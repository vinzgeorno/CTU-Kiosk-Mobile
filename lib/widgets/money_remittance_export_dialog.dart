import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/export_service.dart';
import '../models/ticket_cache.dart';

class MoneyRemittanceExportDialog extends StatefulWidget {
  final List<TicketCache> allTickets;

  const MoneyRemittanceExportDialog({super.key, required this.allTickets});

  @override
  State<MoneyRemittanceExportDialog> createState() =>
      _MoneyRemittanceExportDialogState();
}

class _RemittancePreset {
  final String label;
  final int start;
  final int end;
  final bool overnight;

  const _RemittancePreset({
    required this.label,
    required this.start,
    required this.end,
    required this.overnight,
  });
}

const _kPresets = [
  _RemittancePreset(
    label: 'Day shift (8:00 AM – 4:00 PM, Taipei)',
    start: 8,
    end: 16,
    overnight: false,
  ),
  _RemittancePreset(
    label: 'Night shift (4:00 PM – 8:00 AM next day, Taipei)',
    start: 16,
    end: 8,
    overnight: true,
  ),
];

class _MoneyRemittanceExportDialogState
    extends State<MoneyRemittanceExportDialog> {
  final ExportService _exportService = ExportService();

  DateTime _selectedDate = DateTime.now();
  late String _selectedRange = _kPresets.first.label;
  int _startHour = _kPresets.first.start;
  int _endHour = _kPresets.first.end;
  bool _overnight = _kPresets.first.overnight;
  bool _isCustomRange = false;
  bool _isGenerating = false;

  /// SnackBars render under dialog routes; use root [Overlay] so feedback stays on top.
  void _showBannerOnTop(
    String message, {
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 12,
        right: 12,
        bottom: 16 + bottomPad,
        child: Material(
          color: backgroundColor,
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(duration, () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 28,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Money Remittance Export',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time Range Selection
              Text(
                'Select Time Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('preset_${_selectedRange}_$_isCustomRange'),
                initialValue: _selectedRange,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: _isCustomRange
                    ? null
                    : (value) {
                        if (value != null) {
                          final preset = _kPresets.firstWhere(
                            (p) => p.label == value,
                          );
                          setState(() {
                            _selectedRange = value;
                            _startHour = preset.start;
                            _endHour = preset.end;
                            _overnight = preset.overnight;
                          });
                        }
                      },
                items: _kPresets
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.label,
                        child: Text(
                          p.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Custom Range Toggle
              CheckboxListTile(
                title: const Text('Custom time (same Taipei day, start ≤ end hour)'),
                value: _isCustomRange,
                onChanged: (value) {
                  final on = value ?? false;
                  setState(() {
                    _isCustomRange = on;
                    if (!on) {
                      final preset = _kPresets.firstWhere(
                        (p) => p.label == _selectedRange,
                      );
                      _startHour = preset.start;
                      _endHour = preset.end;
                      _overnight = preset.overnight;
                    } else {
                      _overnight = false;
                      if (!_exportService.isValidHourRange(
                            _startHour,
                            _endHour,
                          )) {
                        _startHour = 8;
                        _endHour = 16;
                      }
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              // Custom Range Inputs
              if (_isCustomRange) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Hour (0-23)'),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g., 6',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              final hour = int.tryParse(value);
                              if (hour != null && hour >= 0 && hour <= 23) {
                                setState(() => _startHour = hour);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Hour (0-23)'),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g., 22',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              final hour = int.tryParse(value);
                              if (hour != null && hour >= 0 && hour <= 23) {
                                setState(() => _endHour = hour);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Times use Asia/Taipei. Day shift is 8:00–16:59 on the selected date; night shift is from 16:00 that date through before 08:00 the next day.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateExport,
                    icon: _isGenerating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'Generate CSV',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateExport() async {
    if (_isCustomRange &&
        !_exportService.isValidHourRange(_startHour, _endHour)) {
      _showBannerOnTop(
        'Invalid hour range. Start hour must be ≤ end hour (same Taipei day).',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Filter tickets for selected date and time range (Asia/Taipei)
      final filteredTickets = await _exportService.getTicketsForHourRange(
        widget.allTickets,
        date: _selectedDate,
        startHour: _startHour,
        endHour: _endHour,
        overnight: _overnight,
      );

      if (filteredTickets.isEmpty) {
        if (mounted) {
          _showBannerOnTop(
            'No tickets found for selected date and time range.',
            backgroundColor: Colors.orange.shade800,
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // Generate CSV
      final suffix = _overnight
          ? '$_startHour-${_endHour}_overnight'
          : '$_startHour-$_endHour';
      final csv = await _exportService.generateCsvExport(
        filteredTickets,
        filename:
            'remittance_${DateFormat('yyyyMMdd').format(_selectedDate)}_$suffix.csv',
      );

      if (mounted) {
        _showExportPreview(csv, filteredTickets.length);
      }
    } catch (e) {
      debugPrint('Error generating export: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error generating export: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showExportPreview(String csvContent, int ticketCount) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Generated Successfully!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tickets: $ticketCount\n'
                    'Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}\n'
                    '${_overnight ? 'Time (Taipei): $_startHour:00 on date shown → before $_endHour:00 next day' : 'Time (Taipei): $_startHour:00–$_endHour:59'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _downloadCsv(csvContent);
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download CSV'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _copyCsvToClipboard(csvContent);
                              },
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Copy to Clipboard'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyCsvToClipboard(String csvContent) async {
    try {
      // Copy to clipboard using Flutter's Clipboard API (works on all platforms)
      await Clipboard.setData(ClipboardData(text: csvContent));
      if (mounted) {
        _showBannerOnTop(
          '✓ CSV copied to clipboard successfully!',
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error copying to clipboard: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  Future<void> _downloadCsv(String csvContent) async {
    try {
      // Skip on web platform - web doesn't have document directories
      if (!Platform.isAndroid && !Platform.isIOS) {
        if (mounted) {
          _showBannerOnTop(
            'Download not available on this platform. Use "Copy to Clipboard" or "Share" instead.',
            backgroundColor: Colors.orange.shade800,
          );
        }
        return;
      }

      final filename =
          'remittance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      // Get the documents directory (works on Android and iOS)
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String filePath = '${documentsDirectory.path}/$filename';

      // Write the CSV content to file
      final File file = File(filePath);
      await file.writeAsString(csvContent);

      if (mounted) {
        // Show CSV preview dialog instead of just a snackbar
        _showCsvPreviewDialog(file, csvContent, filename);
      }
      debugPrint('CSV file saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving CSV: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error saving CSV: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  void _showCsvPreviewDialog(File file, String csvContent, String filename) {
    final lines = csvContent.split('\n');
    final previewLines = lines.take(20).toList();

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CSV File Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          filename,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // CSV Preview
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    previewLines.join('\n'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Courier',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              if (lines.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '... and ${lines.length - 20} more lines',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Action Buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _openCsvFile(file);
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _printCsv(csvContent, filename);
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _shareCsvFile(file);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _deleteCsvFile(file);
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCsvFile(File file) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Open with your preferred app');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error opening file: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  Future<void> _shareCsvFile(File file) async {
    try {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'CSV Export - ${file.path.split('/').last}');
    } catch (e) {
      debugPrint('Error sharing file: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error sharing file: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  Future<void> _printCsv(String csvContent, String filename) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  filename,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Generated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  csvContent,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: PdfPageFormat.a4,
        name: filename.replaceAll('.csv', ''),
      );

      if (mounted) {
        _showBannerOnTop(
          '✓ CSV sent to printer',
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Error printing CSV: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error printing CSV: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  Future<void> _deleteCsvFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        if (mounted) {
          _showBannerOnTop(
            '✓ CSV file deleted',
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          );
        }
        debugPrint('CSV file deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      if (mounted) {
        _showBannerOnTop(
          'Error deleting file: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }
}
