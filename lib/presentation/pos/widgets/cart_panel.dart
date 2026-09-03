import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/pos_provider.dart';
import '../../../providers/stock_provider.dart';
import 'numpad_quantity_dialog.dart';
import 'checkout_confirmation_dialog.dart';

/// The checkout & cart sidebar / mobile bottom-sheet panel
class CartPanel extends StatelessWidget {
  final bool isMobileDrawer;

  const CartPanel({
    super.key,
    this.isMobileDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posProvider = context.watch<PosProvider>();
    final stockProvider = context.read<StockProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: isMobileDrawer
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
        border: isMobileDrawer
            ? null
            : Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle for mobile bottom sheet
          if (isMobileDrawer)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Running Cart',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${posProvider.totalItemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (posProvider.cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => posProvider.clearCart(),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                    label: const Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: posProvider.cartItems.isEmpty
                ? _buildEmptyCart(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: posProvider.cartItemList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = posProvider.cartItemList[index];
                      return _buildCartItemCard(context, posProvider, item);
                    },
                  ),
          ),

          // Checkout pinned at bottom
          if (posProvider.cartItems.isNotEmpty)
            _buildCheckoutSection(context, posProvider, stockProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_shopping_cart_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text('Your cart is empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Tap any product to add it to the billing cart',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, PosProvider posProvider, dynamic item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product name + remove button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => posProvider.removeItem(item.cartKey),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 15, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Qty stepper + line total
          Row(
            children: [
              // Unit price label
              Text(
                '₹${item.unitPrice.toStringAsFixed(0)} ea',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 10),

              // Qty stepper
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(70)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => posProvider.decrementItem(item.cartKey),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Icon(Icons.remove_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => NumpadQuantityDialog(
                            itemName: item.displayName,
                            initialQuantity: item.quantity,
                            onConfirm: (qty) => posProvider.updateQuantity(item.cartKey, qty),
                          ),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => posProvider.incrementItem(item.cartKey),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Line total
              Text(
                CurrencyFormatter.format(item.lineTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, PosProvider posProvider, StockProvider stockProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: isMobileDrawer
            ? BorderRadius.zero
            : const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
        border: Border(
          top: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Customer name
          TextField(
            onChanged: posProvider.setCustomerName,
            decoration: InputDecoration(
              hintText: 'Customer Name (Optional)',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Customer phone
          TextField(
            onChanged: posProvider.setCustomerPhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone Number (Optional)',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Payment mode
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Payment:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ...['Cash', 'UPI', 'Credit'].map((mode) {
                final isSelected = posProvider.paymentMode == mode;
                return ChoiceChip(
                  label: Text(mode, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onSelected: (val) {
                    if (val) posProvider.setPaymentMode(mode);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Subtotal row
          _amountRow('Subtotal', CurrencyFormatter.format(posProvider.subtotal)),
          if (posProvider.taxRate > 0) ...[
            const SizedBox(height: 4),
            _amountRow('GST (${posProvider.taxRate}%)', CurrencyFormatter.format(posProvider.taxAmount)),
          ],
          const SizedBox(height: 10),

          // Grand Total — highlighted container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Rounded to Rupee', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(posProvider.grandTotal),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Generate Bill button
          ElevatedButton.icon(
            onPressed: () => _handleCheckout(context, posProvider, stockProvider),
            icon: const Icon(Icons.receipt_rounded, size: 20),
            label: Text(
              'Generate Bill  •  ${CurrencyFormatter.format(posProvider.grandTotal)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleCheckout(BuildContext context, PosProvider posProvider, StockProvider stockProvider) async {
    final deficitItems = posProvider.getItemsExceedingStock(stockProvider);
    if (deficitItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => NegativeStockWarningDialog(
          deficitItems: deficitItems,
          onProceedWithNegativeStock: () => _executeCheckout(context, posProvider, stockProvider),
        ),
      );
      return;
    }
    _executeCheckout(context, posProvider, stockProvider);
  }

  void _executeCheckout(BuildContext context, PosProvider posProvider, StockProvider stockProvider) async {
    try {
      final invoice = await posProvider.checkout(stockProvider);
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => InvoiceSuccessDialog(
            invoice: invoice,
            onNewSale: () {},
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Error generating invoice: $e');
      }
    }
  }
}
