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
                color: ticket.isValid ? Colors.green.shade700 : Colors.red.shade700,
              ),
              child: Column(
                children: [
                  Icon(
                    ticket.isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.isValid ? 'VALID TICKET' : 'INVALID TICKET',
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

            // Captured Image (if available)
            if (ticket.imageUrl != null) ...[
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                          Icon(Icons.photo_camera, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Text(
                            'Captured Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: Image.network(
                        ticket.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Customer Information
            _buildSection(
              context,
              'Customer Information',
              Icons.person_outline,
              [
                _buildDetailRow('Full Name', ticket.name),
                if (ticket.email != null) _buildDetailRow('Email', ticket.email!),
                if (ticket.phone != null) _buildDetailRow('Phone', ticket.phone!),
              ],
            ),

            // Visit Information
            _buildSection(
              context,
              'Visit Information',
              Icons.info_outline,
              [
                _buildDetailRow('Facility', ticket.facility),
                _buildDetailRow('Amount', '₱${NumberFormat('#,##0.00').format(ticket.amount)}'),
                _buildDetailRow('Visit Date', DateFormat('MMMM dd, yyyy').format(ticket.visitDate)),
                _buildDetailRow('Visit Time', DateFormat('hh:mm a').format(ticket.visitDate)),
              ],
            ),

            // Ticket Information
            _buildSection(
              context,
              'Ticket Information',
              Icons.confirmation_number_outlined,
              [
                _buildDetailRow('Reference Number', ticket.referenceNumber),
                _buildDetailRow('Created At', DateFormat('MMM dd, yyyy hh:mm a').format(ticket.createdAt)),
                _buildDetailRow('Status', ticket.isValid ? 'Valid' : 'Invalid'),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
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
            child: Column(
              children: children,
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
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
