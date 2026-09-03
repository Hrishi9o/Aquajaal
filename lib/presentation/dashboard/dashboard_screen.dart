import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/pdf_sales_report_service.dart';
import '../../providers/sales_provider.dart';
import '../../providers/stock_provider.dart';
import '../invoice/invoice_detail_screen.dart';
import 'widgets/kpi_card.dart';
import 'widgets/sales_charts.dart';

/// Daily Sales Dashboard with KPI metrics, charts, top-selling items, export tools, and invoice drill-down
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final salesProvider = context.watch<SalesProvider>();
    final stockProvider = context.watch<StockProvider>();
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    final invoices = salesProvider.filteredInvoices;
    final lowStockItems = stockProvider.lowStockItems;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Persistent Low-Stock Alert Banner (if any items <= threshold)
            if (lowStockItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Alert: ${lowStockItems.length} item(s) need restocking',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lowStockItems.map((i) => '${i.displayName} (${i.currentStock} left)').join(', '),
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimaryLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Header with Period and Export Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Sales & Revenue Dashboard',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Period: ${salesProvider.dateRangeLabel}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                // Export Buttons
                Row(
                  children: [
                    // Export to CSV Button
                    OutlinedButton.icon(
                      onPressed: invoices.isEmpty
                          ? null
                          : () async {
                              final success = await CsvExportService.exportAndShareInvoices(invoices);
                              if (context.mounted && success) {
                                AppToast.success(context, '✓ CSV Invoices exported');
                              }
                            },
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export CSV'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Generate PDF Report Button
                    ElevatedButton.icon(
                      onPressed: invoices.isEmpty
                          ? null
                          : () async {
                              final settings = LocalDbService.instance.getSettings();
                              await PdfSalesReportService.exportAndPreviewReport(
                                settings: settings,
                                dateRangeLabel: salesProvider.dateRangeLabel,
                                totalRevenue: salesProvider.totalRevenue,
                                invoiceCount: salesProvider.totalInvoicesCount,
                                totalUnits: salesProvider.totalUnitsSold,
                                avgOrderValue: salesProvider.averageOrderValue,
                                dailyBreakdown: salesProvider.dailyBreakdown,
                                topProducts: salesProvider.topSellersByRevenue,
                              );
                            },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
                      label: const Text('Sales Report (PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date Filter Tabs + Custom Range Picker
            Row(
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    _filterChip(context, salesProvider, SalesDateFilter.today, 'Today'),
                    _filterChip(context, salesProvider, SalesDateFilter.thisWeek, 'This Week'),
                    _filterChip(context, salesProvider, SalesDateFilter.thisMonth, 'This Month'),
                    _filterChip(context, salesProvider, SalesDateFilter.allTime, 'All Time'),
                  ],
                ),
                const SizedBox(width: 10),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    salesProvider.selectedFilter == SalesDateFilter.custom
                        ? '${DateFormat('dd/MM').format(salesProvider.customStartDate)} – ${DateFormat('dd/MM').format(salesProvider.customEndDate)}'
                        : 'Custom Range',
                  ),
                  backgroundColor: salesProvider.selectedFilter == SalesDateFilter.custom
                      ? AppColors.primaryContainer
                      : null,
                  onPressed: () => _pickCustomDateRange(context, salesProvider),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 KPI Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 750;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 1.6 : 1.3,
                  children: [
                    KpiCard(
                      title: 'Total Revenue',
                      value: CurrencyFormatter.format(salesProvider.totalRevenue),
                      subtitle: 'Gross billings for period',
                      icon: Icons.currency_rupee_rounded,
                      accentColor: AppColors.primary,
                    ),
                    KpiCard(
                      title: 'Invoices Issued',
                      value: '${salesProvider.totalInvoicesCount}',
                      subtitle: 'Counter sales transactions',
                      icon: Icons.receipt_long_rounded,
                      accentColor: AppColors.accentDark,
                    ),
                    KpiCard(
                      title: 'Water Units Sold',
                      value: '${salesProvider.totalUnitsSold}',
                      subtitle: 'Jars & Case Packs',
                      icon: Icons.water_drop_rounded,
                      accentColor: AppColors.waterAqua,
                    ),
                    KpiCard(
                      title: 'Average Order Value',
                      value: CurrencyFormatter.format(salesProvider.averageOrderValue),
                      subtitle: 'Average bill size',
                      icon: Icons.trending_up_rounded,
                      accentColor: AppColors.accentDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Top 3 by Revenue & Top 3 by Quantity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTop3Card(
                    context,
                    title: 'Top 3 Products by Revenue',
                    items: salesProvider.top3ByRevenue,
                    isRevenue: true,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTop3Card(
                    context,
                    title: 'Top 3 Products by Units Sold',
                    items: salesProvider.top3ByQuantity,
                    isRevenue: false,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sales Revenue Bar Chart
            SalesRevenueBarChart(buckets: salesProvider.salesChartData),
            const SizedBox(height: 20),

            // Invoice Drill-down List
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Period Invoices Drill-Down (${invoices.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: ${CurrencyFormatter.format(salesProvider.totalRevenue)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (invoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No invoices found for this date filter')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final inv = invoices[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  inv.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: inv.paymentMode == 'UPI'
                                        ? Colors.green.shade50
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    inv.paymentMode,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: inv.paymentMode == 'UPI' ? Colors.green.shade800 : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${dateFormatter.format(inv.createdAt)} • ${inv.customerName ?? "Counter Customer"} • ${inv.totalUnits} items',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(inv.grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop3Card(
    BuildContext context, {
    required String title,
    required List<TopSellerItem> items,
    required bool isRevenue,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRevenue ? Icons.leaderboard_rounded : Icons.pie_chart_rounded,
                  size: 18,
                  color: isRevenue ? AppColors.primary : AppColors.accentDark,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No sales records in this period', style: TextStyle(fontSize: 12))),
              )
            else
              ...items.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? (isRevenue ? AppColors.primary : AppColors.accentDark)
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$rank',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity} units sold',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isRevenue
                            ? CurrencyFormatter.format(item.revenue)
                            : '${item.quantity} Units',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    SalesProvider provider,
    SalesDateFilter filter,
    String label,
  ) {
    final isSelected = provider.selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setFilter(filter);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context, SalesProvider provider) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: provider.customStartDate,
        end: provider.customEndDate,
      ),
    );

    if (picked != null) {
      provider.setCustomRange(picked.start, picked.end);
    }
  }
}
