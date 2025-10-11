import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../services/supabase_service.dart';

class TicketValidationDialog extends StatefulWidget {
  final Ticket ticket;

  const TicketValidationDialog({super.key, required this.ticket});

  @override
  State<TicketValidationDialog> createState() => _TicketValidationDialogState();
}

class _TicketValidationDialogState extends State<TicketValidationDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isInvalidating = false;

  Future<void> _invalidateTicket() async {
    setState(() => _isInvalidating = true);

    final success = await _supabaseService.invalidateTicket(
      widget.ticket.referenceNumber,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket marked as used'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isInvalidating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update ticket'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
              isValid ? 'Valid Ticket' : 'Invalid Ticket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
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
                  if (widget.ticket.facility != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Facility',
                      widget.ticket.facility!,
                      Icons.location_on,
                    ),
                  ],
                  if (widget.ticket.amount != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Amount',
                      '₱${widget.ticket.amount!.toStringAsFixed(2)}',
                      Icons.payments,
                    ),
                  ],
                  if (widget.ticket.visitDate != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Visit Date',
                      dateFormat.format(widget.ticket.visitDate!),
                      Icons.calendar_today,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Created',
                    dateFormat.format(widget.ticket.createdAt),
                    Icons.access_time,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isInvalidating
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                if (isValid) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInvalidating ? null : _invalidateTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isInvalidating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Mark as Used'),
                    ),
                  ),
                ],
              ],
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
