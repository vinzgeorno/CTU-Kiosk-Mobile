import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';
import '../models/dashboard_stats.dart';
import 'tickets_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  DashboardStats? _stats;
  int _ticketCount = 0;
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: Today, 1: This Week, 2: This Month
  int _selectedMonth = DateTime.now().month; // 1-12 for month selection

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = _tabController.index;
        });
      }
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await _supabaseService.testConnection();
      if (!isConnected) {
        throw Exception('Failed to connect to Supabase database');
      }

      // Load stats based on selected month for "This Month" tab
      DateTime? monthFilter;
      if (_selectedPeriod == 2) {
        final now = DateTime.now();
        monthFilter = DateTime(now.year, _selectedMonth, 1);
      }

      // Sync from Supabase
      await _localDb.syncFromSupabase();
      
      // Get stats from Supabase
      final stats = await _supabaseService.getDashboardStats(selectedMonth: monthFilter);
      
      // Get ticket count from local DB
      int count = 0;
      switch (_selectedPeriod) {
        case 0:
          final tickets = await _localDb.getTodayTickets();
          count = tickets.length;
          break;
        case 1:
          final tickets = await _localDb.getWeekTickets();
          count = tickets.length;
          break;
        case 2:
          final now = DateTime.now();
          final tickets = await _localDb.getMonthTickets(now.year, _selectedMonth);
          count = tickets.length;
          break;
      }
      
      setState(() {
        _stats = stats;
        _ticketCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDashboardData,
            ),
          ),
        );
      }
    }
  }

  void _showAppGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('App Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem(
                '📊 Dashboard',
                'View payment and visitor statistics. Switch between Today, This Week, and This Month tabs.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                '📅 Month Selection',
                'In "This Month" tab, select any of the 12 months to view historical data.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                '🎫 Ticket Records',
                'Scroll down to see all ticket records with details like reference number, facility, and amount.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                '📱 Scanner',
                'Tap the Scanner tab to scan QR codes or manually enter ticket reference numbers.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                '🔄 Refresh',
                'Pull down to refresh data or tap the refresh icon.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
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
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showAppGuide,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.blue.shade700,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Today'),
                      Tab(text: 'This Week'),
                      Tab(text: 'This Month'),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Selector (only show for "This Month" tab)
                          if (_selectedPeriod == 2) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Month',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(12, (index) {
                                      final month = index + 1;
                                      final monthName = DateFormat('MMM').format(DateTime(2024, month));
                                      final isSelected = _selectedMonth == month;
                                      
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedMonth = month;
                                          });
                                          _loadDashboardData();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            monthName,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.grey.shade700,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Statistics Cards
                          _buildStatisticsSection(),
                          
                          const SizedBox(height: 24),
                          
                          // View Tickets Button
                          _buildViewTicketsButton(),
                          
                          const SizedBox(height: 24),
                          
                          // Charts Section
                          if (_stats != null) ...[
                            _buildChartsSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsSection() {
    double payment = 0;
    int visitors = 0;
    
    // Get data based on selected period
    if (_stats != null) {
      switch (_selectedPeriod) {
        case 0: // Today
          payment = _stats!.totalPaymentToday;
          visitors = _stats!.visitorsToday;
          break;
        case 1: // This Week
          payment = _stats!.totalPaymentWeek;
          visitors = _stats!.visitorsWeek;
          break;
        case 2: // This Month
          payment = _stats!.totalPaymentMonth;
          visitors = _stats!.visitorsMonth;
          break;
      }
    }
    
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
        
        // Uniform stat cards
        Row(
          children: [
            Expanded(
              child: _buildUniformStatCard(
                'Total Payment',
                '₱${NumberFormat('#,##0.00').format(payment)}',
                Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUniformStatCard(
                'Total Visitors',
                '$visitors',
                Icons.people_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUniformStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTicketsButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket Records',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_ticketCount ticket${_ticketCount != 1 ? 's' : ''} available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketsScreen(
                      selectedPeriod: _selectedPeriod,
                      selectedMonth: _selectedMonth,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Tickets'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        
        // Visitors by Facility Pie Chart
        if (_stats!.visitorsByFacility.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitors by Facility',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(_stats!.visitorsByFacility),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildLegend(_stats!.visitorsByFacility),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Payments by Facility Bar Chart
        if (_stats!.paymentsByFacility.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payments by Facility',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxPayment(_stats!.paymentsByFacility) * 1.2,
                      barGroups: _buildBarChartGroups(_stats!.paymentsByFacility),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₱${NumberFormat.compact().format(value)}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final facilities = _stats!.paymentsByFacility.keys.toList();
                              if (value.toInt() >= 0 && value.toInt() < facilities.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    facilities[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> data) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.amber.shade700,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, int> data) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.amber.shade700,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              '${entry.value} visitors',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarChartGroups(Map<String, double> data) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.amber.shade700,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      final barIndex = index;
      index++;
      return BarChartGroupData(
        x: barIndex,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxPayment(Map<String, double> data) {
    if (data.isEmpty) return 100;
    return data.values.reduce((a, b) => a > b ? a : b);
  }


}
