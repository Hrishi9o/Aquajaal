import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/product.dart';
import '../../../providers/pos_provider.dart';
import 'variant_selector_dialog.dart';
import 'low_stock_alert_dialog.dart';

/// Interactive Product Card with dual-method quantity input (numeric keyboard + steppers)
class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _cardQty = 1;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _updateCardQty(int newQty) {
    if (newQty < 1) newQty = 1;
    setState(() {
      _cardQty = newQty;
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
    final posProvider = context.watch<PosProvider>();

    final totalStock = widget.product.totalStock;
    final isLow = widget.product.isLowStock;
    final isOut = totalStock <= 0;
    final inCartQty = posProvider.getQuantityInCart(widget.product.id);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCartQty > 0
              ? AppColors.primary
              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          width: inCartQty > 0 ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.product.hasVariants
            ? () => _showVariantDialog(context, posProvider)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category chip & Stock Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.waterBlueTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _buildStockBadge(isOut, isLow, totalStock),
                ],
              ),
              const SizedBox(height: 10),

              // Product Icon & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.product.hasVariants
                          ? AppColors.primaryContainer
                          : AppColors.accentContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.product.hasVariants
                          ? Icons.water_drop_rounded
                          : Icons.local_drink_rounded,
                      color: widget.product.hasVariants ? AppColors.primary : AppColors.accentDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.hasVariants
                              ? '${widget.product.variants.length} jar variants'
                              : 'HSN: ${widget.product.hsnCode}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (inCartQty > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✓ $inCartQty in cart',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],

              const Spacer(),

              // Price Label Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      widget.product.priceDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Action Area: Variant Dialog or Direct Dual-Input Quantity
              if (widget.product.hasVariants)
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _showVariantDialog(context, posProvider),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Choose Variant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              else
                _buildStandaloneDualQuantityInput(context, posProvider),
            ],
          ),
        ),
      ),
    );
  }

  /// Direct quantity input on card: [-] [ 1 ] [+] and [Add to Cart]
  Widget _buildStandaloneDualQuantityInput(BuildContext context, PosProvider posProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quantity Stepper Row
        SizedBox(
          height: 36,
          child: Row(
            children: [
              // Decrement Button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: _cardQty > 1 ? () => _updateCardQty(_cardQty - 1) : null,
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Direct Numeric Input Field
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        setState(() => _cardQty = parsed);
                      }
                    },
                    onSubmitted: (_) => _handleAddToCart(posProvider),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Increment Button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: () => _updateCardQty(_cardQty + 1),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Add to Cart Button (Comfortable 42px height)
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () => _handleAddToCart(posProvider),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
            label: Text(
              'Add to Cart ($_cardQty)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddToCart(PosProvider posProvider) async {
    final stock = widget.product.standaloneStock;
    final threshold = widget.product.lowStockThreshold;
    bool isOverride = false;

    if (_cardQty > stock || stock <= threshold) {
      final alertRes = await showLowStockAddAlert(
        context,
        itemName: widget.product.name,
        currentStock: stock,
        threshold: threshold,
        quantityRequested: _cardQty,
      );
      if (alertRes?.confirmed != true) return;
      if (alertRes?.overrideReason != null) isOverride = true;
    }

    posProvider.addToCart(widget.product, quantity: _cardQty);
    if (!mounted) return;

    if (isOverride) {
      AppToast.addedOverride(context);
    } else {
      AppToast.addedToCart(context);
    }
    _updateCardQty(1);
  }

  Widget _buildStockBadge(bool isOut, bool isLow, int stock) {
    if (isOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error),
        ),
      );
    }

    if (isLow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '⚠ $stock left',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(38),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Stock: $stock',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentDark),
      ),
    );
  }

  void _showVariantDialog(BuildContext context, PosProvider posProvider) {
    showDialog(
      context: context,
      builder: (ctx) => VariantSelectorDialog(
        product: widget.product,
        onConfirm: (variant, quantity) async {
          bool isOverride = false;
          if (quantity > variant.stock || variant.stock <= variant.lowStockThreshold) {
            final alertRes = await showLowStockAddAlert(
              context,
              itemName: '${widget.product.name} (${variant.name})',
              currentStock: variant.stock,
              threshold: variant.lowStockThreshold,
              quantityRequested: quantity,
            );
            if (alertRes?.confirmed != true) return;
            if (alertRes?.overrideReason != null) isOverride = true;
          }

          posProvider.addToCart(widget.product, variant: variant, quantity: quantity);
          if (context.mounted) {
            if (isOverride) {
              AppToast.addedOverride(context);
            } else {
              AppToast.addedToCart(context);
            }
          }
        },
      ),
    );
  }
}
