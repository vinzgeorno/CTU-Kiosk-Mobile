import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_cache.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketCache ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ticket Details'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ticket.transactionStatus == 'completed'
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
              child: Column(
                children: [
                  Icon(
                    ticket.transactionStatus == 'completed'
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.transactionStatus == 'completed'
                        ? 'COMPLETED'
                        : ticket.transactionStatus.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.referenceNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Visit Information
            _buildSection(context, 'Visit Information', Icons.info_outline, [
              _buildDetailRow('Facility', ticket.facility),
              _buildDetailRow(
                'Amount',
                '₱${NumberFormat('#,##0.00').format(ticket.amount)}',
              ),
              _buildDetailRow(
                'Visit Date',
                DateFormat('MMMM dd, yyyy').format(ticket.visitDate),
              ),
              _buildDetailRow(
                'Visit Time',
                DateFormat('hh:mm a').format(ticket.visitDate),
              ),
            ]),

            // Ticket Information
            _buildSection(
              context,
              'Ticket Information',
              Icons.confirmation_number_outlined,
              [
                _buildDetailRow('Reference Number', ticket.referenceNumber),
                _buildDetailRow(
                  'Created At',
                  DateFormat('MMM dd, yyyy hh:mm a').format(ticket.createdAt),
                ),
                _buildDetailRow(
                  'Status',
                  ticket.transactionStatus == 'completed'
                      ? 'Completed'
                      : ticket.transactionStatus,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
