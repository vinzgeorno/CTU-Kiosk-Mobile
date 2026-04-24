import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/admin_transaction.dart';
import '../models/business_day_report.dart';
import '../models/dashboard_stats.dart';
import '../models/ticket_counter.dart';
import '../models/transaction_breakdown_item.dart';
import '../utils/taipei_time.dart';

class SupabaseService {
  SupabaseService._internal();

  static final SupabaseService _instance = SupabaseService._internal();
  static const String _transactionsTable = 'transactions';
  static const String _breakdownTable = 'transaction_breakdown';
  static const String _countersTable = 'ticket_counters';

  factory SupabaseService() => _instance;

  final SupabaseClient _client = Supabase.instance.client;

  DateTime? _lastSuccessfulRefresh;
  bool _lastConnectionHealthy = false;
  bool _countersTableAvailable = true;

  DateTime? get lastSuccessfulRefresh => _lastSuccessfulRefresh;

  bool get lastConnectionHealthy => _lastConnectionHealthy;

  bool get countersTableAvailable => _countersTableAvailable;

  Future<bool> testConnection({bool recordSuccess = false}) async {
    try {
      await _client
          .from(_transactionsTable)
          .select('local_transaction_id')
          .limit(1);
      _lastConnectionHealthy = true;
      if (recordSuccess) {
        _markRefreshSuccess();
      }
      return true;
    } catch (error) {
      _lastConnectionHealthy = false;
      debugPrint('Supabase connection failed: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>> getLiveStatus() async {
    final isConnected = await testConnection();
    return {
      'isConnected': isConnected,
      'lastSuccessfulRefresh': _lastSuccessfulRefresh,
      'checkedAt': DateTime.now(),
      'countersTableAvailable': _countersTableAvailable,
    };
  }

  Future<DashboardStats> getDashboardStats({
    DateTime? selectedMonth,
    DateTime? selectedDay,
    int period = 0,
  }) async {
    try {
      final transactions = await getTransactions(
        period: period,
        selectedMonth: selectedMonth,
        selectedDay: selectedDay,
        limit: 10000,
      );
      final breakdownItems = await getBreakdownForTransactions(
        transactions.map((transaction) => transaction.localTransactionId),
      );

      return DashboardStats.fromData(
        transactions: transactions,
        breakdownItems: breakdownItems,
      );
    } catch (error, stackTrace) {
      debugPrint('Error building dashboard stats: $error');
      debugPrint('$stackTrace');
      return DashboardStats.empty();
    }
  }

  Future<BusinessDayReport> getBusinessDayReport(DateTime businessDate) async {
    final startAt = TaipeiTime.businessDayStart(businessDate);
    final endAt = startAt.add(const Duration(days: 1));
    final normalizedBusinessDate = DateTime(
      businessDate.year,
      businessDate.month,
      businessDate.day,
    );

    try {
      final response = await _client
          .from(_transactionsTable)
          .select()
          .gte('created_at', startAt.toUtc().toIso8601String())
          .lt('created_at', endAt.toUtc().toIso8601String())
          .order('created_at', ascending: true);

      final transactions = (response as List)
          .map(
            (json) => AdminTransaction.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);

      final breakdownItems = await getBreakdownForTransactions(
        transactions.map((transaction) => transaction.localTransactionId),
      );

      _markRefreshSuccess();
      return BusinessDayReport.fromData(
        businessDate: normalizedBusinessDate,
        startAt: startAt,
        endAt: endAt,
        transactions: transactions,
        breakdownItems: breakdownItems,
      );
    } catch (error, stackTrace) {
      debugPrint('Error building business day report: $error');
      debugPrint('$stackTrace');
      return BusinessDayReport.empty(
        businessDate: normalizedBusinessDate,
        startAt: startAt,
        endAt: endAt,
      );
    }
  }

  Future<BusinessDayReport> getTimeRangeReport({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _client
          .from(_transactionsTable)
          .select()
          .gte('created_at', startTime.toUtc().toIso8601String())
          .lte('created_at', endTime.toUtc().toIso8601String())
          .order('created_at', ascending: true);

      final transactions = (response as List)
          .map(
            (json) => AdminTransaction.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);

      final breakdownItems = await getBreakdownForTransactions(
        transactions.map((transaction) => transaction.localTransactionId),
      );

      _markRefreshSuccess();
      return BusinessDayReport.fromData(
        businessDate: startTime,
        startAt: startTime,
        endAt: endTime,
        transactions: transactions,
        breakdownItems: breakdownItems,
      );
    } catch (error, stackTrace) {
      debugPrint('Error building time range report: $error');
      debugPrint('$stackTrace');
      return BusinessDayReport.empty(
        businessDate: startTime,
        startAt: startTime,
        endAt: endTime,
      );
    }
  }

  Future<List<AdminTransaction>> getTransactions({
    int period = 0,
    DateTime? selectedMonth,
    DateTime? selectedDay,
    int limit = 200,
    bool includeAllPeriods = false,
  }) async {
    try {
      final range = includeAllPeriods
          ? null
          : _buildPeriodRange(period, selectedMonth, selectedDay);
      var query = _client.from(_transactionsTable).select();

      if (range != null) {
        query = query
            .gte('created_at', range.startUtc.toIso8601String())
            .lt('created_at', range.endUtc.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final transactions = (response as List)
          .map(
            (json) => AdminTransaction.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);

      _markRefreshSuccess();
      return transactions;
    } catch (error) {
      debugPrint('Error fetching transactions: $error');
      rethrow;
    }
  }

  Future<AdminTransaction?> findTransaction(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return null;
    }

    try {
      final numericId = int.tryParse(query);
      if (numericId != null) {
        final byId = await _client
            .from(_transactionsTable)
            .select()
            .eq('local_transaction_id', numericId)
            .maybeSingle();
        if (byId != null) {
          _markRefreshSuccess();
          return AdminTransaction.fromJson(Map<String, dynamic>.from(byId));
        }
      }

      final byTicketLabel = await _client
          .from(_transactionsTable)
          .select()
          .eq('ticket_label', query)
          .maybeSingle();
      if (byTicketLabel != null) {
        _markRefreshSuccess();
        return AdminTransaction.fromJson(
          Map<String, dynamic>.from(byTicketLabel),
        );
      }

      final bySession = await _client
          .from(_transactionsTable)
          .select()
          .eq('session_id', query)
          .maybeSingle();
      if (bySession != null) {
        _markRefreshSuccess();
        return AdminTransaction.fromJson(Map<String, dynamic>.from(bySession));
      }

      final cleanedQuery = _cleanSearchTerm(query);
      final filters = <String>[
        'ticket_label.ilike.%$cleanedQuery%',
        'session_id.ilike.%$cleanedQuery%',
        'facility_name.ilike.%$cleanedQuery%',
        'facility_code.ilike.%$cleanedQuery%',
      ];
      if (numericId != null) {
        filters.add('local_transaction_id.eq.$numericId');
      }

      final partialMatches = await _client
          .from(_transactionsTable)
          .select()
          .or(filters.join(','))
          .order('created_at', ascending: false)
          .limit(1);

      if ((partialMatches as List).isEmpty) {
        return null;
      }

      _markRefreshSuccess();
      return AdminTransaction.fromJson(
        Map<String, dynamic>.from(partialMatches.first as Map),
      );
    } catch (error) {
      debugPrint('Error searching transaction: $error');
      rethrow;
    }
  }

  Future<List<TransactionBreakdownItem>> getTransactionBreakdown(
    int localTransactionId,
  ) async {
    try {
      final response = await _client
          .from(_breakdownTable)
          .select()
          .eq('local_transaction_id', localTransactionId)
          .order('id', ascending: true);

      return (response as List)
          .map(
            (json) => TransactionBreakdownItem.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Error fetching transaction breakdown: $error');
      return const [];
    }
  }

  Future<List<TransactionBreakdownItem>> getBreakdownForTransactions(
    Iterable<int> transactionIds,
  ) async {
    final ids = transactionIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const [];
    }

    try {
      final response = await _client
          .from(_breakdownTable)
          .select()
          .filter('local_transaction_id', 'in', '(${ids.join(',')})')
          .order('local_transaction_id', ascending: true)
          .order('id', ascending: true);

      return (response as List)
          .map(
            (json) => TransactionBreakdownItem.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Error fetching breakdown list: $error');
      return const [];
    }
  }

  Future<List<TicketCounter>> getTicketCounters() async {
    try {
      final response = await _client
          .from(_countersTable)
          .select()
          .order('facility_code', ascending: true);

      _countersTableAvailable = true;
      _markRefreshSuccess();

      return (response as List)
          .map(
            (json) =>
                TicketCounter.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      if (_isMissingTable(error)) {
        _countersTableAvailable = false;
        return _deriveTicketCounters();
      }

      debugPrint('Error fetching ticket counters: $error');
      rethrow;
    } catch (error) {
      debugPrint('Error fetching ticket counters: $error');
      rethrow;
    }
  }

  Future<void> updateTicketCounter(TicketCounter counter) async {
    if (!_countersTableAvailable) {
      throw StateError(
        'ticket_counters is not available in this Supabase project. Add the table before editing counters.',
      );
    }

    await _client
        .from(_countersTable)
        .upsert(
          counter.copyWith(updatedAt: DateTime.now().toUtc()).toJson(),
          onConflict: 'facility_code',
        );

    _markRefreshSuccess();
  }

  Future<List<TicketCounter>> _deriveTicketCounters() async {
    final response = await _client
        .from(_transactionsTable)
        .select(
          'facility_code, facility_name, ticket_end_no, ticket_label, created_at',
        )
        .order('created_at', ascending: false)
        .limit(500);

    final counters = <String, TicketCounter>{};

    for (final rawRow in (response as List)) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final facilityCode = (row['facility_code'] ?? 'UNK').toString();
      final facilityName = (row['facility_name'] ?? facilityCode).toString();
      final updatedAt = _asDateTime(row['created_at']);
      final sequence =
          _asInt(row['ticket_end_no']) ??
          _extractSequence((row['ticket_label'] ?? '').toString()) ??
          0;

      final existing = counters[facilityCode];
      if (existing == null || sequence > existing.lastSequence) {
        counters[facilityCode] = TicketCounter(
          facilityCode: facilityCode,
          facilityName: facilityName,
          lastSequence: sequence,
          updatedAt: updatedAt,
          isDerived: true,
        );
      }
    }

    final derivedCounters = counters.values.toList(growable: false)
      ..sort((left, right) => left.facilityCode.compareTo(right.facilityCode));

    _markRefreshSuccess();
    return derivedCounters;
  }

  _UtcRange _buildPeriodRange(
    int period,
    DateTime? selectedMonth,
    DateTime? selectedDay,
  ) {
    final location = TaipeiTime.location;
    final now = tz.TZDateTime.now(location);
    final todayStart = tz.TZDateTime(location, now.year, now.month, now.day);

    switch (period) {
      case 0:
        final targetDay = selectedDay ?? todayStart;
        final dayStart = tz.TZDateTime(
          location,
          targetDay.year,
          targetDay.month,
          targetDay.day,
        );
        return _UtcRange(
          startUtc: dayStart.toUtc(),
          endUtc: dayStart.add(const Duration(days: 1)).toUtc(),
        );
      case 1:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return _UtcRange(
          startUtc: weekStart.toUtc(),
          endUtc: todayStart.add(const Duration(days: 1)).toUtc(),
        );
      case 2:
      default:
        final targetMonth = selectedMonth ?? DateTime(now.year, now.month, 1);
        final monthStart = tz.TZDateTime(
          location,
          targetMonth.year,
          targetMonth.month,
          1,
        );
        final nextMonth = tz.TZDateTime(
          location,
          targetMonth.year,
          targetMonth.month + 1,
          1,
        );
        return _UtcRange(
          startUtc: monthStart.toUtc(),
          endUtc: nextMonth.toUtc(),
        );
    }
  }

  String _cleanSearchTerm(String value) {
    return value
        .replaceAll(',', ' ')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
  }

  bool _isMissingTable(PostgrestException error) {
    return error.code == 'PGRST205' ||
        error.message.toLowerCase().contains('could not find the table');
  }

  void _markRefreshSuccess() {
    _lastSuccessfulRefresh = DateTime.now();
    _lastConnectionHealthy = true;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  int? _extractSequence(String label) {
    final match = RegExp(r'(\d+)$').firstMatch(label);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}

class _UtcRange {
  const _UtcRange({required this.startUtc, required this.endUtc});

  final DateTime startUtc;
  final DateTime endUtc;
}
