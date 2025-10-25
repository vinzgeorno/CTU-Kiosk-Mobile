import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';

class TicketValidationDialog extends StatefulWidget {
  final Ticket ticket;

  const TicketValidationDialog({super.key, required this.ticket});

  @override
  State<TicketValidationDialog> createState() => _TicketValidationDialogState();
}

class _TicketValidationDialogState extends State<TicketValidationDialog> {

  @override
  Widget build(BuildContext context) {
    final isValid = widget.ticket.isValid;
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            // Status Text
            Text(
              isValid ? 'Valid Ticket' : widget.ticket.isExpired ? 'Expired Ticket' : 'Invalid Ticket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            // Expiry Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isValid ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                widget.ticket.expiryStatus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ticket Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Reference Number',
                    widget.ticket.referenceNumber,
                    Icons.confirmation_number,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Name',
                    widget.ticket.name,
                    Icons.person,
                  ),
                  if (widget.ticket.age != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Age',
                      '${widget.ticket.age} years old',
                      Icons.cake,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Facility',
                    widget.ticket.facility,
                    Icons.location_on,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Amount Paid',
                    '₱${widget.ticket.paymentAmount.toStringAsFixed(2)}',
                    Icons.payments,
                  ),
                  if (widget.ticket.hasDiscount && widget.ticket.originalPrice != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Original Price',
                      '₱${widget.ticket.originalPrice!.toStringAsFixed(2)}',
                      Icons.discount,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Date Created',
                    dateFormat.format(widget.ticket.dateCreated),
                    Icons.calendar_today,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Expiry Date',
                    dateFormat.format(widget.ticket.dateExpiry),
                    Icons.event_busy,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Status',
                    widget.ticket.transactionStatus.toUpperCase(),
                    Icons.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isValid ? 'Accept & Close' : 'Close',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
