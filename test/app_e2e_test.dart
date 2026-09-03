import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:aquajaal_pos/data/models/product.dart';
import 'package:aquajaal_pos/data/services/local_db_service.dart';
import 'package:aquajaal_pos/data/services/csv_export_service.dart';
import 'package:aquajaal_pos/providers/pos_provider.dart';
import 'package:aquajaal_pos/providers/stock_provider.dart';
import 'package:aquajaal_pos/providers/sales_provider.dart';
import 'package:aquajaal_pos/providers/theme_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('aquajaal_hive_test_');
    await LocalDbService.instance.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('E2E POS, Invoicing, Stock Deduction, Product Management and CSV Export Test', () async {
    final stockProvider = StockProvider();
    final posProvider = PosProvider();
    final salesProvider = SalesProvider();
    final themeProvider = ThemeProvider();

    // 1. Verify Catalog Seeding
    expect(stockProvider.allProducts.length, 5);

    final jarProduct = stockProvider.findProductById('prod_jar_20l')!;
    expect(jarProduct.hasVariants, true);
    expect(jarProduct.variants.length, 3);

    final medJar = jarProduct.variants.firstWhere((v) => v.name == 'Medium Jar');
    expect(medJar.price, 80.0);
    expect(medJar.stock, 180);

    final premBottle = stockProvider.findProductById('prod_prem_2000ml')!;
    expect(premBottle.standalonePrice, 120.0);
    expect(premBottle.standaloneStock, 75);

    // 2. Add Items to POS Cart
    posProvider.addToCart(jarProduct, variant: medJar, quantity: 2);
    posProvider.addToCart(premBottle, quantity: 1);

    expect(posProvider.totalItemCount, 3);
    // Subtotal: (80 * 2) + (120 * 1) = 280
    expect(posProvider.subtotal, 280.0);
    expect(posProvider.grandTotal, 280.0);
    expect(posProvider.amountInWords, 'Rupees Two Hundred and Eighty Only');

    // 3. Set Customer and Payment details
    posProvider.setCustomerName('Ramesh Kamath');
    posProvider.setCustomerPhone('9845012345');
    posProvider.setPaymentMode('UPI');

    // 4. Validate Stock Availability before sale
    final deficits = posProvider.getItemsExceedingStock(stockProvider);
    expect(deficits.isEmpty, true);

    // 5. Checkout & Generate Invoice (Format: YE-YYYY-MMDD-XXXX)
    final invoice = await posProvider.checkout(stockProvider);

    expect(invoice.invoiceNumber, startsWith('YE-'));
    expect(invoice.invoiceNumber.split('-').length, 4); // YE - YYYY - MMDD - XXXX
    expect(invoice.grandTotal, 280.0);
    expect(invoice.paymentMode, 'UPI');
    expect(invoice.paymentStatus, 'PAID');
    expect(invoice.customerName, 'Ramesh Kamath');
    expect(invoice.items.length, 2);

    // 6. Verify Cart is cleared
    expect(posProvider.totalItemCount, 0);

    // 7. Verify Real-time Stock Deduction
    final updatedJar = stockProvider.findProductById('prod_jar_20l')!;
    final updatedMedJar = updatedJar.variants.firstWhere((v) => v.name == 'Medium Jar');
    expect(updatedMedJar.stock, 178); // 180 - 2 = 178

    final updatedPremBottle = stockProvider.findProductById('prod_prem_2000ml')!;
    expect(updatedPremBottle.standaloneStock, 74); // 75 - 1 = 74

    // 8. Test Product Management: Add a new custom SKU
    final customProduct = Product(
      id: 'prod_custom_dispenser',
      name: 'Aquajaal Tabletop Dispenser Tap',
      category: 'Accessories',
      hsnCode: '8481',
      sku: 'AQJ-DISP-01',
      standalonePrice: 250.0,
      standaloneStock: 20,
      lowStockThreshold: 5,
    );
    await stockProvider.addProduct(customProduct);

    expect(stockProvider.allProducts.length, 6);
    expect(stockProvider.findProductById('prod_custom_dispenser') != null, true);

    // 9. Edit price: Verify old invoice remains unchanged
    final editedBottle = premBottle.copyWith(standalonePrice: 150.0); // was 120
    await stockProvider.updateProduct(editedBottle);

    // Old invoice still has 120.0
    expect(invoice.items.firstWhere((i) => i.productId == 'prod_prem_2000ml').unitPrice, 120.0);
    // Active catalog has new price 150.0
    expect(stockProvider.findProductById('prod_prem_2000ml')!.standalonePrice, 150.0);

    // 10. Test Archive / Reactivate
    await stockProvider.toggleProductActive('prod_custom_dispenser', false);
    expect(stockProvider.activeProducts.any((p) => p.id == 'prod_custom_dispenser'), false);
    expect(stockProvider.archivedProducts.any((p) => p.id == 'prod_custom_dispenser'), true);

    await stockProvider.toggleProductActive('prod_custom_dispenser', true);
    expect(stockProvider.activeProducts.any((p) => p.id == 'prod_custom_dispenser'), true);

    // 11. Test CSV Export Generation with UTF-8 BOM
    final invoicesList = [invoice];
    final csvContent = CsvExportService.generateCsvContent(invoicesList);
    expect(csvContent.startsWith('\uFEFF'), true); // UTF-8 BOM
    expect(csvContent, contains('Invoice #,Date,Time,Customer,Items,Qty,Unit Price,Line Total,Tax %,Tax Amt,Grand Total (₹),Payment Status'));
    expect(csvContent, contains('YE-'));
    expect(csvContent, contains('Ramesh Kamath'));
    expect(csvContent, contains('₹280.00'));

    // 12. Test Sales Analytics Dashboard Metrics & Top 3
    salesProvider.refreshInvoices();
    expect(salesProvider.totalInvoicesCount, 1);
    expect(salesProvider.totalRevenue, 280.0);
    expect(salesProvider.totalUnitsSold, 3);
    expect(salesProvider.averageOrderValue, 280.0);
    expect(salesProvider.top3ByRevenue.isNotEmpty, true);
    expect(salesProvider.top3ByQuantity.isNotEmpty, true);
    expect(salesProvider.dailyBreakdown.isNotEmpty, true);

    // 13. Verify Theme Switcher
    final initialDark = themeProvider.isDarkMode;
    themeProvider.toggleTheme();
    expect(themeProvider.isDarkMode, !initialDark);
  });
}
