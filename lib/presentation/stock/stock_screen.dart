import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/stock_provider.dart';
import 'widgets/stock_intake_dialog.dart';
import 'widgets/stock_adjustment_dialog.dart';
import 'widgets/stock_audit_log_view.dart';

/// Stock management screen featuring live inventory status, low-stock warnings, and audit log
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockProvider = context.watch<StockProvider>();

    final lowStockCount = stockProvider.lowStockItemCount;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Management',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Monitor on-hand jars/cases, record factory inwards, and trace audit logs',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const StockIntakeDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_circle_rounded, size: 20),
                    label: const Text('+ Inward Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Low Stock Warning Banner if any item is low
              if (lowStockCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$lowStockCount product variant(s) are at or below the minimum low-stock threshold! Replenish stock soon.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning),
                        ),
                      ),
                      TextButton(
                        onPressed: stockProvider.toggleLowStockFilter,
                        child: Text(
                          stockProvider.filterLowStockOnly ? 'Show All SKUs' : 'Filter Low Stock',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab Bar
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('On-Hand Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (lowStockCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                            child: Text('$lowStockCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Movement Audit Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tab View
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInventoryList(context, stockProvider),
                    const StockAuditLogView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context, StockProvider stockProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final products = stockProvider.filteredProducts;

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: product.isLowStock
                  ? AppColors.warning
                  : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
              width: product.isLowStock ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: product.hasVariants ? AppColors.primaryContainer : AppColors.accentContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        product.hasVariants ? Icons.water_drop_rounded : Icons.local_drink_rounded,
                        color: product.hasVariants ? AppColors.primary : AppColors.accentDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${product.category} • HSN: ${product.hsnCode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    if (!product.hasVariants) ...[
                      // Quick buttons for standalone item
                      IconButton(
                        tooltip: 'Adjust Stock Count',
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StockAdjustmentDialog(product: product),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StockIntakeDialog(preselectedProduct: product),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('+ Inward', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // If standalone SKU: show simple stock count & threshold
                if (!product.hasVariants) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Current On-Hand: ', style: TextStyle(fontSize: 13)),
                            Text(
                              '${product.standaloneStock} cases',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: product.isOutOfStock
                                    ? AppColors.error
                                    : (product.isLowStock ? AppColors.warning : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        Text('Alert Threshold: ≤ ${product.lowStockThreshold} cases', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        Text('Price: ${CurrencyFormatter.format(product.standalonePrice ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ] else ...[
                  // If product has variants: show list of variants
                  const Text('Jar Quality Variants & Stock:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 8),
                  ...product.variants.map((variant) {
                    final isLow = variant.isLowStock;
                    final isOut = variant.isOutOfStock;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isLow
                              ? AppColors.warning
                              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              variant.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  '${variant.stock} jars',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isOut
                                        ? AppColors.error
                                        : (isLow ? AppColors.warning : AppColors.primary),
                                  ),
                                ),
                                if (isLow) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('LOW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text('₹${variant.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 14),
                          IconButton(
                            tooltip: 'Adjust Count',
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => StockAdjustmentDialog(product: product, variant: variant),
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => StockIntakeDialog(
                                  preselectedProduct: product,
                                  preselectedVariantId: variant.id,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('+ Inward', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
