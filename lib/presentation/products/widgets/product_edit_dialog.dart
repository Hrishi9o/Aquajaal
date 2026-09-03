import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../data/models/product.dart';

/// Modal dialog for adding or editing products & variants
class ProductEditDialog extends StatefulWidget {
  final Product? productToEdit;
  final Function(Product product) onSave;

  const ProductEditDialog({
    super.key,
    this.productToEdit,
    required this.onSave,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _skuController;
  late TextEditingController _hsnController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;

  bool _hasVariants = false;
  List<ProductVariant> _variants = [];

  final List<String> _commonCategories = ['Jars', 'Cases', 'Bottles', 'General'];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Cases');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _hsnController = TextEditingController(text: p?.hsnCode ?? '2201');
    _priceController = TextEditingController(
        text: p?.standalonePrice != null ? p!.standalonePrice!.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p?.standaloneStock.toString() ?? '0');
    _thresholdController = TextEditingController(text: p?.lowStockThreshold.toString() ?? '10');

    _hasVariants = p?.hasVariants ?? false;
    if (p != null && p.variants.isNotEmpty) {
      _variants = p.variants.map((v) => v.copyWith()).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _hsnController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariant(
        id: 'var_${_uuid.v4().substring(0, 8)}',
        name: 'Variant ${_variants.length + 1}',
        price: 80.0,
        stock: 50,
        lowStockThreshold: 15,
      ));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_hasVariants && _variants.isEmpty) {
      AppToast.error(context, 'Please add at least one variant');
      return;
    }

    final isEdit = widget.productToEdit != null;
    final productId = isEdit ? widget.productToEdit!.id : 'prod_${_uuid.v4().substring(0, 8)}';

    final product = Product(
      id: productId,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'Cases',
      hsnCode: _hsnController.text.trim().isNotEmpty ? _hsnController.text.trim() : '2201',
      sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
      hasVariants: _hasVariants,
      variants: _hasVariants ? _variants : const [],
      standalonePrice: !_hasVariants ? double.tryParse(_priceController.text) ?? 0.0 : null,
      standaloneStock: !_hasVariants ? int.tryParse(_stockController.text) ?? 0 : 0,
      lowStockThreshold: int.tryParse(_thresholdController.text) ?? 10,
      isActive: isEdit ? widget.productToEdit!.isActive : true,
      createdAt: isEdit ? widget.productToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(product);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.productToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Product' : 'Add New Product',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isEdit
                                ? 'Price edits apply to new sales; past invoices stay unchanged.'
                                : 'Add a product or variant line to your counter catalog.',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form Scroll Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            hintText: 'e.g. Aquajaal JAR 20 Ltr Filling',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.water_drop_outlined),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Product name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Category & HSN Code
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _commonCategories.contains(_categoryController.text)
                                    ? _categoryController.text
                                    : 'Cases',
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _commonCategories
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _categoryController.text = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _hsnController,
                                decoration: InputDecoration(
                                  labelText: 'HSN Code',
                                  hintText: '2201',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // SKU (optional)
                        TextFormField(
                          controller: _skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU / Barcode (Optional)',
                            hintText: 'e.g. AQJ-2000ML-CASE',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.qr_code_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Variants Toggle Switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDarkElevated : AppColors.primaryContainer.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.waterBlueLight),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Product has Quality/Size Variants', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Enable for items like 20L Jars with Dim, Medium, Best tiers', style: TextStyle(fontSize: 11)),
                            value: _hasVariants,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _hasVariants = val;
                                if (val && _variants.isEmpty) {
                                  _variants = [
                                    ProductVariant(id: 'var_1', name: 'Standard', price: 60.0, stock: 100, lowStockThreshold: 10),
                                  ];
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Standalone fields vs Variant fields
                        if (!_hasVariants) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Unit Price (₹) *',
                                    hintText: '120.00',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (val) {
                                    final p = double.tryParse(val ?? '');
                                    if (p == null || p <= 0) return 'Enter valid price';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Opening Stock *',
                                    hintText: '50',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (val) {
                                    final s = int.tryParse(val ?? '');
                                    if (s == null || s < 0) return 'Enter valid stock';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _thresholdController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Low Threshold',
                                    hintText: '10',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // List of Variants
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Variants (${_variants.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              TextButton.icon(
                                onPressed: _addVariant,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Variant'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._variants.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final variant = entry.value;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: variant.name,
                                        decoration: const InputDecoration(labelText: 'Variant Name', isDense: true),
                                        onChanged: (v) => _variants[idx] = variant.copyWith(name: v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: variant.price.toStringAsFixed(0),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹', isDense: true),
                                        onChanged: (v) {
                                          final p = double.tryParse(v) ?? variant.price;
                                          _variants[idx] = variant.copyWith(price: p);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: variant.stock.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Stock', isDense: true),
                                        onChanged: (v) {
                                          final s = int.tryParse(v) ?? variant.stock;
                                          _variants[idx] = variant.copyWith(stock: s);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      onPressed: () => _removeVariant(idx),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Footer buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: Text(isEdit ? 'Update Product' : 'Create Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
