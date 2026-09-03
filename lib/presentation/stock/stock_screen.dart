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
    final isMobile = MediaQuery.of(context).size.width < 650;

    final lowStockCount = stockProvider.lowStockItemCount;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Management',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Monitor on-hand jars/cases, record factory inwards, and trace audit logs',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const StockIntakeDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_circle_rounded, size: 18),
                    label: const Text('+ Inward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Low Stock Warning Banner if any item is low
              if (lowStockCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$lowStockCount item(s) below low-stock threshold!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                      TextButton(
                        onPressed: stockProvider.toggleLowStockFilter,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: Text(
                          stockProvider.filterLowStockOnly ? 'Show All' : 'Filter Low',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                        const Icon(Icons.inventory_2_outlined, size: 16),
                        const SizedBox(width: 6),
                        const Text('On-Hand Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (lowStockCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                            child: Text('$lowStockCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Movement Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tab View
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInventoryList(context, stockProvider, isMobile),
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

  Widget _buildInventoryList(BuildContext context, StockProvider stockProvider, bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final products = stockProvider.filteredProducts;

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: product.isLowStock
                  ? AppColors.warning
                  : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
              width: product.isLowStock ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: product.hasVariants ? AppColors.primaryContainer : AppColors.accentContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        product.hasVariants ? Icons.water_drop_rounded : Icons.local_drink_rounded,
                        color: product.hasVariants ? AppColors.primary : AppColors.accentDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${product.category} • HSN: ${product.hsnCode}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    if (!product.hasVariants) ...[
                      IconButton(
                        tooltip: 'Adjust Stock',
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StockAdjustmentDialog(product: product),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StockIntakeDialog(preselectedProduct: product),
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
                  ],
                ),

                const SizedBox(height: 10),

                // If standalone SKU: show simple stock count & threshold
                if (!product.hasVariants) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Current On-Hand: ', style: TextStyle(fontSize: 12)),
                            Text(
                              '${product.standaloneStock} cases',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: product.isOutOfStock
                                    ? AppColors.error
                                    : (product.isLowStock ? AppColors.warning : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Alert: ≤ ${product.lowStockThreshold} cases',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              'Price: ${CurrencyFormatter.format(product.standalonePrice ?? 0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // If product has variants: show list of variants
                  const Text('Variants & Stock:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  ...product.variants.map((variant) {
                    final isLow = variant.isLowStock;
                    final isOut = variant.isOutOfStock;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLow
                              ? AppColors.warning
                              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      variant.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '₹${variant.price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${variant.stock} jars',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isOut
                                                ? AppColors.error
                                                : (isLow ? AppColors.warning : AppColors.primary),
                                          ),
                                        ),
                                        if (isLow) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('LOW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => StockAdjustmentDialog(product: product, variant: variant),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.tune_rounded, size: 14),
                                                SizedBox(width: 4),
                                                Text('Adjust', style: TextStyle(fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => StockIntakeDialog(
                                                preselectedProduct: product,
                                                preselectedVariantId: variant.id,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentDark,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                                SizedBox(width: 2),
                                                Text('+ Inward', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
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
