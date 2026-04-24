import 'package:flutter/widgets.dart';
import 'transactions_screen.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({
    super.key,
    required this.selectedPeriod,
    required this.selectedMonth,
    required this.selectedYear,
  });

  final int selectedPeriod;
  final int selectedMonth;
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    return const TransactionsScreen();
  }
}
