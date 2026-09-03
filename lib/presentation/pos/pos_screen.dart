import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../providers/pos_provider.dart';
import '../../providers/stock_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/cart_panel.dart';

/// Point of Sale (POS) Billing Screen
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final stockProvider = context.watch<StockProvider>();
    final posProvider = context.watch<PosProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Section: Catalog Grid & Search
          Expanded(
            flex: isMobile ? 1 : 6,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Aquajaal Product Banner
                  _buildBrandHeader(context),
                  const SizedBox(height: 14),

                  // Search Bar & Category Filters
                  _buildSearchAndFilters(context, stockProvider),
                  const SizedBox(height: 14),

                  // Catalog Grid
                  Expanded(
                    child: stockProvider.filteredPosProducts.isEmpty
                        ? _buildEmptyState(context)
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : (ResponsiveLayout.isTablet(context) ? 2 : 3),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: isMobile ? 0.76 : 0.88,
                            ),
                            itemCount: stockProvider.filteredPosProducts.length,
                            itemBuilder: (context, index) {
                              final product = stockProvider.filteredPosProducts[index];
                              return ProductCard(product: product);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Right Section: Cart Panel (Only for Tablet & Desktop)
          if (!isMobile)
            Expanded(
              flex: ResponsiveLayout.isTablet(context) ? 4 : 3,
              child: const Padding(
                padding: EdgeInsets.only(top: 20, right: 20, bottom: 20),
                child: CartPanel(),
              ),
            ),
        ],
      ),

      // Mobile Bottom Floating Cart Bar
      bottomNavigationBar: isMobile && posProvider.cartItems.isNotEmpty
          ? _buildMobileCartBar(context, posProvider)
          : null,
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryLight.withAlpha(76) : AppColors.waterBlueLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              AppStrings.logoAquajaal,
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Aquajaal™ Catalog',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Added Minerals',
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap any item or variant to add to the cashier billing cart',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, StockProvider stockProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: stockProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search Jars or Bottles (e.g. 20L, 1000ml)...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: stockProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => stockProvider.setSearchQuery(''),
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              fillColor: isDark ? AppColors.cardDark : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Category Filter Chips
        ...['All', '20L Jars', 'Packaged Bottles'].map((cat) {
          final isSelected = stockProvider.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) stockProvider.setCategory(cat);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No water products found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Try clearing your search query or filters', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMobileCartBar(BuildContext context, PosProvider posProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${posProvider.totalItemCount} Items In Cart',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  CurrencyFormatter.format(posProvider.grandTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => const FractionallySizedBox(
                    heightFactor: 0.85,
                    child: CartPanel(isMobileDrawer: true),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text('View Cart & Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
