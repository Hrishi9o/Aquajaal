/// Record for tracking every inventory addition, deduction, or adjustment
class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final int quantityDelta; // Positive for inward stock, negative for sales/breakage
  final String type; // 'intake', 'sale', 'adjustment'
  final String? reference; // Invoice Number or Supplier Batch
  final int previousStock;
  final int newStock;
  final String? notes;
  final DateTime timestamp;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.quantityDelta,
    required this.type,
    this.reference,
    required this.previousStock,
    required this.newStock,
    this.notes,
    required this.timestamp,
  });

  String get itemDisplayName {
    if (variantName != null && variantName!.isNotEmpty) {
      return '$productName ($variantName)';
    }
    return productName;
  }

  bool get isPositive => quantityDelta > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'variantId': variantId,
    'variantName': variantName,
    'quantityDelta': quantityDelta,
    'type': type,
    'reference': reference,
    'previousStock': previousStock,
    'newStock': newStock,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      quantityDelta: json['quantityDelta'] as int,
      type: json['type'] as String,
      reference: json['reference'] as String?,
      previousStock: json['previousStock'] as int,
      newStock: json['newStock'] as int,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
