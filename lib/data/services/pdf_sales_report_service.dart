import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/store_settings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/sales_provider.dart';

/// Generates a comprehensive PDF Sales Summary Report
class PdfSalesReportService {
  PdfSalesReportService._();

  static Future<Uint8List> generateSalesReport({
    required StoreSettings settings,
    required String dateRangeLabel,
    required double totalRevenue,
    required int invoiceCount,
    required int totalUnits,
    required double avgOrderValue,
    required List<DailySalesSummary> dailyBreakdown,
    required List<TopSellerItem> topProducts,
  }) async {
    final pdf = pw.Document();

    // Load fonts supporting standard text and numerals
    final fontRegular = await PdfGoogleFonts.plusJakartaSansRegular();
    final fontBold = await PdfGoogleFonts.plusJakartaSansBold();

    // Load Yashodhar Enterprises badge
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_yashodhar.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    final primaryColor = PdfColor.fromHex('1E4CB8');
    final accentColor = PdfColor.fromHex('8DC63F');
    final textDark = PdfColor.fromHex('1E293B');
    final textMuted = PdfColor.fromHex('64748B');
    final bgTint = PdfColor.fromHex('F8FAFC');

    final generatedTimestamp = DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      margin: const pw.EdgeInsets.only(right: 14),
                      child: pw.Image(logoImage),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.distributorName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${settings.distributorAddress}, ${settings.distributorCity}',
                          style: pw.TextStyle(fontSize: 9, color: textMuted),
                        ),
                        pw.Text(
                          'State: ${settings.stateName} (Code: ${settings.stateCode}) | Phone: ${settings.phone}',
                          style: pw.TextStyle(fontSize: 9, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'SALES REPORT',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $dateRangeLabel',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: primaryColor, thickness: 1.5, height: 20),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: $generatedTimestamp | Aquajaal POS',
                style: pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: textMuted),
              ),
            ],
          );
        },
        build: (context) => [
          // 1. Executive Summary KPIs Box
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: bgTint,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildKpiCell('Total Revenue', CurrencyFormatter.format(totalRevenue), primaryColor),
                _buildKpiCell('Invoices Issued', '$invoiceCount', textDark),
                _buildKpiCell('Total Units Sold', '$totalUnits', textDark),
                _buildKpiCell('Average Bill Value', CurrencyFormatter.format(avgOrderValue), accentColor),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // 2. Top Products Table
          pw.Text(
            'Top Selling Products (Ranked by Revenue)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(36),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeaderCell('Rank', align: pw.TextAlign.center),
                  _tableHeaderCell('Product / Variant'),
                  _tableHeaderCell('Units Sold', align: pw.TextAlign.right),
                  _tableHeaderCell('Revenue (₹)', align: pw.TextAlign.right),
                  _tableHeaderCell('% Share', align: pw.TextAlign.right),
                ],
              ),
              if (topProducts.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('No sales records in this period', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Container(),
                    pw.Container(),
                    pw.Container(),
                    pw.Container(),
                  ],
                )
              else
                ...topProducts.take(8).toList().asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final item = entry.value;
                  final share = totalRevenue > 0 ? (item.revenue / totalRevenue) * 100 : 0.0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rank % 2 == 0 ? bgTint : PdfColors.white),
                    children: [
                      _tableCell('$rank', align: pw.TextAlign.center),
                      _tableCell(item.name, isBold: rank == 1),
                      _tableCell('${item.quantity}', align: pw.TextAlign.right),
                      _tableCell(CurrencyFormatter.format(item.revenue), align: pw.TextAlign.right),
                      _tableCell('${share.toStringAsFixed(1)}%', align: pw.TextAlign.right),
                    ],
                  );
                }),
            ],
          ),
          pw.SizedBox(height: 20),

          // 3. Daily Breakdown Table
          pw.Text(
            'Daily Sales Breakdown',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeaderCell('Date'),
                  _tableHeaderCell('Invoices', align: pw.TextAlign.right),
                  _tableHeaderCell('Units Sold', align: pw.TextAlign.right),
                  _tableHeaderCell('Revenue (₹)', align: pw.TextAlign.right),
                ],
              ),
              if (dailyBreakdown.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('No daily breakdown data available', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Container(),
                    pw.Container(),
                    pw.Container(),
                  ],
                )
              else
                ...dailyBreakdown.map((day) {
                  return pw.TableRow(
                    children: [
                      _tableCell(day.dateLabel),
                      _tableCell('${day.invoiceCount}', align: pw.TextAlign.right),
                      _tableCell('${day.unitsSold}', align: pw.TextAlign.right),
                      _tableCell(CurrencyFormatter.format(day.revenue), align: pw.TextAlign.right),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCell(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('64748B'))),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('1E293B'),
        ),
      ),
    );
  }

  /// Preview & Share Sales Report PDF
  static Future<void> exportAndPreviewReport({
    required StoreSettings settings,
    required String dateRangeLabel,
    required double totalRevenue,
    required int invoiceCount,
    required int totalUnits,
    required double avgOrderValue,
    required List<DailySalesSummary> dailyBreakdown,
    required List<TopSellerItem> topProducts,
  }) async {
    final pdfBytes = await generateSalesReport(
      settings: settings,
      dateRangeLabel: dateRangeLabel,
      totalRevenue: totalRevenue,
      invoiceCount: invoiceCount,
      totalUnits: totalUnits,
      avgOrderValue: avgOrderValue,
      dailyBreakdown: dailyBreakdown,
      topProducts: topProducts,
    );

    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final filename = 'YE_Sales_Report_$timestamp.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: filename,
    );
  }
}
