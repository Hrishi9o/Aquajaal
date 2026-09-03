import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'local_db_service.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

/// Real-time and background cloud synchronization bridge between multiple family devices (Brother's counter phone & Father's phone).
/// Retains 100% offline-first local persistence: if the counter internet is down, invoices save locally
/// and automatically push to the cloud as soon as connection is available.
class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  bool _isResetting = false;
  bool get isResetting => _isResetting;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  static const String defaultFirebaseUrl =
      'https://yashodhar-enterprises-default-rtdb.asia-southeast1.firebasedatabase.app/';

  // Cloud endpoint (Supports Firebase Realtime Database REST API or Supabase / REST bridges)
  String _cloudUrl = defaultFirebaseUrl;
  String get cloudUrl => _cloudUrl;

  Timer? _periodicSyncTimer;

  /// Initializes the cloud sync service with saved settings and starts background sync
  Future<void> init() async {
    _cloudUrl = defaultFirebaseUrl;

    // Start periodic background sync polling every 30 seconds
    _startPeriodicSync();

    // Fire-and-forget startup sync — silently goes offline if no network
    unawaited(triggerFullSync());
  }

  void configure({required String url, required bool autoSync}) {
    // Remove stray spaces and ensure trailing slash
    final cleaned = url.trim().replaceAll(' ', '');
    _cloudUrl = cleaned.isEmpty ? defaultFirebaseUrl : (cleaned.endsWith('/') ? cleaned : '${cleaned}/');
    _autoSyncEnabled = autoSync;
    notifyListeners();
    if (_autoSyncEnabled && _cloudUrl.isNotEmpty) {
      triggerFullSync();
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_autoSyncEnabled && _cloudUrl.isNotEmpty) {
        triggerFullSync();
      }
    });
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  /// Triggers bidirectional sync: pushes local pending records, then pulls remote updates
  Future<bool> triggerFullSync() async {
    if (_cloudUrl.isEmpty || _isResetting) {
      if (_cloudUrl.isEmpty) {
        _status = SyncStatus.idle;
      }
      notifyListeners();
      return false;
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Push local invoices to cloud
      final localInvoices = LocalDbService.instance.getAllInvoices();
      for (final inv in localInvoices) {
        await _pushEntity('invoices', inv.id, inv.toJson());
      }

      // 2. Push local products to cloud
      final localProducts = LocalDbService.instance.getAllProducts();
      for (final prod in localProducts) {
        await _pushEntity('products', prod.id, prod.toJson());
      }

      // 3. Push local stock movements to cloud
      final localStock = LocalDbService.instance.getAllStockMovements();
      for (final mov in localStock) {
        await _pushEntity('stock_movements', mov.id, mov.toJson());
      }

      // 4. Pull remote invoices created by other devices (e.g. brother's phone)
      final remoteInvoices = await _fetchEntities('invoices');
      if (remoteInvoices != null) {
        for (final entry in remoteInvoices.entries) {
          try {
            final data = entry.value is Map<String, dynamic>
                ? entry.value as Map<String, dynamic>
                : jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
            final inv = Invoice.fromJson(data);
            await LocalDbService.instance.saveInvoice(inv, syncToCloud: false);
          } catch (e) {
            debugPrint('[CloudSync] Error parsing remote invoice ${entry.key}: $e');
          }
        }
      }

      // 5. Pull remote products updated by other devices
      final remoteProducts = await _fetchEntities('products');
      if (remoteProducts != null) {
        for (final entry in remoteProducts.entries) {
          try {
            final data = entry.value is Map<String, dynamic>
                ? entry.value as Map<String, dynamic>
                : jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
            final prod = Product.fromJson(data);
            await LocalDbService.instance.saveProduct(prod, syncToCloud: false);
          } catch (e) {
            debugPrint('[CloudSync] Error parsing remote product ${entry.key}: $e');
          }
        }
      }

      // 6. Pull remote stock movements updated by other devices
      final remoteStockMovements = await _fetchEntities('stock_movements');
      if (remoteStockMovements != null) {
        for (final entry in remoteStockMovements.entries) {
          try {
            final data = entry.value is Map<String, dynamic>
                ? entry.value as Map<String, dynamic>
                : jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
            final mov = StockMovement.fromJson(data);
            await LocalDbService.instance.saveStockMovement(mov, syncToCloud: false);
          } catch (e) {
            debugPrint('[CloudSync] Error parsing remote stock movement ${entry.key}: $e');
          }
        }
      }

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      notifyListeners();
      return true;
    } on SocketException catch (e) {
      // Network/DNS failure — treat as offline, not an error state
      debugPrint('[CloudSync] Offline (network unavailable): $e');
      _status = SyncStatus.offline;
      _lastError = 'No internet connection. Data is saved locally and will sync when online.';
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      debugPrint('[CloudSync] Sync timed out: $e');
      _status = SyncStatus.offline;
      _lastError = 'Connection timed out. Will retry when network is available.';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[CloudSync] Sync failed: $e');
      _status = SyncStatus.error;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Immediately pushes a newly created invoice to the cloud when online
  Future<void> pushNewInvoice(Invoice invoice) async {
    if (_cloudUrl.isEmpty) return;
    try {
      await _pushEntity('invoices', invoice.id, invoice.toJson());
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e) {
      debugPrint('[CloudSync] Failed to push new invoice immediately: $e');
      // Saved locally in Hive already; will push on next full sync
    }
  }

  /// Immediately pushes a product update to the cloud when online
  Future<void> pushProductUpdate(Product product) async {
    if (_cloudUrl.isEmpty) return;
    try {
      await _pushEntity('products', product.id, product.toJson());
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e) {
      debugPrint('[CloudSync] Failed to push product update: $e');
    }
  }

  /// Immediately pushes stock movement to the cloud
  Future<void> pushStockMovement(StockMovement movement) async {
    if (_cloudUrl.isEmpty) return;
    try {
      await _pushEntity('stock_movements', movement.id, movement.toJson());
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      notifyListeners();
    } catch (e) {
      debugPrint('[CloudSync] Failed to push stock movement: $e');
    }
  }

  /// Wipes all remote collections in Cloud / Firebase and re-pushes fresh seed data
  Future<void> resetRemoteData() async {
    if (_cloudUrl.isEmpty) return;
    _isResetting = true;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Delete remote collections from Firebase RTDB
      await _deleteEntityCollection('invoices');
      await _deleteEntityCollection('stock_movements');
      await _deleteEntityCollection('products');

      // 2. Re-push fresh seed products
      final localProducts = LocalDbService.instance.getAllProducts();
      for (final prod in localProducts) {
        await _pushEntity('products', prod.id, prod.toJson());
      }

      // 3. Re-push fresh seed stock movements
      final localStock = LocalDbService.instance.getAllStockMovements();
      for (final mov in localStock) {
        await _pushEntity('stock_movements', mov.id, mov.toJson());
      }

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      _lastError = null;
    } on SocketException catch (e) {
      debugPrint('[CloudSync] Offline while resetting cloud data: $e');
      _status = SyncStatus.offline;
      _lastError = 'Offline: Cloud wipe failed, local database reset successfully.';
    } on TimeoutException catch (e) {
      debugPrint('[CloudSync] Timeout while resetting cloud data: $e');
      _status = SyncStatus.offline;
      _lastError = 'Cloud sync timed out during reset.';
    } catch (e) {
      debugPrint('[CloudSync] Error resetting remote data: $e');
      _status = SyncStatus.error;
      _lastError = e.toString();
    } finally {
      _isResetting = false;
      notifyListeners();
    }
  }

  /// Deletes all invoices from Cloud / Firebase
  Future<void> clearRemoteInvoices() async {
    if (_cloudUrl.isEmpty) return;
    _isResetting = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      await _deleteEntityCollection('invoices');
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      _lastError = null;
    } catch (e) {
      debugPrint('[CloudSync] Error clearing remote invoices: $e');
    } finally {
      _isResetting = false;
      notifyListeners();
    }
  }

  /// Deletes an individual remote entity by collection and id
  Future<void> deleteRemoteEntity(String collection, String id) async {
    if (_cloudUrl.isEmpty) return;
    try {
      final url = Uri.parse(_buildUrl(collection, id));
      await http.delete(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[CloudSync] Failed to delete remote entity $collection/$id: $e');
    }
  }

  // --- REST helpers ---

  String _buildUrl(String collection, [String? id]) {
    var base = _cloudUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    // If Firebase Realtime Database
    if (base.contains('firebaseio.com') || base.contains('firebasedatabase.app')) {
      if (id != null) {
        return '$base/$collection/$id.json';
      }
      return '$base/$collection.json';
    }
    // Generic REST URL
    if (id != null) {
      return '$base/$collection/$id';
    }
    return '$base/$collection';
  }

  Future<void> _deleteEntityCollection(String collection) async {
    try {
      final url = Uri.parse(_buildUrl(collection));
      final response = await http.delete(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        debugPrint('[CloudSync] DELETE $collection returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[CloudSync] Error deleting collection $collection: $e');
    }
  }

  Future<void> _pushEntity(String collection, String id, Map<String, dynamic> data) async {
    final url = Uri.parse(_buildUrl(collection, id));
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> _fetchEntities(String collection) async {
    final url = Uri.parse(_buildUrl(collection));
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }
}
