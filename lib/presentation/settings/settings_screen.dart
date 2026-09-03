import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/store_settings.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/local_db_service.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Store Profile & System Settings', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Configure distributor details, low-stock thresholds, and data backup', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card 1: Distributor Profile
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
                            const Text('Distributor Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                              label: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildField('Company / Distributor Name', _nameController),
                        const SizedBox(height: 12),
                        _buildField('Address', _addressController),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildField('Phone Number', _phoneController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildField('Owner / Business Email', _emailController)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildField('GSTIN (Optional)', _gstinController, hint: 'e.g. 29AAAAA0000A1Z5'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: Billing & Low Stock Thresholds
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
                        const Text('Billing & Inventory Thresholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
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
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 0.0, child: Text('0% (Exempted Packaged Water)')),
                                      DropdownMenuItem(value: 5.0, child: Text('5% (2.5% CGST + 2.5% SGST)')),
                                      DropdownMenuItem(value: 12.0, child: Text('12% (6% CGST + 6% SGST)')),
                                      DropdownMenuItem(value: 18.0, child: Text('18% (9% CGST + 9% SGST)')),
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
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card 3: Theme Preferences
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Display Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? 'Dark Mode active for evening counter shifts' : 'Light Mode active',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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
                  ),
                ),
                const SizedBox(height: 20),

                // Card 4: Data Backup & Maintenance
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
                        const Text('Data Backup & Maintenance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text(
                          'Export your entire invoice history as Excel-compatible CSV, or reset database for testing.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Export CSV Button
                            ElevatedButton.icon(
                              onPressed: () async {
                                final invoices = LocalDbService.instance.getAllInvoices();
                                if (invoices.isEmpty) {
                                  AppToast.warning(context, 'No invoices recorded yet');
                                  return;
                                }
                                await CsvExportService.exportAndShareInvoices(invoices);
                              },
                              icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.white),
                              label: const Text('Export All Invoices (CSV)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Reset Button
                            OutlinedButton.icon(
                              onPressed: () => _confirmReset(context),
                              icon: const Icon(Icons.restart_alt_rounded, color: AppColors.error),
                              label: const Text('Reset to Factory Defaults', style: TextStyle(color: AppColors.error)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Aquajaal POS v1.0.0 • Yashodhar Enterprises',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Packaged Drinking Water With Added Minerals',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Factory Defaults?'),
        content: const Text(
          'This will clear transaction history and reset the Aquajaal product catalog and opening inventory to factory default values. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await LocalDbService.instance.resetToFactoryDefaults();
              if (context.mounted) {
                context.read<StockProvider>().loadData();
                context.read<SalesProvider>().refreshInvoices();
                AppToast.success(context, '✓ Database reset to factory defaults');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
