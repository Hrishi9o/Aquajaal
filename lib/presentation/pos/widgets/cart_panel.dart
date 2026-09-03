import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/pos_provider.dart';
import '../../../providers/stock_provider.dart';
import 'numpad_quantity_dialog.dart';
import 'checkout_confirmation_dialog.dart';

/// The checkout & cart sidebar panel
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
        borderRadius: isMobileDrawer ? null : BorderRadius.circular(20),
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (posProvider.cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => posProvider.clearCart(),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                    label: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 13)),
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
                    padding: const EdgeInsets.all(12),
                    itemCount: posProvider.cartItemList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = posProvider.cartItemList[index];
                      return _buildCartItemCard(context, posProvider, item);
                    },
                  ),
          ),

          // Customer Form & Checkout Summary
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
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select jars or packaged water bottles to start billing',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} each',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),

          // Quantity Stepper with Numpad Dialog tap
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => posProvider.decrementItem(item.cartKey),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => posProvider.incrementItem(item.cartKey),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Total Price
          SizedBox(
            width: 68,
            child: Text(
              CurrencyFormatter.format(item.lineTotal),
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, PosProvider posProvider, StockProvider stockProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Inputs (Expandable or compact)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: posProvider.setCustomerName,
                    decoration: InputDecoration(
                      hintText: 'Customer Name (Optional)',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: posProvider.setCustomerPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone No. (Optional)',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment Mode Selector
          Row(
            children: [
              const Text('Payment:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...['Cash', 'UPI', 'Credit'].map((mode) {
                final isSelected = posProvider.paymentMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(mode, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (val) {
                      if (val) posProvider.setPaymentMode(mode);
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),

          // Price Calculation Rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              Text(CurrencyFormatter.format(posProvider.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (posProvider.taxRate > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST (${posProvider.taxRate}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                Text(CurrencyFormatter.format(posProvider.taxAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const Divider(height: 12),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Rounded to Rupee', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                ],
              ),
              Text(
                CurrencyFormatter.format(posProvider.grandTotal),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Checkout Button
          ElevatedButton(
            onPressed: () => _handleCheckout(context, posProvider, stockProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Generate Invoice • ${CurrencyFormatter.format(posProvider.grandTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context, PosProvider posProvider, StockProvider stockProvider) async {
    // 1. Validate negative stock
    final deficitItems = posProvider.getItemsExceedingStock(stockProvider);
    if (deficitItems.isNotEmpty) {
      // Show confirmation dialog before allowing sale
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
