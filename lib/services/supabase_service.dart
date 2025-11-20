import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket.dart';
import '../models/dashboard_stats.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Test database connection
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing Supabase connection...');
      final response = await _client
          .from('tickets')
          .select('id')
          .limit(1);
      debugPrint('Connection successful! Response: $response');
      return true;
    } catch (e) {
      debugPrint('Connection failed: $e');
      return false;
    }
  }

  // Get all tickets (for debugging)
  Future<List<Ticket>> getAllTickets() async {
    try {
      debugPrint('Fetching all tickets from Supabase...');
      final response = await _client
          .from('tickets')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Raw response: $response');
      
      final tickets = (response as List)
          .map((json) => Ticket.fromJson(json))
          .toList();
      
      debugPrint('Successfully fetched ${tickets.length} tickets');
      return tickets;
    } catch (e) {
      debugPrint('Error fetching all tickets: $e');
      rethrow;
    }
  }

  // Validate ticket by reference number
  Future<Ticket?> validateTicket(String referenceNumber) async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .eq('reference_number', referenceNumber)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Ticket.fromJson(response);
    } catch (e) {
      debugPrint('Error validating ticket: $e');
      rethrow;
    }
  }

  // Get dashboard statistics with optional month filter
  Future<DashboardStats> getDashboardStats({DateTime? selectedMonth}) async {
    try {
      debugPrint('Fetching dashboard statistics...');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      
      // Use selected month or current month
      final targetMonth = selectedMonth ?? now;
      final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
      final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 1).subtract(const Duration(days: 1));

      // Fetch ALL tickets
      debugPrint('Querying tickets table...');
      final response = await _client
          .from('tickets')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Raw dashboard response: $response');

      final allTickets = (response as List)
          .map((json) => Ticket.fromJson(json))
          .toList();
      
      debugPrint('Total tickets fetched: ${allTickets.length}');

      // Filter tickets for selected month
      final tickets = allTickets.where((ticket) {
        final dateToCheck = ticket.visitDate;
        return dateToCheck.isAfter(monthStart.subtract(const Duration(days: 1))) &&
               dateToCheck.isBefore(monthEnd.add(const Duration(days: 1)));
      }).toList();
      
      debugPrint('Tickets in selected month: ${tickets.length}');

      // Calculate statistics
      double totalPaymentToday = 0;
      double totalPaymentWeek = 0;
      double totalPaymentMonth = 0;
      double totalPaymentAllTime = 0;
      int visitorsToday = 0;
      int visitorsWeek = 0;
      int visitorsMonth = tickets.length;
      int visitorsAllTime = allTickets.length;

      Map<String, int> visitorsByFacility = {};
      Map<String, double> paymentsByFacility = {};

      // Calculate all-time stats
      for (var ticket in allTickets) {
        final amount = ticket.amount;
        totalPaymentAllTime += amount;
      }

      // Calculate month-specific stats
      for (var ticket in tickets) {
        final visitDate = ticket.visitDate;
        final amount = ticket.amount;
        final facility = ticket.facility;

        // Update facility counts (for selected month)
        visitorsByFacility[facility] = (visitorsByFacility[facility] ?? 0) + 1;
        paymentsByFacility[facility] = (paymentsByFacility[facility] ?? 0) + amount;

        // Today's stats (only if viewing current month)
        if (selectedMonth == null || (targetMonth.year == now.year && targetMonth.month == now.month)) {
          if (visitDate.isAfter(today.subtract(const Duration(days: 1))) && 
              visitDate.isBefore(today.add(const Duration(days: 1)))) {
            totalPaymentToday += amount;
            visitorsToday++;
          }

          // Week's stats
          if (visitDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
            totalPaymentWeek += amount;
            visitorsWeek++;
          }
        }

        // Month's stats
        totalPaymentMonth += amount;
      }

      debugPrint('Dashboard stats calculated:');
      debugPrint('  Today: ₱$totalPaymentToday, $visitorsToday visitors');
      debugPrint('  Week: ₱$totalPaymentWeek, $visitorsWeek visitors');
      debugPrint('  Month: ₱$totalPaymentMonth, $visitorsMonth visitors');
      debugPrint('  All Time: ₱$totalPaymentAllTime, $visitorsAllTime visitors');
      debugPrint('  Facilities: ${visitorsByFacility.keys.join(", ")}');

      return DashboardStats(
        totalPaymentToday: totalPaymentToday,
        totalPaymentWeek: totalPaymentWeek,
        totalPaymentMonth: totalPaymentMonth,
        totalPaymentAllTime: totalPaymentAllTime,
        visitorsToday: visitorsToday,
        visitorsWeek: visitorsWeek,
        visitorsMonth: visitorsMonth,
        visitorsAllTime: visitorsAllTime,
        visitorsByFacility: visitorsByFacility,
        paymentsByFacility: paymentsByFacility,
      );
    } catch (e, stackTrace) {
      debugPrint('Error fetching dashboard stats: $e');
      debugPrint('Stack trace: $stackTrace');
      return DashboardStats.empty();
    }
  }

}
