import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/product.dart';
import '../../../providers/stock_provider.dart';
import '../../../core/widgets/responsive_text.dart';

/// Modal dialog for recording incoming factory/supplier stock shipments
class StockIntakeDialog extends StatefulWidget {
  final Product? preselectedProduct;
  final String? preselectedVariantId;

  const StockIntakeDialog({
    super.key,
    this.preselectedProduct,
    this.preselectedVariantId,
  });

  @override
  State<StockIntakeDialog> createState() => _StockIntakeDialogState();
}

class _StockIntakeDialogState extends State<StockIntakeDialog> {
  Product? _selectedProduct;
  ProductVariant? _selectedVariant;
  final _qtyController = TextEditingController();
  final _referenceController = TextEditingController(text: 'Delivery Note #');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final stockProvider = context.read<StockProvider>();
    _selectedProduct = widget.preselectedProduct ??
        (stockProvider.allProducts.isNotEmpty ? stockProvider.allProducts.first : null);

    if (_selectedProduct != null && _selectedProduct!.hasVariants && _selectedProduct!.variants.isNotEmpty) {
      if (widget.preselectedVariantId != null) {
        _selectedVariant = _selectedProduct!.variants.firstWhere(
          (v) => v.id == widget.preselectedVariantId,
          orElse: () => _selectedProduct!.variants.first,
        );
      } else {
        _selectedVariant = _selectedProduct!.variants.first;
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockProvider = context.watch<StockProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialogWidth = constraints.maxWidth * 0.9;
          return Container(
            width: dialogWidth < 400 ? dialogWidth : 400, // cap width for large screens
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.accentDark, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record Inward Stock', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      const Text('Add received jars/bottles from plant to inventory', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 20),

            // Product Dropdown
            const Text('Select Water Product:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              items: stockProvider.allProducts.map((p) {
                return DropdownMenuItem(value: p, child: ResponsiveText(p.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProduct = val;
                  if (val != null && val.hasVariants && val.variants.isNotEmpty) {
                    _selectedVariant = val.variants.first;
                  } else {
                    _selectedVariant = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            // Variant Selector (if product has variants)
            if (_selectedProduct != null && _selectedProduct!.hasVariants) ...[
              const Text('Select Jar Variant:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ProductVariant>(
                value: _selectedVariant,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                items: _selectedProduct!.variants.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text('${v.name} (Current: ${v.stock} jars)'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVariant = val),
              ),
              const SizedBox(height: 14),
            ],

            // Quantity Received Field
            const Text('Quantity Received (Units):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 50, 100, 200',
                prefixIcon: Icon(Icons.add_circle_outline_rounded, color: AppColors.accentDark),
              ),
            ),
            const SizedBox(height: 14),

            // Supplier / Delivery Note Reference
            const Text('Supplier / Delivery Note Reference:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                hintText: 'e.g. Batch #410 or Plant Inward #29',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // Optional Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Optional notes (e.g. morning delivery, driver name)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
                if (qty <= 0 || _selectedProduct == null) {
                  AppToast.error(context, 'Please enter a valid quantity');
                  return;
                }

                await stockProvider.recordStockIntake(
                  productId: _selectedProduct!.id,
                  variantId: _selectedVariant?.id,
                  quantityReceived: qty,
                  supplierReference: _referenceController.text.trim(),
                  notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppToast.success(context, '✓ Inward stock recorded (+$qty units)');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add to Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
