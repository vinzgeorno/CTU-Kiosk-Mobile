import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_transaction.dart';
import '../models/transaction_breakdown_item.dart';
import '../services/supabase_service.dart';
import '../utils/taipei_time.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final AdminTransaction transaction;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<TransactionBreakdownItem> _breakdown = const [];
  bool _isLoadingBreakdown = true;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    final items = await _supabaseService.getTransactionBreakdown(
      widget.transaction.localTransactionId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _breakdown = items;
      _isLoadingBreakdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final startedAt = TaipeiTime.toTaipei(transaction.startedAt);
    final completedAt = TaipeiTime.toTaipei(transaction.effectiveTimestamp);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transaction.facilityName} (${transaction.facilityCode})',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderChip(transaction.paymentStatus),
                    _buildHeaderChip(transaction.syncStatus),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Summary',
            children: [
              _buildDetailRow(
                'Transaction ID',
                '${transaction.localTransactionId}',
              ),
              _buildDetailRow('Session ID', transaction.sessionId),
              _buildDetailRow(
                'Amount Due',
                'P${NumberFormat('#,##0.00').format(transaction.amountDue)}',
              ),
              _buildDetailRow(
                'Amount Paid',
                'P${NumberFormat('#,##0.00').format(transaction.amountPaid)}',
              ),
              _buildDetailRow('Units', '${transaction.totalUnits}'),
              _buildDetailRow('Ticket Range', _formatTicketRange(transaction)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Timing',
            children: [
              _buildDetailRow(
                'Started At',
                DateFormat('MMMM dd, yyyy hh:mm:ss a').format(startedAt),
              ),
              _buildDetailRow(
                'Completed At',
                DateFormat('MMMM dd, yyyy hh:mm:ss a').format(completedAt),
              ),
              _buildDetailRow(
                'Duration',
                _formatDuration(transaction.durationMs),
              ),
              if (transaction.sourceMode != null)
                _buildDetailRow('Source Mode', transaction.sourceMode!),
              if (transaction.errorMessage != null &&
                  transaction.errorMessage!.isNotEmpty)
                _buildDetailRow('Error Message', transaction.errorMessage!),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingBreakdown)
              const Center(child: CircularProgressIndicator())
            else if (_breakdown.isEmpty)
              Text(
                'No transaction_breakdown rows were found for this transaction.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ..._breakdown.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _breakdownMetric('Code', item.categoryCode),
                          ),
                          Expanded(
                            child: _breakdownMetric('Qty', '${item.quantity}'),
                          ),
                          Expanded(
                            child: _breakdownMetric(
                              'Unit Price',
                              'P${NumberFormat('#,##0.00').format(item.unitPrice)}',
                            ),
                          ),
                          Expanded(
                            child: _breakdownMetric(
                              'Subtotal',
                              'P${NumberFormat('#,##0.00').format(item.subtotal)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  String _formatTicketRange(AdminTransaction transaction) {
    if (transaction.ticketStartNo == null && transaction.ticketEndNo == null) {
      return transaction.displayLabel;
    }
    if (transaction.ticketStartNo == transaction.ticketEndNo) {
      return '${transaction.ticketStartNo}';
    }
    return '${transaction.ticketStartNo ?? '-'} to ${transaction.ticketEndNo ?? '-'}';
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs < 0 ? 0 : durationMs);
    if (duration.inMinutes >= 1) {
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      return '${duration.inMinutes}m ${seconds}s';
    }
    return '${duration.inSeconds}s';
  }
}
