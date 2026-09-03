import 'cart_item.dart';

/// Represents a finalized GST Tax Invoice
class Invoice {
  final String id;
  final String invoiceNumber;
  final int invoiceSequence;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final List<CartItem> items;
  final double subtotal;
  final double taxRate; // Percentage e.g. 0.0, 5.0, 18.0
  final double taxAmount;
  final double cgst;
  final double sgst;
  final double discount;
  final double grandTotal;
  final String amountInWords;
  final String paymentMode; // Cash, UPI, Card, Cheque, Credit
  final String paymentStatus; // PAID, PENDING, PARTIAL
  final double? amountPaid;
  final String? notes;
  final String stateName;
  final String stateCode;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceSequence,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.discount = 0.0,
    required this.grandTotal,
    required this.amountInWords,
    this.paymentMode = 'Cash',
    this.paymentStatus = 'PAID',
    this.amountPaid,
    this.notes,
    this.stateName = 'Karnataka',
    this.stateCode = '29',
  });

  /// Total units (jars or cases) in this invoice
  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'invoiceSequence': invoiceSequence,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
    'customerPhone': customerPhone,
    'items': items.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'cgst': cgst,
    'sgst': sgst,
    'discount': discount,
    'grandTotal': grandTotal,
    'amountInWords': amountInWords,
    'paymentMode': paymentMode,
    'paymentStatus': paymentStatus,
    'amountPaid': amountPaid ?? grandTotal,
    'notes': notes,
    'stateName': stateName,
    'stateCode': stateCode,
  };

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceSequence: json['invoiceSequence'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num).toDouble(),
      amountInWords: json['amountInWords'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? 'Cash',
      paymentStatus: json['paymentStatus'] as String? ?? 'PAID',
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      stateName: json['stateName'] as String? ?? 'Karnataka',
      stateCode: json['stateCode'] as String? ?? '29',
    );
  }
}
