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
      final response = await _client.from('tickets_new').select('id').limit(1);
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
          .from('tickets_new')
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
          .from('tickets_new')
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
  Future<DashboardStats> getDashboardStats({
    DateTime? selectedMonth,
    int period = 2, // 0: Today, 1: Week, 2: Month
  }) async {
    try {
      debugPrint('Fetching dashboard statistics...');
      final now = DateTime.now();
      // Use UTC dates to avoid timezone issues
      final today = DateTime.utc(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));

      // Use selected month or current month
      final targetMonth = selectedMonth ?? now;
      final monthStart = DateTime.utc(targetMonth.year, targetMonth.month, 1);
      final monthEnd = DateTime.utc(
        targetMonth.year,
        targetMonth.month + 1,
        1,
      ).subtract(const Duration(days: 1));

      // Fetch ALL tickets
      debugPrint('Querying tickets table...');
      final response = await _client
          .from('tickets_new')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Raw dashboard response: $response');

      final allTickets = (response as List)
          .map((json) => Ticket.fromJson(json))
          .toList();

      debugPrint('Total tickets fetched: ${allTickets.length}');

      // Determine which date range to filter based on period
      DateTime filterStart;
      DateTime filterEnd;

      switch (period) {
        case 0: // Today
          filterStart = today;
          filterEnd = today.add(const Duration(days: 1));
          break;
        case 1: // This Week
          filterStart = weekStart;
          filterEnd = today.add(const Duration(days: 1));
          break;
        case 2: // This Month
        default:
          filterStart = monthStart;
          filterEnd = monthEnd.add(const Duration(days: 1));
          break;
      }

      debugPrint(
        'Filter range: ${filterStart.toIso8601String()} to ${filterEnd.toIso8601String()}',
      );

      // Filter tickets for selected period
      // Normalize ticket dates to UTC date-only for comparison
      final tickets = allTickets.where((ticket) {
        final ticketDate = DateTime.utc(
          ticket.visitDate.year,
          ticket.visitDate.month,
          ticket.visitDate.day,
        );
        final isInRange =
            !ticketDate.isBefore(filterStart) && ticketDate.isBefore(filterEnd);
        if (!isInRange) {
          debugPrint(
            'Excluded ticket ${ticket.referenceNumber}: ${ticket.visitDate} (${ticketDate.toIso8601String()})',
          );
        }
        return isInRange;
      }).toList();

      debugPrint('Tickets in selected period: ${tickets.length}');

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
      Map<String, int> visitorsByTicketType = {};
      Map<String, double> paymentsByTicketType = {};
      Map<String, int> visitorsByAgeCategory = {};
      Map<String, double> paymentsByAgeCategory = {};
      int visitorsBelow12 = 0;
      int visitorsAbove12 = 0;
      double paymentBelowGroup = 0;
      double paymentAboveGroup = 0;

      // Calculate all-time stats
      for (var ticket in allTickets) {
        final amount = ticket.amount;
        totalPaymentAllTime += amount;
      }

      // Calculate period-specific stats
      for (var ticket in tickets) {
        final visitDate = ticket.visitDate;
        final amount = ticket.amount;
        final facility = ticket.facility;

        // Update facility counts
        visitorsByFacility[facility] = (visitorsByFacility[facility] ?? 0) + 1;
        paymentsByFacility[facility] =
            (paymentsByFacility[facility] ?? 0) + amount;

        // Ticket type breakdown
        final ticketType = ticket.ticketType ?? 'Unknown';
        visitorsByTicketType[ticketType] =
            (visitorsByTicketType[ticketType] ?? 0) + 1;
        paymentsByTicketType[ticketType] =
            (paymentsByTicketType[ticketType] ?? 0) + amount;

        // Age category breakdown
        final ageCategory = ticket.ageCategory ?? 'Unknown';
        visitorsByAgeCategory[ageCategory] =
            (visitorsByAgeCategory[ageCategory] ?? 0) + 1;
        paymentsByAgeCategory[ageCategory] =
            (paymentsByAgeCategory[ageCategory] ?? 0) + amount;

        // Below 12 / Above 12 breakdown
        if (ticket.peopleBelow12 != null && ticket.peopleBelow12! > 0) {
          visitorsBelow12 += ticket.peopleBelow12!;
          paymentBelowGroup += amount;
        }
        if (ticket.people12Above != null && ticket.people12Above! > 0) {
          visitorsAbove12 += ticket.people12Above!;
          paymentAboveGroup += amount;
        }

        // Today's stats
        if (visitDate.isAfter(today) &&
            visitDate.isBefore(today.add(const Duration(days: 1)))) {
          totalPaymentToday += amount;
          visitorsToday++;
        }

        // Week's stats
        if (visitDate.isAfter(weekStart) &&
            visitDate.isBefore(today.add(const Duration(days: 1)))) {
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
      debugPrint(
        '  All Time: ₱$totalPaymentAllTime, $visitorsAllTime visitors',
      );
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
        visitorsByTicketType: visitorsByTicketType,
        paymentsByTicketType: paymentsByTicketType,
        visitorsByAgeCategory: visitorsByAgeCategory,
        paymentsByAgeCategory: paymentsByAgeCategory,
        visitorsBelow12: visitorsBelow12,
        visitorsAbove12: visitorsAbove12,
        paymentBelowGroup: paymentBelowGroup,
        paymentAboveGroup: paymentAboveGroup,
      );
    } catch (e, stackTrace) {
      debugPrint('Error fetching dashboard stats: $e');
      debugPrint('Stack trace: $stackTrace');
      return DashboardStats.empty();
    }
  }
}
