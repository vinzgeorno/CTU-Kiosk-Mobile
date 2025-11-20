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
    );
  }
}
