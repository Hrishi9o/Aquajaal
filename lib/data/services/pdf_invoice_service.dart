import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';
import '../../core/constants/app_strings.dart';

/// Service for generating, printing, and sharing standard Indian GST Tax Invoices
class PdfInvoiceService {
  PdfInvoiceService._();

  /// Generates the PDF document as raw bytes
  static Future<Uint8List> generatePdfBytes(Invoice invoice, StoreSettings settings) async {
    final pdf = pw.Document();

    // Load Yashodhar Enterprises logo from assets
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load(AppStrings.logoYashodhar);
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo fails to load
      logoImage = null;
    }

    final dateFormatter = DateFormat('dd-MMM-yyyy hh:mm a');
    final formattedDate = dateFormatter.format(invoice.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header with Logo & Business Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 68,
                      height: 68,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.Image(logoImage),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.distributorName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E4CB8),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          AppStrings.distributorTagline,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          settings.distributorAddress,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          settings.distributorCity,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'State: ${settings.stateName} (Code: ${settings.stateCode}) | Phone: ${settings.phone}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                        ),
                        if (settings.gstin.isNotEmpty)
                          pw.Text(
                            'GSTIN: ${settings.gstin}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
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
                          color: const PdfColor.fromInt(0xFF1E4CB8),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          AppStrings.taxInvoiceTitle,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Invoice #: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Payment: ${invoice.paymentMode}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(color: const PdfColor.fromInt(0xFF1E4CB8), thickness: 1.5),
              pw.SizedBox(height: 8),

              // Buyer / Customer Information
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Billed To (Customer):',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.customerName?.isNotEmpty == true ? invoice.customerName! : 'Counter Cash Customer',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        if (invoice.customerPhone?.isNotEmpty == true)
                          pw.Text(
                            'Phone: ${invoice.customerPhone}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Place of Supply:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${invoice.stateName} (${invoice.stateCode})',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Itemized Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: const {
                  0: pw.FixedColumnWidth(28),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FixedColumnWidth(55),
                  3: pw.FixedColumnWidth(38),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(70),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1E4CB8),
                    ),
                    children: [
                      _tableHeaderCell('S.N.'),
                      _tableHeaderCell('Description of Goods (Aquajaal)'),
                      _tableHeaderCell('HSN/SAC'),
                      _tableHeaderCell('Qty'),
                      _tableHeaderCell('Rate (₹)'),
                      _tableHeaderCell('Amount (₹)'),
                    ],
                  ),
                  // Table Rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                      ),
                      children: [
                        _tableDataCell(index.toString(), align: pw.TextAlign.center),
                        _tableDataCell(item.displayName),
                        _tableDataCell(item.hsnCode, align: pw.TextAlign.center),
                        _tableDataCell(item.quantity.toString(), align: pw.TextAlign.center),
                        _tableDataCell(item.unitPrice.toStringAsFixed(2), align: pw.TextAlign.right),
                        _tableDataCell(item.lineTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 10),

              // Summary Breakdown (Subtotal, Tax, Grand Total)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Amount in Words & Notes
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Amount in Words:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF1F8E3),
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFF98C528), width: 0.8),
                          ),
                          child: pw.Text(
                            invoice.amountInWords,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF1B2E05),
                            ),
                          ),
                        ),
                        if (invoice.notes?.isNotEmpty == true) ...[
                          pw.SizedBox(height: 6),
                          pw.Text('Notes: ${invoice.notes!}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                        pw.SizedBox(height: 12),
                        pw.Text(
                          AppStrings.invoiceDeclaration,
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Calculation Table
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        children: [
                          _summaryRow('Sub Total:', '₹${invoice.subtotal.toStringAsFixed(2)}'),
                          if (invoice.discount > 0)
                            _summaryRow('Discount:', '-₹${invoice.discount.toStringAsFixed(2)}', color: PdfColors.red700),
                          if (invoice.taxRate > 0) ...[
                            _summaryRow('CGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%):', '₹${invoice.cgst.toStringAsFixed(2)}'),
                            _summaryRow('SGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%):', '₹${invoice.sgst.toStringAsFixed(2)}'),
                          ] else
                            _summaryRow('GST Rate:', '0% (Exempt/Comp)'),
                          pw.Divider(color: PdfColors.grey400),
                          _summaryRow(
                            'Grand Total:',
                            '₹${invoice.grandTotal.toStringAsFixed(2)}',
                            isBold: true,
                            fontSize: 13,
                            color: const PdfColor.fromInt(0xFF1E4CB8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer Signatory
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppStrings.invoiceFooterNote, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Total Quantity Sold: ${invoice.totalUnits} Units', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'For ${settings.distributorName}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 36),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 3),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  /// Triggers the native platform print dialog (Web browser print or mobile print spooler)
  static Future<void> printInvoice(Invoice invoice, StoreSettings settings) async {
    final pdfBytes = await generatePdfBytes(invoice, settings);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Shares or downloads the invoice PDF file
  static Future<void> shareInvoicePdf(Invoice invoice, StoreSettings settings) async {
    final pdfBytes = await generatePdfBytes(invoice, settings);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
