import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/product.dart';
import '../data/models/stock_movement.dart';
import '../data/models/invoice.dart';
import '../data/services/cloud_sync_service.dart';
import '../data/services/local_db_service.dart';

class LowStockItemInfo {
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final int currentStock;
  final int threshold;

  LowStockItemInfo({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.currentStock,
    required this.threshold,
  });

  String get displayName =>
      variantName != null ? '$productName ($variantName)' : productName;
}

/// Provider for managing inventory, product catalog, stock intakes, adjustments, and audit log
class StockProvider with ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final Uuid _uuid = const Uuid();

  List<Product> _products = [];
  List<StockMovement> _movements = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _filterLowStockOnly = false;
  bool _showArchivedOnly = false;

  StockProvider() {
    loadData();
    CloudSyncService.instance.addListener(loadData);
  }

  List<Product> get allProducts => _products;
  List<Product> get activeProducts => _products.where((p) => p.isActive).toList();
  List<Product> get archivedProducts => _products.where((p) => !p.isActive).toList();
  List<StockMovement> get allMovements => _movements;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get filterLowStockOnly => _filterLowStockOnly;
  bool get showArchivedOnly => _showArchivedOnly;

  /// Filtered product list for POS (active only)
  List<Product> get filteredPosProducts {
    return activeProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.variants.any((v) => v.name.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;

      final matchesLowStock = !_filterLowStockOnly || p.isLowStock || p.isOutOfStock;

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  /// Filtered products for Product Management / Stock Screen
  List<Product> get filteredProducts {
    final list = _showArchivedOnly ? archivedProducts : activeProducts;
    return list.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.variants.any((v) => v.name.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;

      final matchesLowStock = !_filterLowStockOnly || p.isLowStock || p.isOutOfStock;

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  /// Detailed list of all low-stock items across catalog for persistent banner
  List<LowStockItemInfo> get lowStockItems {
    final List<LowStockItemInfo> list = [];
    for (final p in activeProducts) {
      if (p.hasVariants) {
        for (final v in p.variants) {
          if (v.stock <= v.lowStockThreshold) {
            list.add(LowStockItemInfo(
              productId: p.id,
              productName: p.name,
              variantId: v.id,
              variantName: v.name,
              currentStock: v.stock,
              threshold: v.lowStockThreshold,
            ));
          }
        }
      } else {
        if (p.standaloneStock <= p.lowStockThreshold) {
          list.add(LowStockItemInfo(
            productId: p.id,
            productName: p.name,
            currentStock: p.standaloneStock,
            threshold: p.lowStockThreshold,
          ));
        }
      }
    }
    return list;
  }

  int get lowStockItemCount => lowStockItems.length;

  void loadData() {
    _products = _db.getAllProducts();
    _movements = _db.getAllStockMovements();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleLowStockFilter() {
    _filterLowStockOnly = !_filterLowStockOnly;
    notifyListeners();
  }

  void setShowArchivedOnly(bool value) {
    _showArchivedOnly = value;
    notifyListeners();
  }

  Product? findProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new product to the catalog
  Future<void> addProduct(Product product) async {
    _products.add(product);
    await _db.saveProduct(product);

    // If opening stock > 0, log initial intake
    if (product.hasVariants) {
      for (final v in product.variants) {
        if (v.stock > 0) {
          final movement = StockMovement(
            id: _uuid.v4(),
            productId: product.id,
            productName: product.name,
            variantId: v.id,
            variantName: v.name,
            quantityDelta: v.stock,
            type: 'intake',
            reference: 'Initial Opening Stock',
            previousStock: 0,
            newStock: v.stock,
            timestamp: DateTime.now(),
          );
          await _db.saveStockMovement(movement);
          _movements.insert(0, movement);
        }
      }
    } else if (product.standaloneStock > 0) {
      final movement = StockMovement(
        id: _uuid.v4(),
        productId: product.id,
        productName: product.name,
        quantityDelta: product.standaloneStock,
        type: 'intake',
        reference: 'Initial Opening Stock',
        previousStock: 0,
        newStock: product.standaloneStock,
        timestamp: DateTime.now(),
      );
      await _db.saveStockMovement(movement);
      _movements.insert(0, movement);
    }

    notifyListeners();
  }

  /// Updates a product's price or threshold without affecting historical invoices
  Future<void> updateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product.copyWith(updatedAt: DateTime.now());
      await _db.saveProduct(_products[idx]);
      notifyListeners();
    }
  }

  /// Deactivates / archives or restores a product
  Future<void> toggleProductActive(String productId, bool isActive) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(isActive: isActive, updatedAt: DateTime.now());
      await _db.saveProduct(_products[idx]);
      notifyListeners();
    }
  }

  /// Checks if product has zero sales history before permanent delete
  bool canDeleteProduct(String productId) {
    final hasMovements = _movements.any((m) => m.productId == productId && m.type == 'sale');
    return !hasMovements;
  }

  /// Permanently removes a product only if it has no sales history
  Future<bool> deleteProductPermanently(String productId) async {
    if (!canDeleteProduct(productId)) {
      return false;
    }
    _products.removeWhere((p) => p.id == productId);
    await _db.deleteProduct(productId);
    notifyListeners();
    return true;
  }

  /// Records incoming stock from production or supplier
  Future<void> recordStockIntake({
    required String productId,
    String? variantId,
    required int quantityReceived,
    required String supplierReference,
    String? notes,
  }) async {
    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return;

    final product = _products[productIndex];
    int oldStock = 0;
    int newStock = 0;
    String? variantName;

    if (product.hasVariants && variantId != null) {
      final variantIndex = product.variants.indexWhere((v) => v.id == variantId);
      if (variantIndex != -1) {
        final variant = product.variants[variantIndex];
        oldStock = variant.stock;
        newStock = oldStock + quantityReceived;
        variantName = variant.name;

        product.variants[variantIndex] = variant.copyWith(stock: newStock);
      }
    } else {
      oldStock = product.standaloneStock;
      newStock = oldStock + quantityReceived;
      _products[productIndex] = product.copyWith(standaloneStock: newStock);
    }

    await _db.saveProduct(_products[productIndex]);

    final movement = StockMovement(
      id: _uuid.v4(),
      productId: productId,
      productName: product.name,
      variantId: variantId,
      variantName: variantName,
      quantityDelta: quantityReceived,
      type: 'intake',
      reference: supplierReference.isNotEmpty ? supplierReference : 'Stock Inward',
      previousStock: oldStock,
      newStock: newStock,
      notes: notes,
      timestamp: DateTime.now(),
    );

    await _db.saveStockMovement(movement);
    _movements.insert(0, movement);
    notifyListeners();
  }

  /// Manually adjusts stock (damage, leakage, reconciliation)
  Future<void> adjustStock({
    required String productId,
    String? variantId,
    required int updatedStock,
    required String reason,
  }) async {
    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return;

    final product = _products[productIndex];
    int oldStock = 0;
    String? variantName;

    if (product.hasVariants && variantId != null) {
      final variantIndex = product.variants.indexWhere((v) => v.id == variantId);
      if (variantIndex != -1) {
        final variant = product.variants[variantIndex];
        oldStock = variant.stock;
        variantName = variant.name;
        product.variants[variantIndex] = variant.copyWith(stock: updatedStock);
      }
    } else {
      oldStock = product.standaloneStock;
      _products[productIndex] = product.copyWith(standaloneStock: updatedStock);
    }

    final delta = updatedStock - oldStock;
    await _db.saveProduct(_products[productIndex]);

    final movement = StockMovement(
      id: _uuid.v4(),
      productId: productId,
      productName: product.name,
      variantId: variantId,
      variantName: variantName,
      quantityDelta: delta,
      type: 'adjustment',
      reference: 'Manual Adjustment',
      previousStock: oldStock,
      newStock: updatedStock,
      notes: reason,
      timestamp: DateTime.now(),
    );

    await _db.saveStockMovement(movement);
    _movements.insert(0, movement);
    notifyListeners();
  }

  /// Deducts stock automatically when an invoice is created
  Future<void> deductStockForInvoice(Invoice invoice) async {
    for (final item in invoice.items) {
      final productIndex = _products.indexWhere((p) => p.id == item.productId);
      if (productIndex == -1) continue;

      final product = _products[productIndex];
      int oldStock = 0;
      int newStock = 0;

      if (product.hasVariants && item.variantId != null) {
        final variantIndex = product.variants.indexWhere((v) => v.id == item.variantId);
        if (variantIndex != -1) {
          final variant = product.variants[variantIndex];
          oldStock = variant.stock;
          newStock = oldStock - item.quantity;
          product.variants[variantIndex] = variant.copyWith(stock: newStock);
        }
      } else {
        oldStock = product.standaloneStock;
        newStock = oldStock - item.quantity;
        _products[productIndex] = product.copyWith(standaloneStock: newStock);
      }

      await _db.saveProduct(_products[productIndex]);

      final movement = StockMovement(
        id: _uuid.v4(),
        productId: item.productId,
        productName: item.productName,
        variantId: item.variantId,
        variantName: item.variantName,
        quantityDelta: -item.quantity,
        type: 'sale',
        reference: invoice.invoiceNumber,
        previousStock: oldStock,
        newStock: newStock,
        notes: 'Sale to ${invoice.customerName ?? "Counter Customer"}',
        timestamp: invoice.createdAt,
      );

      await _db.saveStockMovement(movement);
      _movements.insert(0, movement);
    }

    notifyListeners();
  }
}
