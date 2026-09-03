import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/store_settings.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/local_db_service.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/theme_provider.dart';

/// Settings screen for configuring store profile, tax rates, theme, CSV export, and data reset
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StoreSettings _settings;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstinController;
  late final TextEditingController _thresholdController;
  double _taxRate = 0.0;

  @override
  void initState() {
    super.initState();
    _settings = LocalDbService.instance.getSettings();
    _nameController = TextEditingController(text: _settings.distributorName);
    _addressController = TextEditingController(text: _settings.distributorAddress);
    _cityController = TextEditingController(text: _settings.distributorCity);
    _phoneController = TextEditingController(text: _settings.phone);
    _emailController = TextEditingController(text: _settings.email);
    _gstinController = TextEditingController(text: _settings.gstin);
    _thresholdController = TextEditingController(text: _settings.defaultLowStockThreshold.toString());
    _taxRate = _settings.defaultTaxRate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _reloadControllers() {
    _settings = LocalDbService.instance.getSettings();
    _nameController.text = _settings.distributorName;
    _addressController.text = _settings.distributorAddress;
    _cityController.text = _settings.distributorCity;
    _phoneController.text = _settings.phone;
    _emailController.text = _settings.email;
    _gstinController.text = _settings.gstin;
    _thresholdController.text = _settings.defaultLowStockThreshold.toString();
    _taxRate = _settings.defaultTaxRate;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final updated = _settings.copyWith(
      distributorName: _nameController.text.trim(),
      distributorAddress: _addressController.text.trim(),
      distributorCity: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gstin: _gstinController.text.trim(),
      defaultLowStockThreshold: int.tryParse(_thresholdController.text) ?? 10,
      defaultTaxRate: _taxRate,
    );
    await LocalDbService.instance.saveSettings(updated);
    setState(() => _settings = updated);

    if (mounted) {
      AppToast.success(context, '✓ Settings saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Store & System Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Text('Distributor details, thresholds, and data backup', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card 1: Distributor Profile
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Distributor Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                              label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildField('Company / Distributor Name', _nameController),
                        const SizedBox(height: 10),
                        _buildField('Address', _addressController),
                        const SizedBox(height: 10),
                        if (isMobile) ...[
                          _buildField('City, Dist & PIN', _cityController),
                          const SizedBox(height: 10),
                          _buildField(
                            'State (Code)',
                            TextEditingController(text: '${_settings.stateName} (${_settings.stateCode})'),
                            enabled: false,
                          ),
                          const SizedBox(height: 10),
                          _buildField('Phone Number', _phoneController),
                          const SizedBox(height: 10),
                          _buildField('Owner / Business Email', _emailController),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: _buildField('City, Dist & PIN', _cityController)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  'State (Code)',
                                  TextEditingController(text: '${_settings.stateName} (${_settings.stateCode})'),
                                  enabled: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildField('Phone Number', _phoneController)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildField('Owner / Business Email', _emailController)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildField('GSTIN (Optional)', _gstinController, hint: 'e.g. 29AAAAA0000A1Z5'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Card 2: Billing & Low Stock Thresholds
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Billing & Inventory Thresholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 14),
                        if (isMobile) ...[
                          _buildField(
                            'Default Low-Stock Alert Threshold (Units)',
                            _thresholdController,
                            hint: '10',
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('GST Tax Rate (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<double>(
                                value: _taxRate,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0% — Exempted', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 5.0, child: Text('5% GST (2.5%+2.5%)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 12.0, child: Text('12% GST (6%+6%)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 18.0, child: Text('18% GST (9%+9%)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _taxRate = val);
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  'Default Low-Stock Alert Threshold (Units)',
                                  _thresholdController,
                                  hint: '10',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('GST Tax Rate (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<double>(
                                      value: _taxRate,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 0.0, child: Text('0% — Exempted', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 5.0, child: Text('5% GST (2.5%+2.5%)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 12.0, child: Text('12% GST (6%+6%)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 18.0, child: Text('18% GST (9%+9%)', overflow: TextOverflow.ellipsis)),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _taxRate = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Card 3: Theme Preferences
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Display Theme', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                isDark ? 'Dark Mode active' : 'Light Mode active',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          activeColor: AppColors.accentDark,
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Card 4: Data Backup & Maintenance
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data Backup & Maintenance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text(
                          'Export invoice history as Excel-compatible CSV, or reset database.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final invoices = LocalDbService.instance.getAllInvoices();
                                if (invoices.isEmpty) {
                                  AppToast.warning(context, 'No invoices recorded yet');
                                  return;
                                }
                                await CsvExportService.exportAndShareInvoices(invoices);
                              },
                              icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
                              label: const Text('Export All Invoices (CSV)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _confirmClearInvoices(context),
                              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.warning, size: 16),
                              label: const Text('Clear Invoices Only', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.warning),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _confirmReset(context),
                              icon: const Icon(Icons.restart_alt_rounded, color: AppColors.error, size: 16),
                              label: const Text('Reset Factory Defaults', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Aquajaal POS v1.0.0 • Yashodhar Enterprises',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Packaged Drinking Water With Added Minerals',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    bool isResetting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Expanded(child: Text('Reset to Factory Defaults?')),
            ],
          ),
          content: const Text(
            'This will permanently wipe all sales invoices, transaction history, and custom products from both this device and Cloud Sync.\n\n'
            'The Aquajaal catalog and stock levels will be restored to factory default values.\n\n'
            'This action CANNOT be undone.',
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isResetting
                  ? null
                  : () async {
                      setDialogState(() => isResetting = true);
                      try {
                        await LocalDbService.instance.resetToFactoryDefaults();
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                        if (mounted) {
                          context.read<StockProvider>().loadData();
                          context.read<SalesProvider>().refreshInvoices();
                          context.read<PosProvider>().clearCart();
                          _reloadControllers();
                          AppToast.success(context, '✓ Database and cloud sync reset to factory defaults');
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isResetting = false);
                        }
                        if (mounted) {
                          AppToast.error(context, 'Reset failed: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: isResetting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Resetting...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('Reset Everything', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearInvoices(BuildContext context) {
    bool isClearing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(child: Text('Clear All Invoices?')),
            ],
          ),
          content: const Text(
            'This will permanently delete all sales invoices and reset invoice numbering back to #1 on both local storage and Cloud Sync.\n\n'
            'Your product catalog, current inventory stock levels, and store profile will NOT be changed.',
          ),
          actions: [
            TextButton(
              onPressed: isClearing ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isClearing
                  ? null
                  : () async {
                      setDialogState(() => isClearing = true);
                      try {
                        await LocalDbService.instance.clearInvoiceHistory();
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                        if (mounted) {
                          context.read<SalesProvider>().refreshInvoices();
                          context.read<PosProvider>().clearCart();
                          AppToast.success(context, '✓ All invoices cleared from local and cloud storage');
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          setDialogState(() => isClearing = false);
                        }
                        if (mounted) {
                          AppToast.error(context, 'Clear failed: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: isClearing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Clearing...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('Clear Invoices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
