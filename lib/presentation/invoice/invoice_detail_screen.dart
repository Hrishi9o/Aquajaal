import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/invoice.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/pdf_invoice_service.dart';

/// Full screen GST Tax Invoice viewer and print station
class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = LocalDbService.instance.getSettings();
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice ${invoice.invoiceNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Export / Share PDF',
            onPressed: () => PdfInvoiceService.shareInvoicePdf(invoice, settings),
            icon: const Icon(Icons.share_rounded),
          ),
          IconButton(
            tooltip: 'Print Tax Invoice',
            onPressed: () => PdfInvoiceService.printInvoice(invoice, settings),
            icon: const Icon(Icons.print_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── LETTERHEAD ──────────────────────────────────────────
                  if (isMobile)
                    _buildMobileLetterhead(context, settings, dateFormatter, isDark)
                  else
                    _buildDesktopLetterhead(context, settings, dateFormatter, isDark),

                  const SizedBox(height: 16),
                  const Divider(thickness: 1.5, color: AppColors.primary),
                  const SizedBox(height: 12),

                  // ── BILLED TO ───────────────────────────────────────────
                  isMobile
                      ? _buildMobileBilledTo(isDark)
                      : _buildDesktopBilledTo(isDark),

                  const SizedBox(height: 20),

                  // ── ITEMS ───────────────────────────────────────────────
                  isMobile
                      ? _buildMobileItemCards(context, isDark)
                      : _buildDesktopTable(isDark),

                  const SizedBox(height: 20),

                  // ── TOTALS SUMMARY ──────────────────────────────────────
                  isMobile
                      ? _buildMobileSummary(context, isDark)
                      : _buildDesktopSummary(context, isDark),

                  const SizedBox(height: 24),

                  // ── FOOTER & SIGNATORY ──────────────────────────────────
                  if (!isMobile) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.invoiceFooterNote,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            Text('Total Items: ${invoice.totalUnits} Units',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('For ${settings.distributorName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 48),
                            Container(width: 160, height: 1, color: Colors.grey),
                            const SizedBox(height: 4),
                            const Text('Authorized Signatory',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Text('Total Items: ${invoice.totalUnits} Units',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(AppStrings.invoiceFooterNote,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                  ],

                  // ── ACTION BUTTONS ──────────────────────────────────────
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => PdfInvoiceService.shareInvoicePdf(invoice, settings),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export / Share PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => PdfInvoiceService.printInvoice(invoice, settings),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Print Tax Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LETTERHEAD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobileLetterhead(
      BuildContext context, dynamic settings, DateFormat dateFormatter, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + Company name row
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(
                AppStrings.logoYashodhar,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.water, color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.distributorName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(AppStrings.distributorTagline,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Address block
        Text(settings.distributorAddress, style: const TextStyle(fontSize: 12)),
        Text(settings.distributorCity, style: const TextStyle(fontSize: 12)),
        Text(
          'State: ${settings.stateName} (${settings.stateCode})  •  Ph: ${settings.phone}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        // Invoice badge row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                AppStrings.taxInvoiceTitle,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(invoice.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      textAlign: TextAlign.right),
                  Text(
                    dateFormatter.format(invoice.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.right,
                  ),
                  Text('Mode: ${invoice.paymentMode}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLetterhead(
      BuildContext context, dynamic settings, DateFormat dateFormatter, bool isDark) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Image.asset(
            AppStrings.logoYashodhar,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.water, color: AppColors.primary, size: 36),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.distributorName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(AppStrings.distributorTagline,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text(settings.distributorAddress, style: const TextStyle(fontSize: 12)),
              Text(settings.distributorCity, style: const TextStyle(fontSize: 12)),
              Text(
                'State: ${settings.stateName} (Code: ${settings.stateCode}) | Phone: ${settings.phone}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                AppStrings.taxInvoiceTitle,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Text(invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(dateFormatter.format(invoice.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            Text('Mode: ${invoice.paymentMode}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BILLED TO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobileBilledTo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Billed To (Customer):',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(
            invoice.customerName ?? 'Counter Cash Customer',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (invoice.customerPhone?.isNotEmpty == true)
            Text('Phone: ${invoice.customerPhone}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Place of Supply:',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text('${invoice.stateName} (Code: ${invoice.stateCode})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDesktopBilledTo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Billed To (Customer):',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text(invoice.customerName ?? 'Counter Cash Customer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (invoice.customerPhone?.isNotEmpty == true)
                Text('Phone: ${invoice.customerPhone}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Place of Supply:',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text('${invoice.stateName} (Code: ${invoice.stateCode})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────────────────────

  /// Mobile: card per item — no fixed widths, no overflow
  Widget _buildMobileItemCards(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(child: Text('Item Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Text('Qty × Rate', style: TextStyle(color: Colors.white70, fontSize: 11)),
              SizedBox(width: 12),
              Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...invoice.items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: idx.isEven
                  ? (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight)
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Text('$idx',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                // Description + HSN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('HSN: ${item.hsnCode}  •  ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Line total
                Text(
                  '₹${item.lineTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Desktop: classic table
  Widget _buildDesktopTable(bool isDark) {
    return Table(
      border: TableBorder.all(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FixedColumnWidth(44),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(60),
        4: FixedColumnWidth(90),
        5: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryDark : AppColors.primary,
          ),
          children: [
            _th('S.N.'),
            _th('Description of Goods (Aquajaal)'),
            _th('HSN/SAC'),
            _th('Qty'),
            _th('Rate (₹)'),
            _th('Amount (₹)'),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: idx.isEven
                  ? (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight)
                  : null,
            ),
            children: [
              _td('$idx', align: TextAlign.center),
              _td(item.displayName, isBold: true),
              _td(item.hsnCode, align: TextAlign.center),
              _td('${item.quantity}', align: TextAlign.center, isBold: true),
              _td('₹${item.unitPrice.toStringAsFixed(2)}', align: TextAlign.right),
              _td('₹${item.lineTotal.toStringAsFixed(2)}', align: TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobileSummary(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount in words
        const Text('Amount Chargeable (in words):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDarkElevated : AppColors.accentContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent),
          ),
          child: Text(
            invoice.amountInWords,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.onAccent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Calculation box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: Column(
            children: [
              _calcRow('Sub Total', CurrencyFormatter.formatDetailed(invoice.subtotal)),
              if (invoice.discount > 0)
                _calcRow('Discount', '-${CurrencyFormatter.formatDetailed(invoice.discount)}',
                    color: AppColors.error),
              if (invoice.taxRate > 0) ...[
                _calcRow('CGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%)',
                    CurrencyFormatter.formatDetailed(invoice.cgst)),
                _calcRow('SGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%)',
                    CurrencyFormatter.formatDetailed(invoice.sgst)),
              ] else
                _calcRow('GST Rate', '0% (Exempt)'),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    CurrencyFormatter.formatDetailed(invoice.grandTotal),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(AppStrings.invoiceDeclaration,
            style: const TextStyle(
                fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildDesktopSummary(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Amount Chargeable (in words):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : AppColors.accentContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(
                  invoice.amountInWords,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.onAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(AppStrings.invoiceDeclaration,
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            child: Column(
              children: [
                _calcRow('Sub Total', CurrencyFormatter.formatDetailed(invoice.subtotal)),
                if (invoice.discount > 0)
                  _calcRow('Discount', '-${CurrencyFormatter.formatDetailed(invoice.discount)}',
                      color: AppColors.error),
                if (invoice.taxRate > 0) ...[
                  _calcRow('CGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%)',
                      CurrencyFormatter.formatDetailed(invoice.cgst)),
                  _calcRow('SGST (${(invoice.taxRate / 2).toStringAsFixed(1)}%)',
                      CurrencyFormatter.formatDetailed(invoice.sgst)),
                ] else
                  _calcRow('GST Rate', '0% (Exempt)'),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      CurrencyFormatter.formatDetailed(invoice.grandTotal),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _th(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _td(String val, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(val,
          textAlign: align,
          style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _calcRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
