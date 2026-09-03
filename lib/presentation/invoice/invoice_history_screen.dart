import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/pdf_invoice_service.dart';
import '../../providers/sales_provider.dart';
import 'invoice_detail_screen.dart';

/// Screen listing historical invoices with search, filters, and reprint capabilities
class InvoiceHistoryScreen extends StatelessWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final salesProvider = context.watch<SalesProvider>();
    final settings = LocalDbService.instance.getSettings();
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final isMobile = MediaQuery.of(context).size.width < 650;

    final invoices = salesProvider.filteredInvoices;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Search & Date Filters
            if (isMobile) ...[
              TextField(
                onChanged: salesProvider.setInvoiceSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by Invoice #, Customer, or Phone...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Period: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SalesDateFilter>(
                          value: salesProvider.selectedFilter,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                          onChanged: (val) {
                            if (val != null) salesProvider.setFilter(val);
                          },
                          items: const [
                            DropdownMenuItem(value: SalesDateFilter.today, child: Text('Today', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: SalesDateFilter.yesterday, child: Text('Yesterday', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: SalesDateFilter.last7Days, child: Text('Last 7 Days', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: SalesDateFilter.thisMonth, child: Text('This Month', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: SalesDateFilter.allTime, child: Text('All Time', style: TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: salesProvider.setInvoiceSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search by Invoice # (e.g. YE-2026-0001), Customer, or Phone...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        fillColor: isDark ? AppColors.cardDark : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SalesDateFilter>(
                        value: salesProvider.selectedFilter,
                        icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                        onChanged: (val) {
                          if (val != null) salesProvider.setFilter(val);
                        },
                        items: const [
                          DropdownMenuItem(value: SalesDateFilter.today, child: Text('Today')),
                          DropdownMenuItem(value: SalesDateFilter.yesterday, child: Text('Yesterday')),
                          DropdownMenuItem(value: SalesDateFilter.last7Days, child: Text('Last 7 Days')),
                          DropdownMenuItem(value: SalesDateFilter.thisMonth, child: Text('This Month')),
                          DropdownMenuItem(value: SalesDateFilter.allTime, child: Text('All Time')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Metrics Strip
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatPill('Total Bills', '${invoices.length}', Icons.receipt_rounded),
                _buildStatPill(
                  'Total Volume',
                  '${invoices.fold(0, (sum, i) => sum + i.totalUnits)} Units',
                  Icons.water_drop_rounded,
                ),
                _buildStatPill(
                  'Period Revenue',
                  CurrencyFormatter.format(invoices.fold(0.0, (sum, i) => sum + i.grandTotal)),
                  Icons.currency_rupee_rounded,
                  isHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Invoices List
            Expanded(
              child: invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No invoices found for this period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Generated bills will appear here with instant reprint & PDF export', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        final itemsSummary = invoice.items.map((i) => '${i.displayName} × ${i.quantity}').join(', ');

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(invoice: invoice),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Invoice #, Payment mode badge, and Total
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            invoice.invoiceNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                                            ),
                                            child: Text(
                                              invoice.paymentMode,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        CurrencyFormatter.format(invoice.grandTotal),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Middle row: Customer & Date
                                  Text(
                                    '${invoice.customerName ?? "Counter Customer"}  •  ${dateFormatter.format(invoice.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // Bottom row: items preview & action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          itemsSummary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Share / PDF',
                                        icon: const Icon(Icons.share_rounded, size: 18),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => PdfInvoiceService.shareInvoicePdf(invoice, settings),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Print Invoice',
                                        icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.accentDark),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => PdfInvoiceService.printInvoice(invoice, settings),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String val, IconData icon, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isHighlight ? Colors.white : AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: isHighlight ? Colors.white70 : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
