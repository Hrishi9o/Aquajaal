import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/stock_provider.dart';
import 'widgets/product_edit_dialog.dart';

/// Dedicated screen for creating, editing, archiving, and managing products and variants
class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Management',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manage products, quality variants, pricing, and active status.',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddDialog(context, stockProvider),
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // Search and Status Filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      onChanged: (val) => stockProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search products by name or SKU...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppColors.cardDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Filter Chips: Active vs Archived
                  FilterChip(
                    label: Text('Active (${stockProvider.activeProducts.length})'),
                    selected: !stockProvider.showArchivedOnly,
                    onSelected: (val) => stockProvider.setShowArchivedOnly(false),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Archived (${stockProvider.archivedProducts.length})'),
                    selected: stockProvider.showArchivedOnly,
                    onSelected: (val) => stockProvider.setShowArchivedOnly(true),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            // Products List / Grid
            Expanded(
              child: stockProvider.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            stockProvider.showArchivedOnly
                                ? 'No archived products'
                                : 'No products found matching search',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: stockProvider.filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = stockProvider.filteredProducts[index];
                        return _buildProductCard(context, product, stockProvider, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    StockProvider stockProvider,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: product.isActive
              ? (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              : Colors.grey.shade400,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name, Category, and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: product.hasVariants
                        ? AppColors.primaryContainer
                        : AppColors.accentLight.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    product.hasVariants ? Icons.layers_rounded : Icons.local_drink_rounded,
                    color: product.hasVariants ? AppColors.primary : AppColors.accentDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? AppColors.accentLight.withAlpha(40)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.isActive ? 'Active' : 'Archived',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: product.isActive ? AppColors.accentDark : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Category: ${product.category}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'HSN: ${product.hsnCode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          if (product.sku != null && product.sku!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Variant list or Standalone details
            if (product.hasVariants) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: product.variants.map((v) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: v.isOutOfStock
                            ? AppColors.error
                            : (v.isLowStock ? AppColors.warning : Colors.transparent),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${v.name}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Text(
                          CurrencyFormatter.format(v.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${v.stock} in stock)',
                          style: TextStyle(
                            fontSize: 11,
                            color: v.isOutOfStock
                                ? AppColors.error
                                : (v.isLowStock ? AppColors.warning : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Row(
                children: [
                  Text(
                    'Price: ${CurrencyFormatter.format(product.standalonePrice ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Stock: ${product.standaloneStock} units',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: product.isOutOfStock
                          ? AppColors.error
                          : (product.isLowStock ? AppColors.warning : AppColors.textSecondaryLight),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Low threshold: ${product.lowStockThreshold}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Button
                OutlinedButton.icon(
                  onPressed: () => _openEditDialog(context, stockProvider, product),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // Archive / Reactivate Toggle
                OutlinedButton.icon(
                  onPressed: () => _toggleArchive(context, stockProvider, product),
                  icon: Icon(
                    product.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                    size: 16,
                  ),
                  label: Text(product.isActive ? 'Archive' : 'Restore'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // Permanent Delete (only if no sales history)
                if (stockProvider.canDeleteProduct(product.id))
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    tooltip: 'Delete Product (Zero sales history)',
                    onPressed: () => _confirmDelete(context, stockProvider, product),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddDialog(BuildContext context, StockProvider stockProvider) {
    showDialog(
      context: context,
      builder: (_) => ProductEditDialog(
        onSave: (newProduct) async {
          await stockProvider.addProduct(newProduct);
          if (context.mounted) {
            AppToast.success(context, '✓ Product added to catalog');
          }
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, StockProvider stockProvider, Product product) {
    showDialog(
      context: context,
      builder: (_) => ProductEditDialog(
        productToEdit: product,
        onSave: (updated) async {
          await stockProvider.updateProduct(updated);
          if (context.mounted) {
            AppToast.success(context, '✓ Product updated');
          }
        },
      ),
    );
  }

  void _toggleArchive(BuildContext context, StockProvider stockProvider, Product product) async {
    final willArchive = product.isActive;
    await stockProvider.toggleProductActive(product.id, !willArchive);
    if (context.mounted) {
      AppToast.success(
        context,
        willArchive ? '✓ Product archived' : '✓ Product restored to POS',
      );
    }
  }

  void _confirmDelete(BuildContext context, StockProvider stockProvider, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product Permanently?'),
        content: Text('Are you sure you want to delete "${product.name}"? This item has zero sales history.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await stockProvider.deleteProductPermanently(product.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
