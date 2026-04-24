import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_transaction.dart';
import '../models/dashboard_stats.dart';
import '../services/supabase_service.dart';
import '../utils/taipei_time.dart';
import '../widgets/sync_status_widget.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  DashboardStats _stats = DashboardStats.empty();
  bool _isLoading = true;
  int _selectedPeriod = 0;
  DateTime _selectedDay = _currentTaipeiDate();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const List<_GuideSection> _guideSections = [
    _GuideSection(
      title: 'What This Screen Shows',
      icon: Icons.dashboard_outlined,
      description:
          'The dashboard summarizes completed kiosk transactions from Supabase for the selected day, week, or month.',
      bullets: [
        'Overview cards show total sales, transaction count, units sold, and average payment duration.',
        'Recent Transactions opens the latest completed records so staff can inspect a sale quickly.',
        'Charts break down revenue by facility and units by category.',
      ],
    ),
    _GuideSection(
      title: 'How To Change The Data Range',
      icon: Icons.filter_alt_outlined,
      description:
          'Use the reporting period selector at the top of the screen to switch context.',
      bullets: [
        'Day lets you pick a specific calendar date in Taipei time.',
        'This Week shows the current Monday-to-today range.',
        'This Month lets you choose both month and year before refreshing.',
      ],
    ),
    _GuideSection(
      title: 'How To Investigate A Sale',
      icon: Icons.receipt_long_outlined,
      description:
          'Use the recent transaction list when you need to inspect a specific ticket or payment session.',
      bullets: [
        'Tap any recent transaction card to open its details.',
        'The detail screen shows ticket label, session ID, amount due, amount paid, timing, and category breakdown rows.',
        'Use the Transactions or Search tabs when the sale is not in the recent list.',
      ],
    ),
    _GuideSection(
      title: 'Reading The Numbers Correctly',
      icon: Icons.rule_folder_outlined,
      description:
          'These numbers are operational reporting values, not accounting exports.',
      bullets: [
        'Total Sales is based on amount due from completed transaction rows.',
        'Units Sold comes from total ticket units attached to those transactions.',
        'Units by Category depends on available transaction_breakdown rows.',
      ],
    ),
    _GuideSection(
      title: 'When Something Looks Wrong',
      icon: Icons.troubleshoot_outlined,
      description: 'Use these checks before assuming the dashboard is broken.',
      bullets: [
        'Refresh the screen to force a new Supabase read.',
        'Check the sync banner to confirm the app can still reach Supabase.',
        'If charts are empty but transactions exist, verify transaction_breakdown rows exist for those records.',
      ],
    ),
  ];

  static DateTime _currentTaipeiDate() {
    final now = TaipeiTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _supabaseService.getDashboardStats(
        period: _selectedPeriod,
        selectedDay: _selectedPeriod == 0 ? _selectedDay : null,
        selectedMonth: _selectedPeriod == 2
            ? DateTime(_selectedYear, _selectedMonth, 1)
            : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _pickSelectedDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: _currentTaipeiDate(),
    );

    if (picked == null || !mounted) {
      return;
    }

    final normalizedDate = DateTime(picked.year, picked.month, picked.day);
    if (DateUtils.isSameDay(normalizedDate, _selectedDay)) {
      return;
    }

    setState(() => _selectedDay = normalizedDate);
    await _loadDashboardData();
  }

  Widget _buildDayPicker() {
    final today = _currentTaipeiDate();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickSelectedDay,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDay)),
          ),
        ),
        if (!DateUtils.isSameDay(_selectedDay, today)) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              setState(() => _selectedDay = today);
              _loadDashboardData();
            },
            child: const Text('Today'),
          ),
        ],
      ],
    );
  }

  void _showGuide() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard Guide',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Use this screen for live operational reporting and quick transaction review.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Use the Dashboard for fast status checks. Use Reports for the 9AM business-day summary, Transactions for browsing, and Search when you already have a ticket label or session ID.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._guideSections.map(_buildGuideSectionCard),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Guide'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSectionCard(_GuideSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            section.description,
            style: TextStyle(color: Colors.grey.shade700, height: 1.45),
          ),
          const SizedBox(height: 12),
          ...section.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showGuide,
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Guide',
          ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildFilters(),
                  const SyncStatusWidget(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewGrid(),
                        const SizedBox(height: 20),
                        _buildRecentTransactions(),
                        const SizedBox(height: 20),
                        _buildChartsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporting Period',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Day')),
              ButtonSegment(value: 1, label: Text('This Week')),
              ButtonSegment(value: 2, label: Text('This Month')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == _selectedPeriod) {
                return;
              }
              setState(() => _selectedPeriod = value);
              _loadDashboardData();
            },
          ),
          if (_selectedPeriod == 0) ...[
            const SizedBox(height: 12),
            _buildDayPicker(),
          ],
          if (_selectedPeriod == 2) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: List.generate(12, (index) => index + 1)
                        .map(
                          (month) => DropdownMenuItem<int>(
                            value: month,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(2026, month)),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedMonth = value);
                      _loadDashboardData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items:
                        List.generate(
                              5,
                              (index) => DateTime.now().year - 2 + index,
                            )
                            .map(
                              (year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text('$year'),
                              ),
                            )
                            .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedYear = value);
                      _loadDashboardData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard(
              label: 'Total Sales',
              value: 'P${NumberFormat('#,##0.00').format(_stats.totalSales)}',
              subtitle: 'Gross paid amount',
              icon: Icons.payments_outlined,
            ),
            _buildMetricCard(
              label: 'Transactions',
              value: '${_stats.transactionCount}',
              subtitle: 'Completed rows in period',
              icon: Icons.receipt_long_outlined,
            ),
            _buildMetricCard(
              label: 'Units Sold',
              value: '${_stats.totalUnits}',
              subtitle: 'Total ticket units',
              icon: Icons.confirmation_number_outlined,
            ),
            _buildMetricCard(
              label: 'Avg Duration',
              value: _formatDuration(_stats.averageDurationMs),
              subtitle: 'Payment session time',
              icon: Icons.timer_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 26),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        if (_stats.recentTransactions.isEmpty)
          _buildEmptyPanel('No transactions found for the selected period.')
        else
          ..._stats.recentTransactions.map(_buildTransactionTile),
      ],
    );
  }

  Widget _buildTransactionTile(AdminTransaction transaction) {
    final completedAt = TaipeiTime.toTaipei(transaction.effectiveTimestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: transaction),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade700,
          child: Text('${transaction.totalUnits}'),
        ),
        title: Text(
          transaction.displayLabel,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${transaction.facilityName}  •  ${DateFormat('MMM dd, yyyy hh:mm a').format(completedAt)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'P${NumberFormat('#,##0.00').format(transaction.amountPaid)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              '${transaction.totalUnits} unit${transaction.totalUnits == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          title: 'Sales by Facility',
          child: _stats.salesByFacility.isEmpty
              ? _buildEmptyPanel('No facility sales data available.')
              : SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxDouble(_stats.salesByFacility) * 1.2,
                      barGroups: _buildBarGroups(_stats.salesByFacility),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, meta) => Text(
                              'P${NumberFormat.compact().format(value)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final keys = _stats.salesByFacility.keys.toList();
                              final index = value.toInt();
                              if (index < 0 || index >= keys.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  keys[index],
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          title: 'Units by Category',
          child: _stats.unitsByCategory.isEmpty
              ? _buildEmptyPanel('No category breakdown data available.')
              : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 44,
                          sectionsSpace: 3,
                          sections: _buildPieSectionsFromIntMap(
                            _stats.unitsByCategory,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildLegendFromIntMap(_stats.unitsByCategory),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, double> values) {
    final entries = values.entries.toList(growable: false);
    return List.generate(entries.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entries[index].value,
            width: 18,
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _buildPieSectionsFromIntMap(
    Map<String, int> values,
  ) {
    final entries = values.entries.toList(growable: false);
    final colors = _chartColors;

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 72,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    });
  }

  List<Widget> _buildLegendFromIntMap(Map<String, int> values) {
    final entries = values.entries.toList(growable: false);
    final colors = _chartColors;

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.key)),
            Text('${entry.value}'),
          ],
        ),
      );
    });
  }

  double _maxDouble(Map<String, double> values) {
    if (values.isEmpty) {
      return 1;
    }
    return values.values.reduce((left, right) => left > right ? left : right);
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) {
      return '0s';
    }

    final duration = Duration(milliseconds: durationMs);
    if (duration.inMinutes >= 1) {
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      return '${duration.inMinutes}m $seconds s';
    }
    return '${duration.inSeconds}s';
  }

  List<Color> get _chartColors => const [
    Color(0xFF2563EB),
    Color(0xFF0F766E),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
  ];
}

class _GuideSection {
  const _GuideSection({
    required this.title,
    required this.icon,
    required this.description,
    required this.bullets,
  });

  final String title;
  final IconData icon;
  final String description;
  final List<String> bullets;
}
