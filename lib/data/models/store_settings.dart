/// Store configuration and billing settings
class StoreSettings {
  final String distributorName;
  final String distributorAddress;
  final String distributorCity;
  final String stateName;
  final String stateCode;
  final String gstin;
  final String phone;
  final String email;
  final double defaultTaxRate;
  final int defaultLowStockThreshold;
  final bool allowNegativeStockSale;
  final String invoicePrefix;
  final int nextInvoiceSequence;
  final bool isDarkMode;

  StoreSettings({
    this.distributorName = 'YASHODHAR ENTERPRISES',
    this.distributorAddress = 'Shirva Rishali Complex, Main Road',
    this.distributorCity = 'Shirva, Udupi Dist – 574116',
    this.stateName = 'Karnataka',
    this.stateCode = '29',
    this.gstin = '',
    this.phone = '+91 98450 12345',
    this.email = 'info@yashodharenterprises.com',
    this.defaultTaxRate = 0.0,
    this.defaultLowStockThreshold = 10,
    this.allowNegativeStockSale = true,
    this.invoicePrefix = 'YE',
    this.nextInvoiceSequence = 1,
    this.isDarkMode = false,
  });

  StoreSettings copyWith({
    String? distributorName,
    String? distributorAddress,
    String? distributorCity,
    String? stateName,
    String? stateCode,
    String? gstin,
    String? phone,
    String? email,
    double? defaultTaxRate,
    int? defaultLowStockThreshold,
    bool? allowNegativeStockSale,
    String? invoicePrefix,
    int? nextInvoiceSequence,
    bool? isDarkMode,
  }) {
    return StoreSettings(
      distributorName: distributorName ?? this.distributorName,
      distributorAddress: distributorAddress ?? this.distributorAddress,
      distributorCity: distributorCity ?? this.distributorCity,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      gstin: gstin ?? this.gstin,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultLowStockThreshold: defaultLowStockThreshold ?? this.defaultLowStockThreshold,
      allowNegativeStockSale: allowNegativeStockSale ?? this.allowNegativeStockSale,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceSequence: nextInvoiceSequence ?? this.nextInvoiceSequence,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'distributorName': distributorName,
    'distributorAddress': distributorAddress,
    'distributorCity': distributorCity,
    'stateName': stateName,
    'stateCode': stateCode,
    'gstin': gstin,
    'phone': phone,
    'email': email,
    'defaultTaxRate': defaultTaxRate,
    'defaultLowStockThreshold': defaultLowStockThreshold,
    'allowNegativeStockSale': allowNegativeStockSale,
    'invoicePrefix': invoicePrefix,
    'nextInvoiceSequence': nextInvoiceSequence,
    'isDarkMode': isDarkMode,
  };

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      distributorName: json['distributorName'] as String? ?? 'YASHODHAR ENTERPRISES',
      distributorAddress: json['distributorAddress'] as String? ?? 'Shirva Rishali Complex, Main Road',
      distributorCity: json['distributorCity'] as String? ?? 'Shirva, Udupi Dist – 574116',
      stateName: json['stateName'] as String? ?? 'Karnataka',
      stateCode: json['stateCode'] as String? ?? '29',
      gstin: json['gstin'] as String? ?? '',
      phone: json['phone'] as String? ?? '+91 98450 12345',
      email: json['email'] as String? ?? 'info@yashodharenterprises.com',
      defaultTaxRate: (json['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      defaultLowStockThreshold: json['defaultLowStockThreshold'] as int? ?? 10,
      allowNegativeStockSale: json['allowNegativeStockSale'] as bool? ?? true,
      invoicePrefix: json['invoicePrefix'] as String? ?? 'YE',
      nextInvoiceSequence: json['nextInvoiceSequence'] as int? ?? 1,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );
  }
}
