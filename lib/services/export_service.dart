import 'package:flutter/foundation.dart';
import '../models/ticket_cache.dart';

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

      // Filter tickets by hour range if provided
      List<TicketCache> filteredTickets = tickets;
      if (startHour != null && endHour != null) {
        filteredTickets = _filterByHourRange(tickets, startHour, endHour);
        debugPrint(
          '[Export] Filtered ${filteredTickets.length} tickets for hours $startHour-$endHour',
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

  // Filter tickets by hour range (e.g., 9-17 for 9 AM to 5 PM)
  List<TicketCache> _filterByHourRange(
    List<TicketCache> tickets,
    int startHour,
    int endHour,
  ) {
    return tickets.where((ticket) {
      final hour = ticket.createdAt.hour;
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
      totalPaid += ticket.amount;
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

  // Get tickets for specific date and hour range
  Future<List<TicketCache>> getTicketsForHourRange(
    List<TicketCache> allTickets, {
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return allTickets.where((ticket) {
      final isDateMatch =
          ticket.createdAt.isAfter(dayStart) &&
          ticket.createdAt.isBefore(dayEnd);
      final hour = ticket.createdAt.hour;
      final isHourMatch = hour >= startHour && hour <= endHour;
      return isDateMatch && isHourMatch;
    }).toList();
  }

  // Validate hour range
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
      'Morning (6am-12pm)': {'start': 6, 'end': 12},
      'Afternoon (12pm-6pm)': {'start': 12, 'end': 18},
      'Evening (6pm-10pm)': {'start': 18, 'end': 22},
      'Full Day (6am-10pm)': {'start': 6, 'end': 22},
      'Custom': {'start': -1, 'end': -1}, // User will specify
    };
  }
}
