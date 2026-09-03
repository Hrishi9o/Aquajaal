import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/sales_provider.dart';

/// Interactive custom Bar Chart displaying revenue breakdown over time with tooltips
class SalesRevenueBarChart extends StatelessWidget {
  final List<SalesTimeBucket> buckets;

  const SalesRevenueBarChart({
    super.key,
    required this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (buckets.isEmpty) {
      return const Center(child: Text('No sales data recorded for this period'));
    }

    final maxRevenue = buckets.fold(0.0, (max, b) => b.revenue > max ? b.revenue : max);
    final effectiveMax = maxRevenue > 0 ? maxRevenue : 1000.0;

    return Card(
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
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Revenue Trend',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Revenue (₹)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Chart Area
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-Axis labels
                  SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatCompact(effectiveMax),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                        Text(
                          CurrencyFormatter.formatCompact(effectiveMax * 0.5),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                        const Text(
                          '₹0',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Vertical divider
                  Container(
                    width: 1,
                    height: 190,
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                  const SizedBox(width: 8),

                  // Bars Area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: buckets.map((bucket) {
                        final isPeak = bucket.revenue == maxRevenue && maxRevenue > 0;
                        final heightRatio = maxRevenue > 0
                            ? (bucket.revenue / effectiveMax).clamp(0.04, 1.0)
                            : 0.04;
                        final barHeight = 170.0 * heightRatio;

                        return Tooltip(
                          message: '${bucket.label}\n${CurrencyFormatter.format(bucket.revenue)} (${bucket.count} bills)',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // The Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 28,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isPeak ? AppColors.accentDark : AppColors.primary,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  boxShadow: isPeak
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accentDark.withAlpha(80),
                                            blurRadius: 8,
                                            offset: const Offset(0, -2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // X-Axis Label
                              Text(
                                bucket.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                                  color: isPeak ? AppColors.accentDark : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ranked list of top-selling products by revenue and quantity
class TopSellersRankedCard extends StatelessWidget {
  final List<TopSellerItem> items;
  final bool sortByRevenue;

  const TopSellersRankedCard({
    super.key,
    required this.items,
    this.sortByRevenue = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final maxVal = items.isEmpty
        ? 1.0
        : (sortByRevenue ? items.first.revenue : items.first.quantity.toDouble());

    return Card(
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
                  sortByRevenue ? 'Top Items by Revenue' : 'Top Items by Units Sold',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${items.length} items',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No sales records in this date range')),
              )
            else
              ...items.take(5).toList().asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                final fraction = maxVal > 0
                    ? (sortByRevenue ? (item.revenue / maxVal) : (item.quantity / maxVal))
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: rank == 1
                                  ? AppColors.accentDark
                                  : (rank == 2 ? AppColors.primary : Colors.grey.shade400),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            sortByRevenue
                                ? CurrencyFormatter.format(item.revenue)
                                : '${item.quantity} Units',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? AppColors.cardDarkElevated : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rank == 1 ? AppColors.accentDark : AppColors.primary,
                          ),
                        ),
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
}
