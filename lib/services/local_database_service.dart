import 'package:flutter/foundation.dart';
import '../models/admin_transaction.dart';
import '../models/ticket_cache.dart';
import 'supabase_service.dart';

class LocalDatabaseService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> initialize() async {}

  Future<void> syncFromSupabase({bool force = false}) async {
    await _supabaseService.testConnection(recordSuccess: true);
  }

  Future<List<TicketCache>> getAllTickets() async {
    final transactions = await _supabaseService.getTransactions(
      includeAllPeriods: true,
      limit: 400,
    );
    return transactions.map(_toTicketCache).toList(growable: false);
  }

  Future<List<TicketCache>> getTicketsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final tickets = await getAllTickets();
    return tickets
        .where((ticket) {
          return !ticket.visitDate.isBefore(start) &&
              !ticket.visitDate.isAfter(end);
        })
        .toList(growable: false);
  }

  Future<List<TicketCache>> getTodayTickets() async {
    final transactions = await _supabaseService.getTransactions(
      period: 0,
      limit: 250,
    );
    return transactions.map(_toTicketCache).toList(growable: false);
  }

  Future<List<TicketCache>> getWeekTickets() async {
    final transactions = await _supabaseService.getTransactions(
      period: 1,
      limit: 250,
    );
    return transactions.map(_toTicketCache).toList(growable: false);
  }

  Future<List<TicketCache>> getMonthTickets(int year, int month) async {
    final transactions = await _supabaseService.getTransactions(
      period: 2,
      selectedMonth: DateTime(year, month, 1),
      limit: 300,
    );
    return transactions.map(_toTicketCache).toList(growable: false);
  }

  Future<TicketCache?> getTicketByReferenceNumber(
    String referenceNumber,
  ) async {
    final transaction = await _supabaseService.findTransaction(referenceNumber);
    if (transaction == null) {
      return null;
    }
    return _toTicketCache(transaction);
  }

  Future<DateTime?> getLastSyncTime() async {
    return _supabaseService.lastSuccessfulRefresh;
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final tickets = await getAllTickets();
    return {
      'ticketCount': tickets.length,
      'lastSync': _supabaseService.lastSuccessfulRefresh,
      'isCached': false,
    };
  }

  Future<void> clearCache() async {
    debugPrint('Local cache is no longer used by the active app flow.');
  }

  Future<void> close() async {}

  TicketCache _toTicketCache(AdminTransaction transaction) {
    return TicketCache(
      id: transaction.localTransactionId.toString(),
      referenceNumber: transaction.displayLabel,
      facility: transaction.facilityName,
      amount: transaction.amountPaid,
      visitDate: transaction.effectiveTimestamp,
      createdAt: transaction.createdAt,
      transactionStatus: transaction.paymentStatus,
      amountDue: transaction.amountDue,
      ticketType: transaction.isBulk ? 'bulk' : 'single',
      totalPeople: transaction.totalUnits,
      people12Above: transaction.totalUnits,
    );
  }
}
