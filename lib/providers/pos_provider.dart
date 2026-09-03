import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/product.dart';
import '../data/models/cart_item.dart';
import '../data/models/invoice.dart';
import '../data/services/local_db_service.dart';
import '../../core/utils/number_to_words.dart';
import 'stock_provider.dart';

/// Provider managing active POS cart, customer details, and invoice generation
class PosProvider with ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final Uuid _uuid = const Uuid();

  final Map<String, CartItem> _cartItems = {};
  String _customerName = '';
  String _customerPhone = '';
  String _paymentMode = 'Cash';
  double _discount = 0.0;
  String _notes = '';

  Map<String, CartItem> get cartItems => _cartItems;
  List<CartItem> get cartItemList => _cartItems.values.toList();
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get paymentMode => _paymentMode;
  double get discount => _discount;
  String get notes => _notes;

  int get totalItemCount => _cartItems.values.fold(0, (sum, i) => sum + i.quantity);

  int getQuantityInCart(String productId) {
    int total = 0;
    for (final item in _cartItems.values) {
      if (item.productId == productId) {
        total += item.quantity;
      }
    }
    return total;
  }

  double get subtotal => _cartItems.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Configurable tax rate from store settings
  double get taxRate => _db.getSettings().defaultTaxRate;

  /// Taxable amount after discount
  double get taxableAmount {
    final afterDiscount = subtotal - _discount;
    return afterDiscount > 0 ? afterDiscount : 0.0;
  }

  double get taxAmount => (taxableAmount * taxRate) / 100.0;
  double get cgst => taxAmount / 2.0;
  double get sgst => taxAmount / 2.0;

  double get grandTotal {
    final total = taxableAmount + taxAmount;
    // Round to nearest integer standard in Indian retail
    return total.roundToDouble();
  }

  String get amountInWords => NumberToWords.convert(grandTotal);

  // --- Cart Operations ---

  /// Helper to check if an item is at or below threshold
  bool isItemLowStock(Product product, {ProductVariant? variant}) {
    if (variant != null) {
      return variant.stock <= variant.lowStockThreshold;
    }
    return product.standaloneStock <= product.lowStockThreshold;
  }

  void addToCart(Product product, {ProductVariant? variant, int quantity = 1}) {
    final key = variant != null ? '${product.id}_${variant.id}' : product.id;
    final price = variant?.price ?? product.standalonePrice ?? 0.0;
    final availableStock = variant?.stock ?? product.standaloneStock;

    if (_cartItems.containsKey(key)) {
      final existing = _cartItems[key]!;
      existing.quantity += quantity;
    } else {
      _cartItems[key] = CartItem(
        productId: product.id,
        productName: product.name,
        variantId: variant?.id,
        variantName: variant?.name,
        hsnCode: product.hsnCode,
        unitPrice: price,
        quantity: quantity,
        availableStock: availableStock,
      );
    }
    notifyListeners();
  }

  void updateQuantity(String cartKey, int newQuantity) {
    if (!_cartItems.containsKey(cartKey)) return;

    if (newQuantity <= 0) {
      _cartItems.remove(cartKey);
    } else {
      _cartItems[cartKey]!.quantity = newQuantity;
    }
    notifyListeners();
  }

  void incrementItem(String cartKey) {
    if (_cartItems.containsKey(cartKey)) {
      _cartItems[cartKey]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrementItem(String cartKey) {
    if (!_cartItems.containsKey(cartKey)) return;
    if (_cartItems[cartKey]!.quantity > 1) {
      _cartItems[cartKey]!.quantity -= 1;
    } else {
      _cartItems.remove(cartKey);
    }
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _cartItems.remove(cartKey);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _customerName = '';
    _customerPhone = '';
    _discount = 0.0;
    _notes = '';
    notifyListeners();
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void setPaymentMode(String mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    notifyListeners();
  }

  // --- Stock Validation ---

  /// Returns list of items in cart where quantity exceeds available inventory
  List<CartItem> getItemsExceedingStock(StockProvider stockProvider) {
    final List<CartItem> deficitItems = [];

    for (final item in _cartItems.values) {
      final product = stockProvider.findProductById(item.productId);
      if (product == null) continue;

      int currentStock = 0;
      if (product.hasVariants && item.variantId != null) {
        final variant = product.variants.firstWhere(
          (v) => v.id == item.variantId,
          orElse: () => ProductVariant(id: '', name: '', price: 0, stock: 0),
        );
        currentStock = variant.stock;
      } else {
        currentStock = product.standaloneStock;
      }

      if (item.quantity > currentStock) {
        deficitItems.add(item.copyWith(availableStock: currentStock));
      }
    }

    return deficitItems;
  }

  // --- Checkout Execution ---

  /// Finalizes sale, creates persisted invoice, updates inventory & stock logs
  Future<Invoice> checkout(StockProvider stockProvider) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty. Please add items before checking out.');
    }

    final settings = _db.getSettings();
    final sequence = await _db.getAndIncrementInvoiceSequence();
    final now = DateTime.now();
    final year = now.year;
    final mmdd = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final seqStr = sequence.toString().padLeft(4, '0');
    final invoiceNumber = '${settings.invoicePrefix}-$year-$mmdd-$seqStr';

    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: invoiceNumber,
      invoiceSequence: sequence,
      createdAt: now,
      customerName: _customerName.trim().isNotEmpty ? _customerName.trim() : null,
      customerPhone: _customerPhone.trim().isNotEmpty ? _customerPhone.trim() : null,
      items: List.from(_cartItems.values),
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      cgst: cgst,
      sgst: sgst,
      discount: _discount,
      grandTotal: grandTotal,
      amountInWords: amountInWords,
      paymentMode: _paymentMode,
      paymentStatus: 'PAID',
      notes: _notes.trim().isNotEmpty ? _notes.trim() : null,
      stateName: settings.stateName,
      stateCode: settings.stateCode,
    );

    // 1. Save invoice to database
    await _db.saveInvoice(invoice);

    // 2. Automatically deduct inventory in real time
    await stockProvider.deductStockForInvoice(invoice);

    // 3. Clear cart after successful checkout
    clearCart();

    return invoice;
  }
}
