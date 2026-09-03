import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/product.dart';
import '../../../providers/stock_provider.dart';

/// Modal dialog for manually adjusting on-hand inventory count
class StockAdjustmentDialog extends StatefulWidget {
  final Product product;
  final ProductVariant? variant;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
    this.variant,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  late final TextEditingController _countController;
  final _reasonController = TextEditingController(text: 'Physical audit / count reconciliation');

  @override
  void initState() {
    super.initState();
    final currentStock = widget.variant?.stock ?? widget.product.standaloneStock;
    _countController = TextEditingController(text: currentStock.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.read<StockProvider>();

    final title = widget.variant != null
        ? '${widget.product.name} (${widget.variant!.name})'
        : widget.product.name;

    final currentStock = widget.variant?.stock ?? widget.product.standaloneStock;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // responsive width up to 90% of screen
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adjust Stock Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.waterBlueTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Recorded Stock:'),
                  Text('$currentStock units', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('New Correct Physical Count:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter counted on-hand stock',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Reason / Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. 2 Jars damaged / leaking, or counted inventory',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                final newCount = int.tryParse(_countController.text.trim());
                if (newCount == null || newCount < 0) {
                  AppToast.error(context, 'Please enter a valid stock count');
                  return;
                }

                await stockProvider.adjustStock(
                  productId: widget.product.id,
                  variantId: widget.variant?.id,
                  updatedStock: newCount,
                  reason: _reasonController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppToast.success(context, '✓ Stock updated to $newCount units');
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Stock Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
