import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_transaction.dart';
import '../services/supabase_service.dart';
import '../utils/taipei_time.dart';
import '../widgets/sync_status_widget.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<AdminTransaction> _transactions = const [];
  bool _isLoading = true;
  int _selectedPeriod = 3;
  DateTime _selectedDay = _currentTaipeiDate();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 50;

  static DateTime _currentTaipeiDate() {
    final now = TaipeiTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _supabaseService.getTransactions(
        includeAllPeriods: _selectedPeriod == 3,
        period: _selectedPeriod == 3 ? 0 : _selectedPeriod,
        selectedDay: _selectedPeriod == 0 ? _selectedDay : null,
        selectedMonth: _selectedPeriod == 2
            ? DateTime(_selectedYear, _selectedMonth, 1)
            : null,
        limit: _selectedPeriod == 3 ? 10000 : 250,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = transactions;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  List<AdminTransaction> get _filteredTransactions {
    if (_searchQuery.trim().isEmpty) {
      return _transactions;
    }
    return _transactions
        .where((transaction) => transaction.matchesQuery(_searchQuery))
        .toList(growable: false);
  }

  List<AdminTransaction> get _paginatedTransactions {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    return _filteredTransactions.sublist(
      start,
      end > _filteredTransactions.length ? _filteredTransactions.length : end,
    );
  }

  int get _totalPages {
    if (_filteredTransactions.isEmpty) return 1;
    return (_filteredTransactions.length / _pageSize).ceil();
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
    await _loadTransactions();
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
              _loadTransactions();
            },
            child: const Text('Today'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusWidget(),
          _buildFilters(),
          _buildSearchBar(),
          _buildCountBar(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadTransactions,
                          child: _buildTransactionsTable(),
                        ),
                      ),
                      _buildPaginationBar(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Day')),
                ButtonSegment(value: 1, label: Text('Week')),
                ButtonSegment(value: 2, label: Text('Month')),
                ButtonSegment(value: 3, label: Text('All')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) {
                final value = selection.first;
                if (value == _selectedPeriod) {
                  return;
                }
                setState(() => _selectedPeriod = value);
                _loadTransactions();
              },
            ),
          ),
          if (_selectedPeriod == 0) ...[
            const SizedBox(height: 10),
            _buildDayPicker(),
          ],
          if (_selectedPeriod == 2) ...[
            const SizedBox(height: 10),
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
                      _loadTransactions();
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
                      _loadTransactions();
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

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText:
              'Search by ticket label, session ID, facility, or transaction ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCountBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        '${_filteredTransactions.length} transaction${_filteredTransactions.length == 1 ? '' : 's'} total',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('← Previous'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next →'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          color: Colors.white,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            columns: const [
              DataColumn(label: Text('Ticket/ID')),
              DataColumn(label: Text('Facility')),
              DataColumn(label: Text('Session')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Units')),
              DataColumn(label: Text('Pmt Status')),
              DataColumn(label: Text('Sync Status')),
              DataColumn(label: Text('Completed')),
            ],
            rows: _paginatedTransactions.map((transaction) {
              final completedAt = TaipeiTime.toTaipei(transaction.effectiveTimestamp);
              return DataRow(
                onSelectChanged: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(transaction: transaction),
                    ),
                  );
                },
                cells: [
                  DataCell(
                    Text(
                      transaction.displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      transaction.facilityName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      transaction.sessionId.substring(0, 8),
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      'P${NumberFormat('#,##0.00').format(transaction.amountPaid)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${transaction.totalUnits}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  DataCell(
                    _buildStatusChip(transaction.paymentStatus, true),
                  ),
                  DataCell(
                    _buildStatusChip(transaction.syncStatus, true),
                  ),
                  DataCell(
                    Text(
                      DateFormat('MMM dd\nhh:mm a').format(completedAt),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, bool emphasize) {
    final normalized = value.toLowerCase();
    Color color;
    if (normalized == 'printed' ||
        normalized == 'completed' ||
        normalized == 'synced') {
      color = Colors.green.shade700;
    } else if (normalized == 'pending') {
      color = Colors.orange.shade700;
    } else {
      color = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: emphasize ? 12 : 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No transactions available'
                  : 'No transactions match that search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Try another reporting period or refresh the Supabase data.'
                  : 'Search with a ticket label, session ID, facility, or transaction ID.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
