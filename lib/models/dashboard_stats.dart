import 'admin_transaction.dart';
import 'transaction_breakdown_item.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalSales,
    required this.transactionCount,
    required this.totalUnits,
    required this.averageDurationMs,
    required this.transactionsByFacility,
    required this.salesByFacility,
    required this.unitsByCategory,
    required this.salesByCategory,
    required this.printStatusCounts,
    required this.paymentStatusCounts,
    required this.syncStatusCounts,
    required this.recentTransactions,
    required this.generatedAt,
  });

  final double totalSales;
  final int transactionCount;
  final int totalUnits;
  final int averageDurationMs;
  final Map<String, int> transactionsByFacility;
  final Map<String, double> salesByFacility;
  final Map<String, int> unitsByCategory;
  final Map<String, double> salesByCategory;
  final Map<String, int> printStatusCounts;
  final Map<String, int> paymentStatusCounts;
  final Map<String, int> syncStatusCounts;
  final List<AdminTransaction> recentTransactions;
  final DateTime generatedAt;

  int get pendingPrintCount {
    var count = 0;
    for (final entry in printStatusCounts.entries) {
      if (entry.key.toLowerCase() != 'printed') {
        count += entry.value;
      }
    }
    return count;
  }

  factory DashboardStats.empty() {
    return DashboardStats(
      totalSales: 0,
      transactionCount: 0,
      totalUnits: 0,
      averageDurationMs: 0,
      transactionsByFacility: const {},
      salesByFacility: const {},
      unitsByCategory: const {},
      salesByCategory: const {},
      printStatusCounts: const {},
      paymentStatusCounts: const {},
      syncStatusCounts: const {},
      recentTransactions: const [],
      generatedAt: DateTime.now(),
    );
  }

  factory DashboardStats.fromData({
    required List<AdminTransaction> transactions,
    required List<TransactionBreakdownItem> breakdownItems,
  }) {
    if (transactions.isEmpty) {
      return DashboardStats.empty();
    }

    final transactionsByFacility = <String, int>{};
    final salesByFacility = <String, double>{};
    final unitsByCategory = <String, int>{};
    final salesByCategory = <String, double>{};
    final printStatusCounts = <String, int>{};
    final paymentStatusCounts = <String, int>{};
    final syncStatusCounts = <String, int>{};

    var totalSales = 0.0;
    var totalUnits = 0;
    var totalDurationMs = 0;

    for (final transaction in transactions) {
      totalSales += transaction.amountDue;
      totalUnits += transaction.totalUnits;
      totalDurationMs += transaction.durationMs;

      transactionsByFacility[transaction.facilityName] =
          (transactionsByFacility[transaction.facilityName] ?? 0) + 1;
      salesByFacility[transaction.facilityName] =
          (salesByFacility[transaction.facilityName] ?? 0) +
          transaction.amountDue;

      final printStatus = transaction.printStatus.trim().isEmpty
          ? 'unknown'
          : transaction.printStatus;
      final paymentStatus = transaction.paymentStatus.trim().isEmpty
          ? 'unknown'
          : transaction.paymentStatus;
      final syncStatus = transaction.syncStatus.trim().isEmpty
          ? 'live'
          : transaction.syncStatus;

      printStatusCounts[printStatus] =
          (printStatusCounts[printStatus] ?? 0) + 1;
      paymentStatusCounts[paymentStatus] =
          (paymentStatusCounts[paymentStatus] ?? 0) + 1;
      syncStatusCounts[syncStatus] = (syncStatusCounts[syncStatus] ?? 0) + 1;
    }

    for (final item in breakdownItems) {
      unitsByCategory[item.categoryLabel] =
          (unitsByCategory[item.categoryLabel] ?? 0) + item.quantity;
      salesByCategory[item.categoryLabel] =
          (salesByCategory[item.categoryLabel] ?? 0) + item.subtotal;
    }

    final sortedRecent = [...transactions]
      ..sort(
        (left, right) =>
            right.effectiveTimestamp.compareTo(left.effectiveTimestamp),
      );

    return DashboardStats(
      totalSales: totalSales,
      transactionCount: transactions.length,
      totalUnits: totalUnits,
      averageDurationMs: totalDurationMs ~/ transactions.length,
      transactionsByFacility: transactionsByFacility,
      salesByFacility: salesByFacility,
      unitsByCategory: unitsByCategory,
      salesByCategory: salesByCategory,
      printStatusCounts: printStatusCounts,
      paymentStatusCounts: paymentStatusCounts,
      syncStatusCounts: syncStatusCounts,
      recentTransactions: sortedRecent.take(10).toList(growable: false),
      generatedAt: DateTime.now(),
    );
  }
}
