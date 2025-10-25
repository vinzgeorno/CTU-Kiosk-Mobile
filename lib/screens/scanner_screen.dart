import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/supabase_service.dart';
import '../widgets/ticket_validation_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _referenceController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validateTicket(String referenceNumber) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('Validating ticket: $referenceNumber');
      final ticket = await _supabaseService.validateTicket(referenceNumber);
      
      if (!mounted) return;

      if (ticket != null) {
        debugPrint('Ticket found: ${ticket.referenceNumber}');
        debugPrint('  - Name: ${ticket.name}');
        debugPrint('  - Facility: ${ticket.facility}');
        debugPrint('  - Amount: ₱${ticket.paymentAmount}');
        debugPrint('  - Status: ${ticket.transactionStatus}');
        debugPrint('  - Expiry: ${ticket.dateExpiry}');
        debugPrint('  - Is Valid: ${ticket.isValid}');
        debugPrint('  - Is Expired: ${ticket.isExpired}');
        debugPrint('  - Expiry Status: ${ticket.expiryStatus}');
        
        await showDialog(
          context: context,
          builder: (context) => TicketValidationDialog(ticket: ticket),
        );
      } else {
        debugPrint('Ticket not found: $referenceNumber');
        _showErrorDialog('Ticket Not Found', 
            'No ticket found with reference number: $referenceNumber');
      }
    } catch (e) {
      debugPrint('Error validating ticket: $e');
      if (!mounted) return;
      _showErrorDialog('Error', 'Failed to validate ticket: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Validation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // QR Scanner Section
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 300,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _validateTicket(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
            ),

            // Manual Reference Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Reference Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'Enter ticket reference number',
                      prefixIcon: const Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _validateTicket(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (_referenceController.text.isNotEmpty) {
                                _validateTicket(_referenceController.text);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Validate Ticket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
