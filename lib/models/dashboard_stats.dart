class DashboardStats {
  final double totalPaymentToday;
  final double totalPaymentWeek;
  final double totalPaymentMonth;
  final int visitorsToday;
  final int visitorsWeek;
  final int visitorsMonth;
  final Map<String, int> visitorsByFacility;
  final Map<String, double> paymentsByFacility;

  DashboardStats({
    required this.totalPaymentToday,
    required this.totalPaymentWeek,
    required this.totalPaymentMonth,
    required this.visitorsToday,
    required this.visitorsWeek,
    required this.visitorsMonth,
    required this.visitorsByFacility,
    required this.paymentsByFacility,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalPaymentToday: 0,
      totalPaymentWeek: 0,
      totalPaymentMonth: 0,
      visitorsToday: 0,
      visitorsWeek: 0,
      visitorsMonth: 0,
      visitorsByFacility: {},
      paymentsByFacility: {},
    );
  }
}
