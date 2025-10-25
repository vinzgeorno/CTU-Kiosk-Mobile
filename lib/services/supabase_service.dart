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

  // Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      debugPrint('Fetching dashboard statistics...');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Fetch ALL tickets and filter client-side
      // This ensures we get data even if visit_date is null or in the future
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

      // Filter tickets for current month based on visit_date or created_at
      final tickets = allTickets.where((ticket) {
        final dateToCheck = ticket.visitDate ?? ticket.createdAt;
        return dateToCheck.isAfter(monthStart.subtract(const Duration(days: 1)));
      }).toList();
      
      debugPrint('Tickets in current month: ${tickets.length}');

      // Calculate statistics
      double totalPaymentToday = 0;
      double totalPaymentWeek = 0;
      double totalPaymentMonth = 0;
      int visitorsToday = 0;
      int visitorsWeek = 0;
      int visitorsMonth = tickets.length;

      Map<String, int> visitorsByFacility = {};
      Map<String, double> paymentsByFacility = {};

      for (var ticket in tickets) {
        final visitDate = ticket.visitDate ?? ticket.createdAt;
        final amount = ticket.amount ?? 0;
        final facility = ticket.facility ?? 'Unknown';

        // Update facility counts
        visitorsByFacility[facility] = (visitorsByFacility[facility] ?? 0) + 1;
        paymentsByFacility[facility] = (paymentsByFacility[facility] ?? 0) + amount;

        // Today's stats
        if (visitDate.isAfter(today) || visitDate.isAtSameMomentAs(today)) {
          totalPaymentToday += amount;
          visitorsToday++;
        }

        // Week's stats
        if (visitDate.isAfter(weekStart) || visitDate.isAtSameMomentAs(weekStart)) {
          totalPaymentWeek += amount;
          visitorsWeek++;
        }

        // Month's stats
        totalPaymentMonth += amount;
      }

      debugPrint('Dashboard stats calculated:');
      debugPrint('  Today: ₱$totalPaymentToday, $visitorsToday visitors');
      debugPrint('  Week: ₱$totalPaymentWeek, $visitorsWeek visitors');
      debugPrint('  Month: ₱$totalPaymentMonth, $visitorsMonth visitors');
      debugPrint('  Facilities: ${visitorsByFacility.keys.join(", ")}');

      return DashboardStats(
        totalPaymentToday: totalPaymentToday,
        totalPaymentWeek: totalPaymentWeek,
        totalPaymentMonth: totalPaymentMonth,
        visitorsToday: visitorsToday,
        visitorsWeek: visitorsWeek,
        visitorsMonth: visitorsMonth,
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
