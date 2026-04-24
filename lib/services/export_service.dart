import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ticket_cache.dart';
import '../utils/taipei_time.dart';

class ExportService {
  // Generate CSV export for specific hour range
  Future<String> generateCsvExport(
    List<TicketCache> tickets, {
    required String filename,
    int? startHour,
    int? endHour,
  }) async {
    try {
      debugPrint('[Export] Generating CSV export...');

      // Filter tickets by hour range if provided (hours interpreted in Taipei)
      List<TicketCache> filteredTickets = tickets;
      if (startHour != null && endHour != null) {
        filteredTickets = _filterByHourRange(tickets, startHour, endHour);
        debugPrint(
          '[Export] Filtered ${filteredTickets.length} tickets for Taipei hours $startHour-$endHour',
        );
      }

      // Calculate summary statistics
      final summary = _calculateSummary(filteredTickets);

      // Generate CSV content
      final csv = _generateCsvContent(filteredTickets, summary);

      debugPrint('[Export] CSV generated successfully');
      return csv;
    } catch (e) {
      debugPrint('[Export] Error generating CSV: $e');
      rethrow;
    }
  }

  // Filter by hour-of-day in Asia/Taipei (no calendar filter — legacy helper)
  List<TicketCache> _filterByHourRange(
    List<TicketCache> tickets,
    int startHour,
    int endHour,
  ) {
    return tickets.where((ticket) {
      final hour = TaipeiTime.toTaipei(ticket.createdAt).hour;
      return hour >= startHour && hour <= endHour;
    }).toList();
  }

  // Calculate summary statistics
  Map<String, dynamic> _calculateSummary(List<TicketCache> tickets) {
    double totalPaid = 0;
    double totalDue = 0;
    double totalChange = 0;
    int soloTickets = 0;
    int bulkTickets = 0;
    int below12 = 0;
    int above12 = 0;
    Map<String, int> byFacility = {};
    Map<String, int> byAgeCategory = {};
    Map<String, int> byTicketType = {};
    int clubMembers = 0;
    int residents = 0;

    for (var ticket in tickets) {
      totalPaid += ticket.amountDue ?? 0;
      totalDue += ticket.amountDue ?? 0;
      totalChange += ticket.changeAmount ?? 0;

      // Ticket type
      if (ticket.ticketType?.toLowerCase() == 'solo') {
        soloTickets++;
      } else if (ticket.ticketType?.toLowerCase() == 'bulk') {
        bulkTickets++;
      }

      // Age category
      if (ticket.ageCategory != null) {
        byAgeCategory[ticket.ageCategory!] =
            (byAgeCategory[ticket.ageCategory!] ?? 0) + 1;
      }

      // Ticket type tracking
      if (ticket.ticketType != null) {
        byTicketType[ticket.ticketType!] =
            (byTicketType[ticket.ticketType!] ?? 0) + 1;
      }

      // Facility
      byFacility[ticket.facility] = (byFacility[ticket.facility] ?? 0) + 1;

      // Below 12 / Above 12
      if (ticket.peopleBelow12 != null) {
        below12 += ticket.peopleBelow12!;
      }
      if (ticket.people12Above != null) {
        above12 += ticket.people12Above!;
      }

      // Membership
      if (ticket.isClubMember == true) clubMembers++;
      if (ticket.isResident == true) residents++;
    }

    return {
      'totalTickets': tickets.length,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'totalChange': totalChange,
      'soloTickets': soloTickets,
      'bulkTickets': bulkTickets,
      'below12': below12,
      'above12': above12,
      'byFacility': byFacility,
      'byAgeCategory': byAgeCategory,
      'byTicketType': byTicketType,
      'clubMembers': clubMembers,
      'residents': residents,
    };
  }

  // Generate CSV content
  String _generateCsvContent(
    List<TicketCache> tickets,
    Map<String, dynamic> summary,
  ) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // Header
    buffer.writeln('CTU KIOSK - MONEY REMITTANCE REPORT');
    buffer.writeln('Generated: ${now.toString()}');
    buffer.writeln('');

    // Summary Section
    buffer.writeln('=== SUMMARY ===');
    buffer.writeln('Total Tickets,${summary['totalTickets']}');
    buffer.writeln(
      'Total Amount Paid,₱${(summary['totalPaid'] as double).toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Total Amount Due,₱${(summary['totalDue'] as double).toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Total Change,₱${(summary['totalChange'] as double).toStringAsFixed(2)}',
    );
    buffer.writeln('');

    // Ticket Type Summary
    buffer.writeln('=== TICKET TYPE BREAKDOWN ===');
    buffer.writeln('Solo Tickets,${summary['soloTickets']}');
    buffer.writeln('Bulk Tickets,${summary['bulkTickets']}');
    buffer.writeln('');

    // Age Category Summary
    buffer.writeln('=== AGE CATEGORY BREAKDOWN ===');
    buffer.writeln('Below 12 Years,${summary['below12']}');
    buffer.writeln('12 & Above,${summary['above12']}');
    buffer.writeln('');

    // Facility Breakdown
    buffer.writeln('=== FACILITY BREAKDOWN ===');
    (summary['byFacility'] as Map<String, int>).forEach((facility, count) {
      buffer.writeln('$facility,$count');
    });
    buffer.writeln('');

    // Age Category Breakdown
    buffer.writeln('=== AGE CATEGORY DISTRIBUTION ===');
    (summary['byAgeCategory'] as Map<String, int>).forEach((category, count) {
      buffer.writeln('$category,$count');
    });
    buffer.writeln('');

    // Detailed Tickets
    buffer.writeln('=== DETAILED TICKETS ===');
    buffer.writeln(
      'Reference,Facility,Ticket Type,Age Category,Amount Paid,Amount Due,Change,Date,Club Member,Resident',
    );

    for (var ticket in tickets) {
      final clubMember = ticket.isClubMember == true ? 'Yes' : 'No';
      final resident = ticket.isResident == true ? 'Yes' : 'No';
      buffer.writeln(
        '${ticket.referenceNumber},${ticket.facility},${ticket.ticketType ?? 'N/A'},${ticket.ageCategory ?? 'N/A'},₱${ticket.amount.toStringAsFixed(2)},₱${(ticket.amountDue ?? 0).toStringAsFixed(2)},₱${(ticket.changeAmount ?? 0).toStringAsFixed(2)},${ticket.createdAt.toString()},$clubMember,$resident',
      );
    }

    return buffer.toString();
  }

  /// [date] calendar (year/month/day) is treated as a business date in Asia/Taipei.
  /// Same-day range: [startHour, endHour] inclusive on that Taipei date.
  /// Overnight: from [startHour] on that date through before [endHour] on the next Taipei day.
  Future<List<TicketCache>> getTicketsForHourRange(
    List<TicketCache> allTickets, {
    required DateTime date,
    required int startHour,
    required int endHour,
    bool overnight = false,
  }) async {
    final loc = TaipeiTime.location;
    final y = date.year;
    final m = date.month;
    final d = date.day;

    return allTickets.where((ticket) {
      final z = TaipeiTime.toTaipei(ticket.createdAt);

      if (!overnight) {
        if (z.year != y || z.month != m || z.day != d) return false;
        final h = z.hour;
        return h >= startHour && h <= endHour;
      }

      final dayStart = tz.TZDateTime(loc, y, m, d);
      final nextDay = dayStart.add(const Duration(days: 1));

      final onEvening =
          z.year == dayStart.year &&
          z.month == dayStart.month &&
          z.day == dayStart.day &&
          z.hour >= startHour;
      final onNextMorning =
          z.year == nextDay.year &&
          z.month == nextDay.month &&
          z.day == nextDay.day &&
          z.hour < endHour;

      return onEvening || onNextMorning;
    }).toList();
  }

  // Validate same-calendar-day hour range (custom mode)
  bool isValidHourRange(int startHour, int endHour) {
    return startHour >= 0 &&
        startHour <= 23 &&
        endHour >= 0 &&
        endHour <= 23 &&
        startHour <= endHour;
  }

  // Get predefined hour ranges
  Map<String, Map<String, int>> getPredefinedHourRanges() {
    return {
      'Day shift (8am–4pm, Taipei)': {'start': 8, 'end': 16},
      'Night shift (4pm–8am next day, Taipei)': {'start': 16, 'end': 8},
      'Custom': {'start': -1, 'end': -1},
    };
  }
}
