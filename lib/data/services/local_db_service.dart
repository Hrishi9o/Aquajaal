import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/stock_movement.dart';
import '../models/store_settings.dart';
import 'cloud_sync_service.dart';
import 'seed_data.dart';

/// Local Database Service using Hive (IndexedDB on Web, Disk on Mobile/Desktop)
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static const String _productsBoxName = 'aquajaal_products';
  static const String _invoicesBoxName = 'aquajaal_invoices';
  static const String _stockBoxName = 'aquajaal_stock_movements';
  static const String _settingsBoxName = 'aquajaal_settings';

  late Box<String> _productsBox;
  late Box<String> _invoicesBox;
  late Box<String> _stockBox;
  late Box<String> _settingsBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initializes Hive and opens all application boxes
  Future<void> init([String? customPath]) async {
    if (_initialized) return;

    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    _productsBox = await Hive.openBox<String>(_productsBoxName);
    _invoicesBox = await Hive.openBox<String>(_invoicesBoxName);
    _stockBox = await Hive.openBox<String>(_stockBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);

    // Seed initial products if box is empty
    if (_productsBox.isEmpty) {
      debugPrint('[LocalDbService] Seeding initial catalog data...');
      await _seedInitialData();
    }

    _initialized = true;
    debugPrint('[LocalDbService] Hive DB initialized successfully across platforms.');
  }

  Future<void> _seedInitialData() async {
    for (final product in SeedData.initialProducts) {
      await _productsBox.put(product.id, jsonEncode(product.toJson()));
    }
    for (final movement in SeedData.initialStockMovements) {
      await _stockBox.put(movement.id, jsonEncode(movement.toJson()));
    }
  }

  // --- Products ---

  List<Product> getAllProducts() {
    final List<Product> list = [];
    for (final raw in _productsBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        list.add(Product.fromJson(map));
      } catch (e) {
        debugPrint('[LocalDbService] Error parsing product: $e');
      }
    }
    return list;
  }

  Future<void> saveProduct(Product product, {bool syncToCloud = true}) async {
    await _productsBox.put(product.id, jsonEncode(product.toJson()));
    if (syncToCloud) {
      unawaited(CloudSyncService.instance.pushProductUpdate(product));
    }
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
  }

  // --- Invoices ---

  List<Invoice> getAllInvoices() {
    final List<Invoice> list = [];
    for (final raw in _invoicesBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        list.add(Invoice.fromJson(map));
      } catch (e) {
        debugPrint('[LocalDbService] Error parsing invoice: $e');
      }
    }
    // Sort descending by creation date
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveInvoice(Invoice invoice, {bool syncToCloud = true}) async {
    await _invoicesBox.put(invoice.id, jsonEncode(invoice.toJson()));
    if (syncToCloud) {
      unawaited(CloudSyncService.instance.pushNewInvoice(invoice));
    }
  }

  // --- Stock Movements ---

  List<StockMovement> getAllStockMovements() {
    final List<StockMovement> list = [];
    for (final raw in _stockBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        list.add(StockMovement.fromJson(map));
      } catch (e) {
        debugPrint('[LocalDbService] Error parsing stock movement: $e');
      }
    }
    // Sort descending by timestamp
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> saveStockMovement(StockMovement movement, {bool syncToCloud = true}) async {
    await _stockBox.put(movement.id, jsonEncode(movement.toJson()));
    if (syncToCloud) {
      unawaited(CloudSyncService.instance.pushStockMovement(movement));
    }
  }

  // --- Settings ---

  StoreSettings getSettings() {
    final raw = _settingsBox.get('current_settings');
    if (raw == null) {
      return StoreSettings();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoreSettings.fromJson(map);
    } catch (e) {
      debugPrint('[LocalDbService] Error parsing settings: $e');
      return StoreSettings();
    }
  }

  Future<void> saveSettings(StoreSettings settings) async {
    await _settingsBox.put('current_settings', jsonEncode(settings.toJson()));
  }

  /// Increments and returns the next invoice sequence number
  Future<int> getAndIncrementInvoiceSequence() async {
    final settings = getSettings();
    final currentSeq = settings.nextInvoiceSequence;
    await saveSettings(settings.copyWith(nextInvoiceSequence: currentSeq + 1));
    return currentSeq;
  }

  /// Factory reset: Clears all data and re-seeds original catalog
  Future<void> resetToFactoryDefaults() async {
    await _productsBox.clear();
    await _invoicesBox.clear();
    await _stockBox.clear();
    await _settingsBox.clear();
    await _seedInitialData();
  }
}
