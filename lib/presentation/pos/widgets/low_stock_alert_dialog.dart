import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LowStockAlertResult {
  final bool confirmed;
  final String? overrideReason;

  LowStockAlertResult({required this.confirmed, this.overrideReason});
}

/// Shows an immediate alert modal when attempting to add a low-stock item to cart
Future<LowStockAlertResult?> showLowStockAddAlert(
  BuildContext context, {
  required String itemName,
  required int currentStock,
  required int threshold,
  int quantityRequested = 1,
}) {
  final reasonController = TextEditingController();
  final isExceeding = quantityRequested > currentStock;
  final isOut = currentStock <= 0;
  final formKey = GlobalKey<FormState>();

  return showDialog<LowStockAlertResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isExceeding || isOut ? AppColors.error : AppColors.warning).withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExceeding || isOut ? Icons.warning_rounded : Icons.warning_amber_rounded,
                color: isExceeding || isOut ? AppColors.error : AppColors.warning,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isExceeding
                    ? 'Insufficient Stock Warning'
                    : (isOut ? 'Out of Stock Alert' : 'Low Stock Warning'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isExceeding || isOut ? AppColors.error : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: $itemName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isExceeding || isOut ? AppColors.error : AppColors.warning).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isExceeding || isOut ? AppColors.error : AppColors.warning).withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$itemName stock is $currentStock, threshold is $threshold. Current order is $quantityRequested.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isExceeding
                          ? '⚠ Warning: This order exceeds current physical inventory by ${quantityRequested - currentStock} units.'
                          : '• Low-stock alert threshold: $threshold units',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExceeding ? AppColors.error : AppColors.textSecondaryLight,
                        fontWeight: isExceeding ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add anyway?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (isExceeding) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Why override stock? (Required)',
                    hintText: 'e.g. Shipment arriving today / Manager approved',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Override reason is required for negative stock';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(LowStockAlertResult(confirmed: false)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExceeding || isOut ? AppColors.error : AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (isExceeding) {
                if (!formKey.currentState!.validate()) return;
              }
              Navigator.of(ctx).pop(
                LowStockAlertResult(
                  confirmed: true,
                  overrideReason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
