class DashboardStats {
  final double totalPaymentToday;
  final double totalPaymentWeek;
  final double totalPaymentMonth;
  final double totalPaymentAllTime;
  final int visitorsToday;
  final int visitorsWeek;
  final int visitorsMonth;
  final int visitorsAllTime;
  final Map<String, int> visitorsByFacility;
  final Map<String, double> paymentsByFacility;

  // New fields for enhanced analytics
  final Map<String, int>
  visitorsByTicketType; // 'solo' -> count, 'bulk' -> count
  final Map<String, double> paymentsByTicketType;
  final Map<String, int> visitorsByAgeCategory;
  final Map<String, double> paymentsByAgeCategory;
  final int visitorsBelow12;
  final int visitorsAbove12;
  final double paymentBelowGroup;
  final double paymentAboveGroup;

  DashboardStats({
    required this.totalPaymentToday,
    required this.totalPaymentWeek,
    required this.totalPaymentMonth,
    required this.totalPaymentAllTime,
    required this.visitorsToday,
    required this.visitorsWeek,
    required this.visitorsMonth,
    required this.visitorsAllTime,
    required this.visitorsByFacility,
    required this.paymentsByFacility,
    this.visitorsByTicketType = const {},
    this.paymentsByTicketType = const {},
    this.visitorsByAgeCategory = const {},
    this.paymentsByAgeCategory = const {},
    this.visitorsBelow12 = 0,
    this.visitorsAbove12 = 0,
    this.paymentBelowGroup = 0,
    this.paymentAboveGroup = 0,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalPaymentToday: 0,
      totalPaymentWeek: 0,
      totalPaymentMonth: 0,
      totalPaymentAllTime: 0,
      visitorsToday: 0,
      visitorsWeek: 0,
      visitorsMonth: 0,
      visitorsAllTime: 0,
      visitorsByFacility: {},
      paymentsByFacility: {},
      visitorsByTicketType: {},
      paymentsByTicketType: {},
      visitorsByAgeCategory: {},
      paymentsByAgeCategory: {},
      visitorsBelow12: 0,
      visitorsAbove12: 0,
      paymentBelowGroup: 0,
      paymentAboveGroup: 0,
    );
  }
}
