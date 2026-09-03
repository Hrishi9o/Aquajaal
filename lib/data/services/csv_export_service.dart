import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../../core/utils/currency_formatter.dart';

/// Service to export invoices to Excel-compatible UTF-8 CSV with Rupee symbol
class CsvExportService {
  CsvExportService._();

  /// Generates UTF-8 with BOM CSV content for invoices
  static String generateCsvContent(List<Invoice> invoices) {
    final List<List<dynamic>> rows = [];

    // Header Row matching exact specification
    rows.add([
      'Invoice #',
      'Date',
      'Time',
      'Customer',
      'Items',
      'Qty',
      'Unit Price',
      'Line Total',
      'Tax %',
      'Tax Amt',
      'Grand Total (₹)',
      'Payment Status',
    ]);

    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm');

    for (final inv in invoices) {
      if (inv.items.isEmpty) {
        rows.add([
          inv.invoiceNumber,
          dateFormat.format(inv.createdAt),
          timeFormat.format(inv.createdAt),
          inv.customerName ?? 'Counter Sale',
          '—',
          0,
          CurrencyFormatter.format(0),
          CurrencyFormatter.format(0),
          '${inv.taxRate.toStringAsFixed(1)}%',
          CurrencyFormatter.format(inv.taxAmount),
          CurrencyFormatter.format(inv.grandTotal),
          inv.paymentStatus,
        ]);
        continue;
      }

      // First item of invoice includes header data
      for (int i = 0; i < inv.items.length; i++) {
        final item = inv.items[i];
        final isFirst = i == 0;

        rows.add([
          isFirst ? inv.invoiceNumber : '',
          isFirst ? dateFormat.format(inv.createdAt) : '',
          isFirst ? timeFormat.format(inv.createdAt) : '',
          isFirst ? (inv.customerName ?? 'Counter Sale') : '',
          item.displayName,
          item.quantity,
          CurrencyFormatter.format(item.unitPrice),
          CurrencyFormatter.format(item.lineTotal),
          isFirst ? '${inv.taxRate.toStringAsFixed(1)}%' : '',
          isFirst ? CurrencyFormatter.format(inv.taxAmount) : '',
          isFirst ? CurrencyFormatter.format(inv.grandTotal) : '',
          isFirst ? inv.paymentStatus : '',
        ]);
      }
    }

    final csvConverter = const ListToCsvConverter();
    final csvString = csvConverter.convert(rows);

    // Prefix with UTF-8 BOM (\uFEFF) for Excel compatibility
    return '\uFEFF$csvString';
  }

  /// Exports invoices as CSV file and prompts save/share dialog
  static Future<bool> exportAndShareInvoices(List<Invoice> invoices) async {
    try {
      final csvContent = generateCsvContent(invoices);
      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'YE_Invoices_$timestamp.csv';

      return await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      return false;
    }
  }
}
