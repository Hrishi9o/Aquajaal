import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/services/local_db_service.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../invoice/invoice_detail_screen.dart';

/// Modal dialog shown after successful checkout with immediate Print & Share actions
class InvoiceSuccessDialog extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onNewSale;

  const InvoiceSuccessDialog({
    super.key,
    required this.invoice,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = LocalDbService.instance.getSettings();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon with Ripple Ring
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentDark,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Bill Generated Successfully!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invoice: ${invoice.invoiceNumber}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.waterBlueTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.waterBlueLight),
              ),
              child: Column(
                children: [
                  _infoRow('Customer', invoice.customerName ?? 'Counter Cash Customer'),
                  const SizedBox(height: 6),
                  _infoRow('Payment Mode', invoice.paymentMode),
                  const SizedBox(height: 6),
                  _infoRow('Total Units', '${invoice.totalUnits} items'),
                  const Divider(height: 18, color: AppColors.waterBlueLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.format(invoice.grandTotal),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.amountInWords,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await PdfInvoiceService.shareInvoicePdf(invoice, settings);
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await PdfInvoiceService.printInvoice(invoice, settings);
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvoiceDetailScreen(invoice: invoice),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('View Full Tax Invoice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNewSale();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('New Sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Warning dialog displayed when cart items exceed current available stock
class NegativeStockWarningDialog extends StatelessWidget {
  final List<CartItem> deficitItems;
  final VoidCallback onProceedWithNegativeStock;

  const NegativeStockWarningDialog({
    super.key,
    required this.deficitItems,
    required this.onProceedWithNegativeStock,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
          SizedBox(width: 10),
          Text('Stock Warning'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following items will exceed current on-hand stock and result in negative inventory:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...deficitItems.map((item) {
              final deficit = item.quantity - item.availableStock;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(75)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            'Current Stock: ${item.availableStock} | Selling: ${item.quantity}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-$deficit deficit',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Do you want to proceed and allow negative stock for this sale?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Adjust Cart'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onProceedWithNegativeStock();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
          child: const Text('Allow Sale & Override'),
        ),
      ],
    );
  }
}
