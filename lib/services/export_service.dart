import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'report_service.dart';
import '../models/production_entry_model.dart';
import '../models/money_entry_model.dart';
import '../models/quotation_model.dart';
import '../utils/date_utils.dart';
import '../utils/money_utils.dart';

/// Service for exporting reports as PDF and CSV.
class ExportService {
  /// Loads the organization logo from base64 or file path.
  Future<Uint8List?> _loadLogo(String? logoPath, String? logoBase64) async {
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        return base64Decode(logoBase64);
      } catch (_) {}
    }
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Builds a PDF header with optional logo.
  pw.Widget _buildPdfHeader(
    String title,
    String subtitle,
    String orgName,
    Uint8List? logoBytes,
    {String? address, String? contact}
  ) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
        if (logoBytes != null) ...[
          pw.Container(
            height: 40,
            child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Text(
          orgName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1B4B'),
          ),
        ),
        if (address != null && address.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            address,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
        if (contact != null && contact.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Contact: $contact',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty)
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ],
        pw.SizedBox(height: 12),
      ],
    ));
  }

  /// Export daily report as PDF.
  Future<void> exportDailyReportPdf(
    DailyReportData report,
    String orgName,
    String currency, {
    String? logoPath,
    String? logoBase64,
    String? date,
    String? address,
    String? contact,
  }) async {
    final logoBytes = await _loadLogo(logoPath, logoBase64);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Powered by BahiKhata',
                  style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          _buildPdfHeader(
            'Daily Report',
            'Date: ${AppDateUtils.displayDate(date ?? report.date)}',
            orgName,
            logoBytes,
            address: address,
            contact: contact,
          ),
          // Production entries table
          if (report.productionEntries.isNotEmpty) ...[
            pw.Text('Production Entries',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8EAF6')),
              headers: ['Staff', 'Items Breakdown', 'Total Qty', 'Total Amount'],
              data: (report.productionEntries.toList()..sort((a, b) => a.staffName.compareTo(b.staffName))).map((entry) {
                final breakdown = entry.items
                    .where((i) => i.quantity > 0)
                    .map((i) => '${i.itemTypeName} (${i.quantity})')
                    .join(', ');
                return [
                  entry.staffName,
                  breakdown,
                  entry.totalQuantity.toString(),
                  MoneyUtils.formatCurrencyCompact(entry.totalAmount, currency),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 12),
          ],
          // Money entries
          if (report.moneyEntries.isNotEmpty) ...[
            pw.Text('Money Entries',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF3E0')),
              headers: ['Staff', 'Type', 'Amount', 'Notes'],
              data: () {
                final grouped = <String, List<dynamic>>{};
                for (var e in report.moneyEntries) {
                  grouped.putIfAbsent(e.staffName, () => []).add(e);
                }
                final sortedStaff = grouped.keys.toList()..sort();
                return sortedStaff.map((staffName) {
                  final entries = grouped[staffName]!;
                  final types = entries.map((e) => e.type.displayName).toSet().join(', ');
                  final totalAmount = entries.fold<double>(0, (sum, e) => sum + e.amount);
                  final notes = entries.map((e) => e.notes).where((n) => n != null && n.isNotEmpty).join(' | ');
                  return [
                    staffName,
                    types,
                    MoneyUtils.formatCurrencyCompact(totalAmount, currency),
                    notes,
                  ];
                }).toList();
              }(),
            ),
            pw.SizedBox(height: 12),
          ],
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F5F5'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                _summaryRow('Total Items', report.totalItems.toString()),
                _summaryRow('Total Production',
                    MoneyUtils.formatCurrencyCompact(report.totalProduction, currency)),
                _summaryRow('Total Payments',
                    MoneyUtils.formatCurrencyCompact(report.totalPayments, currency)),
                pw.Divider(),
                _summaryRow('Net Payable',
                    MoneyUtils.formatCurrencyCompact(report.netPayable, currency),
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'daily_report_${date ?? report.date}');
  }

  /// Export monthly report as PDF.
  Future<void> exportMonthlyReportPdf(
    MonthlyReportData report,
    String orgName,
    String currency, {
    String? logoPath,
    String? logoBase64,
    String? address,
    String? contact,
  }) async {
    final logoBytes = await _loadLogo(logoPath, logoBase64);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Powered by BahiKhata',
                  style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          _buildPdfHeader(
            'Monthly Report',
            'Month: ${AppDateUtils.displayMonth(report.month)}',
            orgName,
            logoBytes,
            address: address,
            contact: contact,
          ),
          ...report.staffData.map((staff) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(staff.staffName,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    // Item breakdown
                    pw.TableHelper.fromTextArray(
                      headerStyle:
                          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      cellStyle: const pw.TextStyle(fontSize: 9),
                      headerDecoration:
                          pw.BoxDecoration(color: PdfColor.fromHex('#E8EAF6')),
                      headers: ['Item', 'Qty', 'Rate', 'Amount'],
                      data: staff.itemBreakdown.values.map((item) => [
                            item.itemTypeName,
                            item.totalQuantity.toString(),
                            MoneyUtils.formatCurrencyCompact(item.rate, currency),
                            MoneyUtils.formatCurrencyCompact(
                                item.totalAmount, currency),
                          ]).toList(),
                    ),
                    pw.SizedBox(height: 8),
                    _summaryRow('Gross Production',
                        MoneyUtils.formatCurrencyCompact(staff.grossProduction, currency)),
                    if (staff.totalBonus > 0)
                      _summaryRow('Bonus (+)',
                          MoneyUtils.formatCurrencyCompact(staff.totalBonus, currency)),
                    if (staff.totalAdvance > 0)
                      _summaryRow('Advance (-)',
                          MoneyUtils.formatCurrencyCompact(staff.totalAdvance, currency)),
                    if (staff.totalPartialPayment > 0)
                      _summaryRow('Partial Payment (-)',
                          MoneyUtils.formatCurrencyCompact(
                              staff.totalPartialPayment, currency)),
                    if (staff.totalFinalPayment > 0)
                      _summaryRow('Final Payment (-)',
                          MoneyUtils.formatCurrencyCompact(
                              staff.totalFinalPayment, currency)),
                    if (staff.totalDeduction > 0)
                      _summaryRow('Deduction (-)',
                          MoneyUtils.formatCurrencyCompact(
                              staff.totalDeduction, currency)),
                    pw.Divider(),
                    _summaryRow('Final Payable',
                        MoneyUtils.formatCurrencyCompact(staff.finalPayable, currency),
                        bold: true),
                  ],
                ),
              )),
          // Grand totals
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8EAF6'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _summaryRow('Grand Total Production',
                    MoneyUtils.formatCurrencyCompact(report.totalGrossProduction, currency),
                    bold: true),
                _summaryRow('Grand Total Payments',
                    MoneyUtils.formatCurrencyCompact(report.totalPayments, currency),
                    bold: true),
                pw.Divider(),
                _summaryRow('Grand Total Payable',
                    MoneyUtils.formatCurrencyCompact(report.totalPayable, currency),
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'monthly_report_${report.month}');
  }

  /// Export staff ledger as PDF.
  Future<void> exportStaffLedgerPdf(
    List<LedgerEntry> entries,
    String staffName,
    String month,
    String orgName,
    String currency, {
    String? logoPath,
    String? logoBase64,
    String? address,
    String? contact,
  }) async {
    final logoBytes = await _loadLogo(logoPath, logoBase64);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Powered by BahiKhata',
                  style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          _buildPdfHeader(
            'Staff Ledger - $staffName',
            'Generated: ${AppDateUtils.displayDate(DateTime.now().toIso8601String().split('T').first)}',
            orgName,
            logoBytes,
            address: address,
            contact: contact,
          ),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8EAF6')),
            headers: ['Date', 'Description', 'Earned', 'Paid/Advance', 'Balance'],
            data: entries.map((e) => [
                  AppDateUtils.displayDate(e.date),
                  e.description,
                  e.earned > 0
                      ? MoneyUtils.formatCurrencyCompact(e.earned, currency)
                      : '-',
                  e.paid > 0
                      ? MoneyUtils.formatCurrencyCompact(e.paid, currency)
                      : '-',
                  MoneyUtils.formatCurrencyCompact(e.balance, currency),
                ]).toList(),
          ),
          if (entries.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F5F5'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: _summaryRow('Final Balance',
                  MoneyUtils.formatCurrencyCompact(entries.last.balance, currency),
                  bold: true),
            ),
          ],
        ],
      ),
    );

    await _savePdf(pdf, 'ledger_${staffName.toLowerCase()}_$month');
  }

  /// Export monthly report as CSV.
  Future<void> exportMonthlyReportCsv(
    MonthlyReportData report,
    String currency,
  ) async {
    final rows = <List<String>>[];

    // Header
    rows.add(['Staff', 'Item', 'Quantity', 'Rate', 'Amount']);

    for (final staff in report.staffData) {
      for (final item in staff.itemBreakdown.values) {
        rows.add([
          staff.staffName,
          item.itemTypeName,
          item.totalQuantity.toString(),
          item.rate.toString(),
          item.totalAmount.toString(),
        ]);
      }
      rows.add([
        staff.staffName,
        'GROSS TOTAL',
        staff.totalItems.toString(),
        '',
        staff.grossProduction.toString(),
      ]);
      rows.add([
        staff.staffName,
        'Advance',
        '',
        '',
        (-staff.totalAdvance).toString(),
      ]);
      if (staff.totalBonus > 0) {
        rows.add([
          staff.staffName,
          'Bonus',
          '',
          '',
          staff.totalBonus.toString(),
        ]);
      }
      rows.add([
        staff.staffName,
        'FINAL PAYABLE',
        '',
        '',
        staff.finalPayable.toString(),
      ]);
      rows.add(['', '', '', '', '']); // Empty row separator
    }

    final csvString = rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
    final bytes = utf8.encode(csvString);

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), name: 'monthly_report_${report.month}.csv', mimeType: 'text/csv')],
        text: 'Monthly Report - ${report.month}',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/monthly_report_${report.month}.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Monthly Report - ${report.month}',
      );
    }
  }

  pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> exportQuotationPdf({
    required Quotation quotation,
    required String organizationName,
    required String address,
    required String contact,
    String? logoBase64,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogo(null, logoBase64);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                pw.SizedBox(height: 24),
                pw.Text(
                  'QUALITY YOU CAN TRUST',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '"DON\'T JUST COMPARE PRICING; COMPARE QUALITY TOO."',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          String? lastGroup = null;

          return [
            _buildPdfHeader(
              '',
              '',
              organizationName,
              logoBytes,
              address: address,
              contact: contact,
            ),
            pw.Divider(color: PdfColors.grey400, thickness: 1),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                quotation.title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 20),
            ...quotation.sections.map((section) {
              final isNewGroup = section.groupName.isNotEmpty && section.groupName != lastGroup;
              if (isNewGroup) lastGroup = section.groupName;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (isNewGroup) ...[
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text(
                        section.groupName,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                  ],
                  if (section.sectionName.isNotEmpty) ...[
                    pw.Text(section.sectionName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 6),
                  ],
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8EAF6')),
                    headers: ['S.N.', 'Items', 'Amount'],
                    data: section.items.asMap().entries.map((entry) => [
                          (entry.key + 1).toString(),
                          entry.value.description,
                          '${MoneyUtils.formatCurrencyCompact(entry.value.amount, currency)} /-',
                        ]).toList(),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(40),
                      1: const pw.FlexColumnWidth(),
                      2: const pw.FixedColumnWidth(80),
                    },
                  ),
                  pw.SizedBox(height: 16),
                ],
              );
            }).toList(),
            if (quotation.note.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Note: ${quotation.note}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ];
        },
      ),
    );

    await _savePdf(pdf, 'quotation_${quotation.title.replaceAll(' ', '_')}');
  }

  Future<void> _savePdf(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    if (kIsWeb) {
      // Use SharePlus on Web. This natively triggers the Web Share API
      // (iOS Share Sheet, Android Share) on mobile browsers.
      // If Web Share API is unsupported (like Desktop Chrome), it falls back to an anchor download.
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: '$filename.pdf', mimeType: 'application/pdf')],
      );
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '$filename.pdf',
      );
    }
  }
}

