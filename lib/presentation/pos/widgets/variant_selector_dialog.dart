import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';

/// Modal dialog for selecting a specific jar variant (Dim, Medium, Best) and quantity with dual-input method
class VariantSelectorDialog extends StatefulWidget {
  final Product product;
  final Function(ProductVariant variant, int quantity) onConfirm;

  const VariantSelectorDialog({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<VariantSelectorDialog> createState() => _VariantSelectorDialogState();
}

class _VariantSelectorDialogState extends State<VariantSelectorDialog> {
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQty) {
    if (newQty < 1) newQty = 1;
    setState(() {
      _quantity = newQty;
      _qtyController.text = '$newQty';
      _qtyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _qtyController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unitPrice = _selectedVariant?.price ?? 0.0;
    final lineTotal = unitPrice * _quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select Jar Quality Variant & Quantity',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Variant Options
              const Text(
                'Quality Variants',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ...widget.product.variants.map((variant) {
                final isSelected = _selectedVariant?.id == variant.id;
                final isLow = variant.isLowStock;
                final isOut = variant.isOutOfStock;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVariant = variant;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.primaryDark : AppColors.primaryContainer)
                          : (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected && !isDark ? AppColors.primaryDark : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Stock: ${variant.stock} jars',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isOut
                                          ? AppColors.error
                                          : (isLow ? AppColors.warning : AppColors.accentDark),
                                    ),
                                  ),
                                  if (isLow && !isOut)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withAlpha(38),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '⚠ Low Stock',
                                        style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(variant.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Quantity Input Section (Method 1: Direct Keyboard Entry + Method 2: Manual Steppers)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity (Type or Tap +/−)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Defaults to 1', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Minus Button
                        IconButton.filledTonal(
                          onPressed: _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(width: 10),

                        // Method 1: Direct Numeric Input Box (default 1)
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            onTap: () => _qtyController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _qtyController.text.length,
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                setState(() => _quantity = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Plus Button
                        IconButton.filled(
                          onPressed: () => _updateQuantity(_quantity + 1),
                          icon: const Icon(Icons.add_rounded),
                          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Bulk Presets (+10, +25, +50, +100)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [10, 25, 50, 100].map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('+$preset'),
                              onPressed: () => _updateQuantity(_quantity + preset),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Add to Cart Button with Reactive Total
              ElevatedButton(
                onPressed: _selectedVariant != null
                    ? () {
                        widget.onConfirm(_selectedVariant!, _quantity);
                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Add to Cart • ${CurrencyFormatter.format(lineTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
