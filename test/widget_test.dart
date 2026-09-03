import 'package:flutter_test/flutter_test.dart';
import 'package:aquajaal_pos/core/utils/currency_formatter.dart';
import 'package:aquajaal_pos/core/utils/number_to_words.dart';
import 'package:aquajaal_pos/data/models/cart_item.dart';
import 'package:aquajaal_pos/data/services/seed_data.dart';

void main() {
  group('NumberToWords Converter Tests', () {
    test('converts zero amount correctly', () {
      expect(NumberToWords.convert(0), 'Rupees Zero Only');
    });

    test('converts small amounts', () {
      expect(NumberToWords.convert(60), 'Rupees Sixty Only');
      expect(NumberToWords.convert(80), 'Rupees Eighty Only');
      expect(NumberToWords.convert(100), 'Rupees One Hundred Only');
    });

    test('converts composite amounts with hundreds', () {
      expect(NumberToWords.convert(180), 'Rupees One Hundred and Eighty Only');
      expect(NumberToWords.convert(145), 'Rupees One Hundred and Forty Five Only');
    });

    test('converts thousands and lakhs', () {
      expect(NumberToWords.convert(12500), 'Rupees Twelve Thousand Five Hundred Only');
      expect(NumberToWords.convert(100000), 'Rupees One Lakh Only');
    });
  });

  group('CurrencyFormatter Tests', () {
    test('formats strictly with 2 decimal places and Indian grouping', () {
      expect(CurrencyFormatter.format(120), contains('120.00'));
      expect(CurrencyFormatter.format(60), contains('60.00'));
      expect(CurrencyFormatter.format(100000), contains('1,00,000.00'));
      expect(CurrencyFormatter.format(250000.5), contains('2,50,000.50'));
    });

    test('formats compact thousands and lakhs', () {
      expect(CurrencyFormatter.formatCompact(1500), '₹1.5 K');
      expect(CurrencyFormatter.formatCompact(250000), '₹2.5 L');
    });
  });

  group('Seed Catalog Verification', () {
    test('has all required Aquajaal SKUs and exact prices', () {
      final products = SeedData.initialProducts;

      // 1. 20L Jar filling with 3 variants
      final jar20L = products.firstWhere((p) => p.id == 'prod_jar_20l');
      expect(jar20L.hasVariants, true);
      expect(jar20L.variants.length, 3);

      final dimJar = jar20L.variants.firstWhere((v) => v.name == 'Dim Jar');
      expect(dimJar.price, 60.0);

      final medJar = jar20L.variants.firstWhere((v) => v.name == 'Medium Jar');
      expect(medJar.price, 80.0);

      final bestJar = jar20L.variants.firstWhere((v) => v.name == 'Best Jar');
      expect(bestJar.price, 100.0);

      // 2. Aquajaal Premium 2000ml case
      final prem2000 = products.firstWhere((p) => p.id == 'prod_prem_2000ml');
      expect(prem2000.standalonePrice, 120.0);

      // 3. Aquajal SN Shrink Pack 1000ml case
      final sn1000 = products.firstWhere((p) => p.id == 'prod_sn_1000ml');
      expect(sn1000.standalonePrice, 110.0);

      // 4. Aquajal SN Shrink Pack 500ml case
      final sn500 = products.firstWhere((p) => p.id == 'prod_sn_500ml');
      expect(sn500.standalonePrice, 135.0);

      // 5. Aquajal SN Shrink Pack 300ml case
      final sn300 = products.firstWhere((p) => p.id == 'prod_sn_300ml');
      expect(sn300.standalonePrice, 145.0);
    });

    test('verifies opening stock counts are non-zero', () {
      for (final p in SeedData.initialProducts) {
        expect(p.totalStock > 0, true);
      }
    });
  });

  group('CartItem Calculation Tests', () {
    test('line total calculates accurately', () {
      final item = CartItem(
        productId: 'prod_1',
        productName: 'Aquajaal JAR 20 Ltr Filling',
        variantId: 'var_best_jar',
        variantName: 'Best Jar',
        hsnCode: '2201',
        unitPrice: 100.0,
        quantity: 5,
        availableStock: 50,
      );

      expect(item.lineTotal, 500.0);
      expect(item.displayName, 'Aquajaal JAR 20 Ltr Filling (Best Jar)');
    });
  });
}
