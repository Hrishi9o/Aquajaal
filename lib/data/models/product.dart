import '../../core/utils/currency_formatter.dart';

/// Represents a variant of a product (e.g. Dim Jar, Medium Jar, Best Jar)
class ProductVariant {
  final String id;
  final String name;
  final double price;
  int stock;
  final int lowStockThreshold;
  final String? sku;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.lowStockThreshold = 10,
    this.sku,
  });

  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'stock': stock,
    'lowStockThreshold': lowStockThreshold,
    'sku': sku,
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      sku: json['sku'] as String?,
    );
  }

  ProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    int? lowStockThreshold,
    String? sku,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      sku: sku ?? this.sku,
    );
  }
}

/// Product Entity supporting standalone items and variant-based product lines
class Product {
  final String id;
  final String name;
  final String category; // 'Jars', 'Cases', 'Bottles'
  final String hsnCode;
  final String? sku;
  final String? description;
  final bool hasVariants;
  final List<ProductVariant> variants;
  final double? standalonePrice;
  int standaloneStock;
  final int lowStockThreshold;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    this.hsnCode = '2201',
    this.sku,
    this.description,
    this.hasVariants = false,
    this.variants = const [],
    this.standalonePrice,
    this.standaloneStock = 0,
    this.lowStockThreshold = 10,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Total available stock across variants or standalone
  int get totalStock {
    if (hasVariants) {
      return variants.fold(0, (sum, v) => sum + v.stock);
    }
    return standaloneStock;
  }

  /// Price display string (e.g. ₹60 – ₹100 or ₹120.00)
  String get priceDisplay {
    if (hasVariants && variants.isNotEmpty) {
      final prices = variants.map((v) => v.price).toList()..sort();
      if (prices.first == prices.last) {
        return CurrencyFormatter.format(prices.first);
      }
      final minStr = prices.first % 1 == 0 ? '₹${prices.first.toInt()}' : CurrencyFormatter.format(prices.first);
      final maxStr = prices.last % 1 == 0 ? '₹${prices.last.toInt()}' : CurrencyFormatter.format(prices.last);
      return '$minStr – $maxStr';
    }
    return CurrencyFormatter.format(standalonePrice ?? 0);
  }

  bool get isLowStock {
    if (hasVariants) {
      return variants.any((v) => v.isLowStock || v.isOutOfStock);
    }
    return standaloneStock > 0 && standaloneStock <= lowStockThreshold;
  }

  bool get isOutOfStock {
    if (hasVariants) {
      return variants.every((v) => v.isOutOfStock);
    }
    return standaloneStock <= 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'hsnCode': hsnCode,
    'sku': sku,
    'description': description,
    'hasVariants': hasVariants,
    'variants': variants.map((v) => v.toJson()).toList(),
    'standalonePrice': standalonePrice,
    'standaloneStock': standaloneStock,
    'lowStockThreshold': lowStockThreshold,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General',
      hsnCode: json['hsnCode'] as String? ?? '2201',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      hasVariants: json['hasVariants'] as bool? ?? false,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v as Map)))
              .toList() ??
          [],
      standalonePrice: (json['standalonePrice'] as num?)?.toDouble(),
      standaloneStock: json['standaloneStock'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? hsnCode,
    String? sku,
    String? description,
    bool? hasVariants,
    List<ProductVariant>? variants,
    double? standalonePrice,
    int? standaloneStock,
    int? lowStockThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      hsnCode: hsnCode ?? this.hsnCode,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      standalonePrice: standalonePrice ?? this.standalonePrice,
      standaloneStock: standaloneStock ?? this.standaloneStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
