/// Item in active POS cart or completed invoice line
class CartItem {
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final String hsnCode;
  final double unitPrice;
  int quantity;
  final int availableStock;

  CartItem({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.hsnCode,
    required this.unitPrice,
    this.quantity = 1,
    required this.availableStock,
  });

  /// Full item name for receipts (e.g. "Aquajaal JAR 20 Ltr - Medium Jar")
  String get displayName {
    if (variantName != null && variantName!.isNotEmpty) {
      return '$productName ($variantName)';
    }
    return productName;
  }

  /// Line total before tax
  double get lineTotal => unitPrice * quantity;

  /// Unique key to identify product + variant combination in cart
  String get cartKey => variantId != null ? '${productId}_$variantId' : productId;

  CartItem copyWith({
    String? productId,
    String? productName,
    String? variantId,
    String? variantName,
    String? hsnCode,
    double? unitPrice,
    int? quantity,
    int? availableStock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      hsnCode: hsnCode ?? this.hsnCode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'variantId': variantId,
    'variantName': variantName,
    'hsnCode': hsnCode,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'availableStock': availableStock,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      hsnCode: json['hsnCode'] as String? ?? '2201',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      availableStock: json['availableStock'] as int? ?? 0,
    );
  }
}
