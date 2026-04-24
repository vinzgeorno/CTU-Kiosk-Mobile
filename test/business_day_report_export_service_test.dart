import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctu_kiosk_mobile/models/business_day_report.dart';
import 'package:ctu_kiosk_mobile/services/business_day_report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BusinessDayReportExportService', () {
    test('writes an Excel workbook to disk', () async {
      final service = BusinessDayReportExportService();
      final report = BusinessDayReport(
        businessDate: DateTime(2026, 3, 30),
        startAt: DateTime(2026, 3, 30, 9),
        endAt: DateTime(2026, 3, 31, 9),
        totalSales: 1234.5,
        totalTransactions: 2,
        totalUnits: 5,
        facilitySummaries: const [
          FacilityBusinessSummary(
            facilityCode: 'OV',
            facilityName: 'Ocean View',
            ticketLabelRange: 'OV-0001-OV-0003',
            totalSales: 1234.5,
            transactionCount: 2,
            totalUnits: 5,
            kidsUnits: 2,
            adultUnits: 3,
            unitsByCategory: {'Kid': 2, 'Adult': 3},
            salesByCategory: {'Kid': 400, 'Adult': 834.5},
          ),
        ],
        generatedAt: DateTime(2026, 3, 30, 10, 30),
      );

      final file = await service.saveExcelReport(report);

      addTearDown(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });

      expect(file, isA<File>());
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      expect(archive.findFile('[Content_Types].xml'), isNotNull);
      expect(archive.findFile('xl/workbook.xml'), isNotNull);
      expect(archive.findFile('xl/sharedStrings.xml'), isNotNull);
      expect(archive.findFile('xl/worksheets/sheet1.xml'), isNotNull);
      expect(archive.findFile('xl/worksheets/sheet2.xml'), isNotNull);

      final workbookFile = archive.findFile('xl/workbook.xml');
      expect(workbookFile, isNotNull);
      final workbookXml = utf8.decode(workbookFile!.content as List<int>);
      expect(workbookXml, contains('Summary'));
      expect(workbookXml, contains('Breakdown'));

      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      expect(sharedStringsFile, isNotNull);
      final sharedStringsXml = utf8.decode(
        sharedStringsFile!.content as List<int>,
      );
      expect(sharedStringsXml, contains('CTU Kiosk Business Day Summary'));
      expect(sharedStringsXml, contains('Ocean View (OV)'));

      final summarySheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      expect(summarySheetFile, isNotNull);
      final summarySheetXml = utf8.decode(
        summarySheetFile!.content as List<int>,
      );
      expect(summarySheetXml, contains('<dimension ref="A1:G11"'));
      expect(summarySheetXml, contains('<c r="B6"><v>2</v></c>'));

      final breakdownSheetFile = archive.findFile('xl/worksheets/sheet2.xml');
      expect(breakdownSheetFile, isNotNull);
      final breakdownSheetXml = utf8.decode(
        breakdownSheetFile!.content as List<int>,
      );
      expect(breakdownSheetXml, contains('<dimension ref="A1:E3"'));
    });
  });
}
