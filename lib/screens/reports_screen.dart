import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/business_day_report.dart';
import '../services/business_day_report_export_service.dart';
import '../services/supabase_service.dart';
import '../utils/taipei_time.dart';
import '../widgets/sync_status_widget.dart';

const String _excelMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final BusinessDayReportExportService _exportService =
      BusinessDayReportExportService();

  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late BusinessDayReport _report;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = TaipeiTime.now();
    _endDateTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _startDateTime = _endDateTime.subtract(const Duration(days: 1));
    _report = BusinessDayReport.empty(
      businessDate: _startDateTime,
      startAt: _startDateTime,
      endAt: _endDateTime,
    );
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    try {
      final report = await _supabaseService.getTimeRangeReport(
        startTime: _startDateTime,
        endTime: _endDateTime,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      _showMessage('Error loading report: $error', Colors.red.shade700);
    }
  }

  Future<void> _pickStartDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime(2024),
      lastDate: _endDateTime,
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    await _loadReport();
  }

  Future<void> _pickEndDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDateTime,
      firstDate: _startDateTime,
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDateTime),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _endDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    await _loadReport();
  }

  Future<void> _exportReport() async {
    if (_report.isEmpty || _isExporting) {
      return;
    }

    setState(() => _isExporting = true);

    try {
      final excelReport = _exportService.buildExcelReportFile(_report);
      await Share.shareXFiles(
        [
          XFile.fromData(
            excelReport.bytes,
            mimeType: _excelMimeType,
            name: excelReport.fileName,
          ),
        ],
        subject: 'CTU Kiosk Time Range Report',
        text:
            'Time range report from ${DateFormat('MMM dd, yyyy hh:mm a').format(_startDateTime)} to ${DateFormat('MMM dd, yyyy hh:mm a').format(_endDateTime)}.',
      );
      if (!mounted) {
        return;
      }

      _showMessage(
        'Excel report generated and ready to share.',
        Colors.green.shade700,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to export report: $error', Colors.red.shade700);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SyncStatusWidget(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterCard(),
                        const SizedBox(height: 16),
                        if (_report.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildTopSummaryCard(),
                          const SizedBox(height: 16),
                          ..._report.facilitySummaries.map(_buildFacilityCard),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Custom Time Range Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coverage: ${DateFormat('MMM dd, yyyy hh:mm a').format(_startDateTime)} - ${DateFormat('MMM dd, yyyy hh:mm a').format(_endDateTime)}',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Date & Time',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickStartDateTime,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  DateFormat('MMM dd, yyyy hh:mm a').format(_startDateTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Date & Time',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickEndDateTime,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  DateFormat('MMM dd, yyyy hh:mm a').format(_endDateTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _report.isEmpty || _isExporting
                  ? null
                  : _exportReport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isExporting ? 'Exporting...' : 'Export Excel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Sales',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'P${NumberFormat('#,##0.00').format(_report.totalSales)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSummaryChip('Transactions', '${_report.totalTransactions}'),
              _buildSummaryChip(
                'Facilities',
                '${_report.facilitySummaries.length}',
              ),
              _buildSummaryChip('Units', '${_report.totalUnits}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityBusinessSummary summary) {
    final categoryEntries = summary.unitsByCategory.entries.toList(
      growable: false,
    )..sort((left, right) => left.key.compareTo(right.key));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.facilityName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.facilityCode} • ${summary.ticketLabelRange}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                'P${NumberFormat('#,##0.00').format(summary.totalSales)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip('Kids', '${summary.kidsUnits}'),
              _buildMetricChip('Adults', '${summary.adultUnits}'),
              _buildMetricChip('Units', '${summary.totalUnits}'),
              _buildMetricChip('Transactions', '${summary.transactionCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          if (categoryEntries.isEmpty)
            Text(
              'No transaction_breakdown rows were found for this facility in the selected business day.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...categoryEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value} unit${entry.value == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'P${NumberFormat('#,##0.00').format(summary.salesByCategory[entry.key] ?? 0)}',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w700,
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

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.summarize_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no transactions between 9:00 AM of the selected date and 9:00 AM the next day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }
}
