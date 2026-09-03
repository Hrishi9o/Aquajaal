import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive_layout.dart';
import '../../providers/pos_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/theme_provider.dart';
import '../pos/pos_screen.dart';
import '../products/product_management_screen.dart';
import '../stock/stock_screen.dart';
import '../invoice/invoice_history_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/cloud_sync_indicator.dart';

/// Main responsive shell adapting between Mobile BottomNav and Desktop SideRail
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PosScreen(),
    ProductManagementScreen(),
    StockScreen(),
    InvoiceHistoryScreen(),
    DashboardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    final posProvider = context.watch<PosProvider>();
    final stockProvider = context.watch<StockProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final cartCount = posProvider.totalItemCount;
    final lowStockCount = stockProvider.lowStockItemCount;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 12,
          title: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  AppStrings.logoYashodhar,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const Icon(Icons.water, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.distributorName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Text(
                    'Aquajaal Water Distributor',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            const CloudSyncIndicator(compact: true),
            IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: themeProvider.toggleTheme,
              tooltip: 'Toggle Theme',
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.point_of_sale_rounded),
              ),
              label: 'Billing',
            ),
            const NavigationDestination(
              icon: Icon(Icons.category_rounded),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: lowStockCount > 0,
                label: Text('$lowStockCount'),
                backgroundColor: AppColors.warning,
                child: const Icon(Icons.inventory_2_rounded),
              ),
              label: 'Stock',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Invoices',
            ),
            const NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Analytics',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      );
    }

    // Tablet / Desktop Layout with Side Rail
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation Rail
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distributor Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Image.asset(
                          AppStrings.logoYashodhar,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.water_drop_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.distributorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Text(
                              'Packaged Water Distributor',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentDark),
                            ),
                            const Text(
                              'Shirva, Karnataka (29)',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Navigation Items
                _buildNavItem(0, 'POS Billing', Icons.point_of_sale_rounded, badgeCount: cartCount),
                _buildNavItem(1, 'Product Catalog', Icons.category_rounded),
                _buildNavItem(2, 'Stock Management', Icons.inventory_2_rounded, badgeCount: lowStockCount, isWarningBadge: true),
                _buildNavItem(3, 'Invoice History', Icons.receipt_long_rounded),
                _buildNavItem(4, 'Sales Analytics', Icons.dashboard_rounded),
                _buildNavItem(5, 'Store Settings', Icons.settings_rounded),

                const Spacer(),

                // Bottom Offline / Theme strip
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Cloud Sync Indicator
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDarkElevated : AppColors.waterBlueTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: CloudSyncIndicator()),
                      ),

                      // Offline Ready indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDarkElevated : AppColors.waterBlueTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.accentDark),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '100% Offline Ready',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Theme Mode Switcher Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 18,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDark ? 'Dark Theme' : 'Light Theme',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Switch(
                            value: themeProvider.isDarkMode,
                            activeColor: AppColors.accentDark,
                            onChanged: (_) => themeProvider.toggleTheme(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon, {
    int badgeCount = 0,
    bool isWarningBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.cardDarkElevated : AppColors.primaryContainer)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: isDark ? AppColors.primaryLight.withAlpha(50) : AppColors.waterBlueLight)
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textPrimaryLight),
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isWarningBadge ? AppColors.warning : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }
}
