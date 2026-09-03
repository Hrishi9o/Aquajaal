import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/stock_provider.dart';

/// Traceable chronological audit log of every stock intake, invoice sale, and adjustment
class StockAuditLogView extends StatefulWidget {
  const StockAuditLogView({super.key});

  @override
  State<StockAuditLogView> createState() => _StockAuditLogViewState();
}

class _StockAuditLogViewState extends State<StockAuditLogView> {
  String _typeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockProvider = context.watch<StockProvider>();
    final dateFormatter = DateFormat('dd-MMM-yyyy hh:mm a');

    final movements = stockProvider.allMovements.where((m) {
      if (_typeFilter == 'All') return true;
      if (_typeFilter == 'Intake') return m.type == 'intake';
      if (_typeFilter == 'Sale') return m.type == 'sale';
      if (_typeFilter == 'Adjustment') return m.type == 'adjustment';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: ['All', 'Intake', 'Sale', 'Adjustment'].map((type) {
                final isSelected = _typeFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _typeFilter = type);
                    },
                  ),
                );
              }).toList(),
            ),
            Text(
              '${movements.length} log records',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Timeline List
        Expanded(
          child: movements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No stock movements logged yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Every bill generated or inward stock added will be recorded here', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Movement Icon
                            _buildTypeIcon(m.type),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        m.itemDisplayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildTypeBadge(m.type),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${dateFormatter.format(m.timestamp)} • Ref: ${m.reference ?? "Direct"}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                  ),
                                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Note: ${m.notes}',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Delta & Stock Balance
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.quantityDelta > 0 ? '+${m.quantityDelta}' : '${m.quantityDelta}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: m.quantityDelta > 0 ? AppColors.accentDark : AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bal: ${m.previousStock} → ${m.newStock}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(String type) {
    if (type == 'intake') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.accentContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_downward_rounded, color: AppColors.accentDark, size: 20),
      );
    } else if (type == 'sale') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 20),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.tune_rounded, color: AppColors.warning, size: 20),
      );
    }
  }

  Widget _buildTypeBadge(String type) {
    Color bg;
    Color fg;
    String label;

    if (type == 'intake') {
      bg = AppColors.accent.withAlpha(38);
      fg = AppColors.accentDark;
      label = 'INWARD INTAKE';
    } else if (type == 'sale') {
      bg = AppColors.primaryContainer;
      fg = AppColors.primaryDark;
      label = 'BILL SALE';
    } else {
      bg = AppColors.warning.withAlpha(38);
      fg = AppColors.warning;
      label = 'ADJUSTMENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
