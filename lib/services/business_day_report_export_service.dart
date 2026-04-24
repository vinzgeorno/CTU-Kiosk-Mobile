import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../models/business_day_report.dart';

class BusinessDayReportExportService {
  ExcelReportFile buildExcelReportFile(BusinessDayReport report) {
    return ExcelReportFile(
      fileName:
          'business_day_report_${DateFormat('yyyyMMdd').format(report.businessDate)}.xlsx',
      bytes: _buildWorkbookBytes([
        _WorksheetData(name: 'Summary', rows: _buildSummaryRows(report)),
        _WorksheetData(name: 'Breakdown', rows: _buildBreakdownRows(report)),
      ]),
    );
  }

  Future<File> saveExcelReport(BusinessDayReport report) async {
    final excelReport = buildExcelReportFile(report);

    final directory = await _createExportDirectory();
    final file = File('${directory.path}/${excelReport.fileName}');
    await file.create(recursive: true);
    await file.writeAsBytes(excelReport.bytes, flush: true);
    return file;
  }

  List<List<String>> _buildSummaryRows(BusinessDayReport report) {
    final rows = <List<String>>[
      ['CTU Kiosk Business Day Summary'],
      [
        'Coverage',
        '${DateFormat('MMM dd, yyyy hh:mm a').format(report.startAt)} - ${DateFormat('MMM dd, yyyy hh:mm a').format(report.endAt)}',
      ],
      [
        'Generated At',
        DateFormat('MMM dd, yyyy hh:mm a').format(report.generatedAt),
      ],
      const [''],
      ['Total Sales', _currency(report.totalSales)],
      ['Transactions', '${report.totalTransactions}'],
      ['Units', '${report.totalUnits}'],
      ['Facilities', '${report.facilitySummaries.length}'],
      const [''],
      const [
        'Facility',
        'Ticket Label Range',
        'Total Sales',
        'Transactions',
        'Kids',
        'Adults',
        'Units',
      ],
    ];

    for (final summary in report.facilitySummaries) {
      rows.add([
        '${summary.facilityName} (${summary.facilityCode})',
        summary.ticketLabelRange,
        _currency(summary.totalSales),
        '${summary.transactionCount}',
        '${summary.kidsUnits}',
        '${summary.adultUnits}',
        '${summary.totalUnits}',
      ]);
    }

    return rows;
  }

  List<List<String>> _buildBreakdownRows(BusinessDayReport report) {
    final rows = <List<String>>[
      const ['Facility', 'Ticket Label Range', 'Category', 'Units', 'Sales'],
    ];

    if (report.facilitySummaries.isEmpty) {
      rows.add(const ['No transactions found for this business day.']);
      return rows;
    }

    for (final summary in report.facilitySummaries) {
      final categories = summary.unitsByCategory.keys.toList(growable: false)
        ..sort();

      if (categories.isEmpty) {
        rows.add([
          '${summary.facilityName} (${summary.facilityCode})',
          summary.ticketLabelRange,
          'No breakdown rows',
          '0',
          _currency(0),
        ]);
        continue;
      }

      for (final category in categories) {
        rows.add([
          '${summary.facilityName} (${summary.facilityCode})',
          summary.ticketLabelRange,
          category,
          '${summary.unitsByCategory[category] ?? 0}',
          _currency(summary.salesByCategory[category] ?? 0),
        ]);
      }
    }

    return rows;
  }

  Uint8List _buildWorkbookBytes(List<_WorksheetData> worksheets) {
    final archive = Archive();
    final sharedStrings = _buildSharedStrings(worksheets);

    _addTextFile(
      archive,
      '[Content_Types].xml',
      _buildContentTypesXml(worksheets),
    );
    _addTextFile(archive, '_rels/.rels', _buildRootRelationshipsXml());
    _addTextFile(
      archive,
      'docProps/app.xml',
      _buildAppPropertiesXml(worksheets),
    );
    _addTextFile(
      archive,
      'docProps/core.xml',
      _buildCorePropertiesXml(DateTime.now().toUtc()),
    );
    _addTextFile(archive, 'xl/workbook.xml', _buildWorkbookXml(worksheets));
    _addTextFile(
      archive,
      'xl/_rels/workbook.xml.rels',
      _buildWorkbookRelationshipsXml(worksheets),
    );
    _addTextFile(archive, 'xl/styles.xml', _buildStylesXml());
    _addTextFile(
      archive,
      'xl/sharedStrings.xml',
      _buildSharedStringsXml(sharedStrings),
    );

    for (var index = 0; index < worksheets.length; index++) {
      _addTextFile(
        archive,
        'xl/worksheets/sheet${index + 1}.xml',
        _buildWorksheetXml(worksheets[index], sharedStrings),
      );
    }

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw StateError('Failed to generate Excel workbook.');
    }

    return Uint8List.fromList(bytes);
  }

  String _currency(double amount) {
    return 'P${NumberFormat('#,##0.00').format(amount)}';
  }

  void _addTextFile(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  String _buildContentTypesXml(List<_WorksheetData> worksheets) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln(
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
      )
      ..writeln(
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
      )
      ..writeln('<Default Extension="xml" ContentType="application/xml"/>')
      ..writeln(
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
      )
      ..writeln(
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>',
      )
      ..writeln(
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
      )
      ..writeln(
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
      )
      ..writeln(
        '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>',
      );

    for (var index = 0; index < worksheets.length; index++) {
      buffer.writeln(
        '<Override PartName="/xl/worksheets/sheet${index + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
    }

    buffer.writeln('</Types>');
    return buffer.toString();
  }

  String _buildRootRelationshipsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  }

  String _buildAppPropertiesXml(List<_WorksheetData> worksheets) {
    final titles = worksheets
        .map(
          (worksheet) => '<vt:lpstr>${_escapeXml(worksheet.name)}</vt:lpstr>',
        )
        .join();

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>CTU Kiosk Mobile</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <HeadingPairs>
    <vt:vector size="2" baseType="variant">
      <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>
      <vt:variant><vt:i4>${worksheets.length}</vt:i4></vt:variant>
    </vt:vector>
  </HeadingPairs>
  <TitlesOfParts>
    <vt:vector size="${worksheets.length}" baseType="lpstr">$titles</vt:vector>
  </TitlesOfParts>
  <Company></Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>1.0</AppVersion>
</Properties>''';
  }

  String _buildCorePropertiesXml(DateTime generatedAt) {
    final timestamp = generatedAt.toIso8601String();

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>CTU Kiosk Mobile</dc:creator>
  <cp:lastModifiedBy>CTU Kiosk Mobile</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$timestamp</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$timestamp</dcterms:modified>
</cp:coreProperties>''';
  }

  String _buildWorkbookXml(List<_WorksheetData> worksheets) {
    final sheets = StringBuffer();
    for (var index = 0; index < worksheets.length; index++) {
      sheets.writeln(
        '<sheet name="${_escapeXml(worksheets[index].name)}" sheetId="${index + 1}" r:id="rId${index + 1}"/>',
      );
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews>
    <workbookView xWindow="0" yWindow="0" windowWidth="28800" windowHeight="17100"/>
  </bookViews>
  <sheets>
${sheets.toString().trimRight()}
  </sheets>
</workbook>''';
  }

  String _buildWorkbookRelationshipsXml(List<_WorksheetData> worksheets) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln(
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
      );

    for (var index = 0; index < worksheets.length; index++) {
      buffer.writeln(
        '<Relationship Id="rId${index + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${index + 1}.xml"/>',
      );
    }

    buffer
      ..writeln(
        '<Relationship Id="rId${worksheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
      )
      ..writeln(
        '<Relationship Id="rId${worksheets.length + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>',
      )
      ..writeln('</Relationships>');

    return buffer.toString();
  }

  String _buildStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1">
    <font>
      <sz val="11"/>
      <color theme="1"/>
      <name val="Calibri"/>
      <family val="2"/>
      <scheme val="minor"/>
    </font>
  </fonts>
  <fills count="2">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>''';
  }

  String _buildWorksheetXml(
    _WorksheetData worksheet,
    Map<String, int> sharedStrings,
  ) {
    final rows = worksheet.rows;
    final dimension = _worksheetDimension(rows);
    final rowBuffer = StringBuffer();

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      rowBuffer.write('<row r="${rowIndex + 1}" spans="1:${row.length}">');
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final value = row[columnIndex];
        final cellReference = _cellReference(rowIndex, columnIndex);
        rowBuffer.write(_buildCellXml(cellReference, value, sharedStrings));
      }
      rowBuffer.writeln('</row>');
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <dimension ref="$dimension"/>
  <sheetViews>
    <sheetView workbookViewId="0"/>
  </sheetViews>
  <sheetFormatPr defaultRowHeight="15"/>
  <sheetData>
${rowBuffer.toString().trimRight()}
  </sheetData>
  <pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>
</worksheet>''';
  }

  Map<String, int> _buildSharedStrings(List<_WorksheetData> worksheets) {
    final sharedStrings = <String, int>{};

    for (final worksheet in worksheets) {
      for (final row in worksheet.rows) {
        for (final value in row) {
          if (_isNumericCellValue(value)) {
            continue;
          }
          sharedStrings.putIfAbsent(value, () => sharedStrings.length);
        }
      }
    }

    return sharedStrings;
  }

  String _buildSharedStringsXml(Map<String, int> sharedStrings) {
    final orderedValues = List<String>.filled(sharedStrings.length, '');
    for (final entry in sharedStrings.entries) {
      orderedValues[entry.value] = entry.key;
    }

    final items = orderedValues
        .map(
          (value) =>
              '<si><t xml:space="preserve">${_escapeXml(value)}</t></si>',
        )
        .join();

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${orderedValues.length}" uniqueCount="${orderedValues.length}">$items</sst>''';
  }

  String _buildCellXml(
    String cellReference,
    String value,
    Map<String, int> sharedStrings,
  ) {
    if (_isNumericCellValue(value)) {
      return '<c r="$cellReference"><v>${value.trim()}</v></c>';
    }

    final sharedStringIndex = sharedStrings[value];
    if (sharedStringIndex == null) {
      throw StateError('Missing shared string value for "$value".');
    }

    return '<c r="$cellReference" t="s"><v>$sharedStringIndex</v></c>';
  }

  bool _isNumericCellValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('P')) {
      return false;
    }

    return RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(trimmed);
  }

  String _worksheetDimension(List<List<String>> rows) {
    if (rows.isEmpty) {
      return 'A1';
    }

    var maxColumns = 1;
    for (final row in rows) {
      if (row.length > maxColumns) {
        maxColumns = row.length;
      }
    }

    return 'A1:${_cellReference(rows.length - 1, maxColumns - 1)}';
  }

  String _cellReference(int rowIndex, int columnIndex) {
    return '${_columnName(columnIndex)}${rowIndex + 1}';
  }

  String _columnName(int columnIndex) {
    var currentIndex = columnIndex + 1;
    final buffer = StringBuffer();

    while (currentIndex > 0) {
      final remainder = (currentIndex - 1) % 26;
      buffer.writeCharCode(65 + remainder);
      currentIndex = (currentIndex - 1) ~/ 26;
    }

    return buffer.toString().split('').reversed.join();
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<Directory> _createExportDirectory() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/ctu_kiosk_reports',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}

class _WorksheetData {
  const _WorksheetData({required this.name, required this.rows});

  final String name;
  final List<List<String>> rows;
}

class ExcelReportFile {
  const ExcelReportFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
