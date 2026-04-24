import 'dart:math' as math;

import 'admin_transaction.dart';
import 'transaction_breakdown_item.dart';

class BusinessDayReport {
  const BusinessDayReport({
    required this.businessDate,
    required this.startAt,
    required this.endAt,
    required this.totalSales,
    required this.totalTransactions,
    required this.totalUnits,
    required this.facilitySummaries,
    required this.generatedAt,
  });

  final DateTime businessDate;
  final DateTime startAt;
  final DateTime endAt;
  final double totalSales;
  final int totalTransactions;
  final int totalUnits;
  final List<FacilityBusinessSummary> facilitySummaries;
  final DateTime generatedAt;

  bool get isEmpty => totalTransactions == 0;

  factory BusinessDayReport.empty({
    required DateTime businessDate,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return BusinessDayReport(
      businessDate: businessDate,
      startAt: startAt,
      endAt: endAt,
      totalSales: 0,
      totalTransactions: 0,
      totalUnits: 0,
      facilitySummaries: const [],
      generatedAt: DateTime.now(),
    );
  }

  factory BusinessDayReport.fromData({
    required DateTime businessDate,
    required DateTime startAt,
    required DateTime endAt,
    required List<AdminTransaction> transactions,
    required List<TransactionBreakdownItem> breakdownItems,
  }) {
    if (transactions.isEmpty) {
      return BusinessDayReport.empty(
        businessDate: businessDate,
        startAt: startAt,
        endAt: endAt,
      );
    }

    final breakdownByTransaction = <int, List<TransactionBreakdownItem>>{};
    for (final item in breakdownItems) {
      breakdownByTransaction
          .putIfAbsent(item.localTransactionId, () => [])
          .add(item);
    }

    final summariesByFacility = <String, _FacilitySummaryAccumulator>{};

    for (final transaction in transactions) {
      final key = '${transaction.facilityCode}|${transaction.facilityName}';
      final accumulator = summariesByFacility.putIfAbsent(
        key,
        () => _FacilitySummaryAccumulator(
          facilityCode: transaction.facilityCode,
          facilityName: transaction.facilityName,
        ),
      );
      accumulator.add(
        transaction,
        breakdownByTransaction[transaction.localTransactionId] ?? const [],
      );
    }

    final facilitySummaries =
        summariesByFacility.values
            .map((accumulator) => accumulator.build())
            .toList(growable: false)
          ..sort((left, right) {
            final codeCompare = left.facilityCode.compareTo(right.facilityCode);
            if (codeCompare != 0) {
              return codeCompare;
            }
            return right.totalSales.compareTo(left.totalSales);
          });

    var totalSales = 0.0;
    var totalUnits = 0;

    for (final transaction in transactions) {
      totalSales += transaction.amountDue;
      totalUnits += transaction.totalUnits;
    }

    return BusinessDayReport(
      businessDate: businessDate,
      startAt: startAt,
      endAt: endAt,
      totalSales: totalSales,
      totalTransactions: transactions.length,
      totalUnits: totalUnits,
      facilitySummaries: facilitySummaries,
      generatedAt: DateTime.now(),
    );
  }
}

class FacilityBusinessSummary {
  const FacilityBusinessSummary({
    required this.facilityCode,
    required this.facilityName,
    required this.ticketLabelRange,
    required this.totalSales,
    required this.transactionCount,
    required this.totalUnits,
    required this.kidsUnits,
    required this.adultUnits,
    required this.unitsByCategory,
    required this.salesByCategory,
  });

  final String facilityCode;
  final String facilityName;
  final String ticketLabelRange;
  final double totalSales;
  final int transactionCount;
  final int totalUnits;
  final int kidsUnits;
  final int adultUnits;
  final Map<String, int> unitsByCategory;
  final Map<String, double> salesByCategory;
}

class _FacilitySummaryAccumulator {
  _FacilitySummaryAccumulator({
    required this.facilityCode,
    required this.facilityName,
  });

  final String facilityCode;
  final String facilityName;

  final Map<String, int> _unitsByCategory = <String, int>{};
  final Map<String, double> _salesByCategory = <String, double>{};

  double _totalSales = 0;
  int _transactionCount = 0;
  int _totalUnits = 0;
  int _kidsUnits = 0;
  int _labelDigits = 4;

  String? _firstLabel;
  int? _firstSequence;
  DateTime? _firstTimestamp;

  String? _lastLabel;
  int? _lastSequence;
  DateTime? _lastTimestamp;

  void add(
    AdminTransaction transaction,
    List<TransactionBreakdownItem> breakdownItems,
  ) {
    _transactionCount += 1;
    _totalSales += transaction.amountDue;
    _totalUnits += transaction.totalUnits;

    final labels = _extractBoundaryLabels(transaction);
    final startSequence =
        transaction.ticketStartNo ??
        _extractTrailingSequence(labels.first) ??
        transaction.endingSequence;
    final endSequence =
        transaction.ticketEndNo ??
        _extractTrailingSequence(labels.last) ??
        transaction.endingSequence;
    final timestamp = transaction.effectiveTimestamp;

    _labelDigits = math.max(_labelDigits, _extractDigits(labels.first));
    _labelDigits = math.max(_labelDigits, _extractDigits(labels.last));

    if (_firstSequence == null ||
        startSequence < _firstSequence! ||
        (startSequence == _firstSequence! &&
            (_firstTimestamp == null ||
                timestamp.isBefore(_firstTimestamp!)))) {
      _firstSequence = startSequence;
      _firstLabel = labels.first;
      _firstTimestamp = timestamp;
    }

    if (_lastSequence == null ||
        endSequence > _lastSequence! ||
        (endSequence == _lastSequence! &&
            (_lastTimestamp == null || timestamp.isAfter(_lastTimestamp!)))) {
      _lastSequence = endSequence;
      _lastLabel = labels.last;
      _lastTimestamp = timestamp;
    }

    for (final item in breakdownItems) {
      _unitsByCategory[item.categoryLabel] =
          (_unitsByCategory[item.categoryLabel] ?? 0) + item.quantity;
      _salesByCategory[item.categoryLabel] =
          (_salesByCategory[item.categoryLabel] ?? 0) + item.subtotal;
      if (_isKidCategory(item)) {
        _kidsUnits += item.quantity;
      }
    }
  }

  FacilityBusinessSummary build() {
    final startLabel =
        _firstLabel ??
        _formatTicketLabel(facilityCode, _firstSequence, _labelDigits);
    final endLabel =
        _lastLabel ??
        _formatTicketLabel(facilityCode, _lastSequence, _labelDigits);
    final ticketLabelRange = startLabel == endLabel
        ? startLabel
        : '$startLabel-$endLabel';

    return FacilityBusinessSummary(
      facilityCode: facilityCode,
      facilityName: facilityName,
      ticketLabelRange: ticketLabelRange,
      totalSales: _totalSales,
      transactionCount: _transactionCount,
      totalUnits: _totalUnits,
      kidsUnits: _kidsUnits,
      adultUnits: math.max(0, _totalUnits - _kidsUnits),
      unitsByCategory: Map.unmodifiable(_unitsByCategory),
      salesByCategory: Map.unmodifiable(_salesByCategory),
    );
  }
}

List<String> _extractBoundaryLabels(AdminTransaction transaction) {
  final label = transaction.displayLabel;
  final facilityCode = transaction.facilityCode.trim();

  if (facilityCode.isNotEmpty) {
    final pattern = RegExp(
      '${RegExp.escape(facilityCode)}(?:-[A-Za-z0-9]+)*-\\d+',
    );
    final matches = pattern
        .allMatches(label)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    if (matches.isNotEmpty) {
      return [matches.first, matches.last];
    }
  }

  return [label, label];
}

bool _isKidCategory(TransactionBreakdownItem item) {
  final normalized = '${item.categoryCode} ${item.categoryLabel}'.toLowerCase();
  return normalized.contains('kid') || normalized.contains('child');
}

int? _extractTrailingSequence(String value) {
  final match = RegExp(r'(\d+)$').firstMatch(value);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

int _extractDigits(String value) {
  final match = RegExp(r'(\d+)$').firstMatch(value);
  return match?.group(1)?.length ?? 4;
}

String _formatTicketLabel(String facilityCode, int? sequence, int digits) {
  if (sequence == null || sequence <= 0) {
    return facilityCode.isEmpty ? 'Unassigned' : facilityCode;
  }

  final prefix = facilityCode.isEmpty ? 'TX' : facilityCode;
  return '$prefix-${sequence.toString().padLeft(digits, '0')}';
}
