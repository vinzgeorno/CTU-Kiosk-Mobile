import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket.dart';
import '../models/dashboard_stats.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Fetch all tickets for the month
      final response = await _client
          .from('tickets')
          .select()
          .gte('visit_date', monthStart.toIso8601String())
          .order('visit_date', ascending: false);

      final tickets = (response as List)
          .map((json) => Ticket.fromJson(json))
          .toList();

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
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  // Mark ticket as used/invalid
  Future<bool> invalidateTicket(String referenceNumber) async {
    try {
      await _client
          .from('tickets')
          .update({'is_valid': false})
          .eq('reference_number', referenceNumber);
      return true;
    } catch (e) {
      debugPrint('Error invalidating ticket: $e');
      return false;
    }
  }
}
