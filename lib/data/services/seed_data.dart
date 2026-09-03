import '../models/product.dart';
import '../models/stock_movement.dart';

/// Pre-seeded catalog items and initial inventory as specified by business requirements
class SeedData {
  SeedData._();

  static List<Product> get initialProducts => [
    // 1. Aquajaal JAR 20 Ltr Filling (3 Variants)
    Product(
      id: 'prod_jar_20l',
      name: 'Aquajaal JAR 20 Ltr Filling',
      category: '20L Jars',
      hsnCode: '2201',
      description: '20 Litre returnable mineral water jar filling for commercial and home dispensers',
      hasVariants: true,
      variants: [
        ProductVariant(
          id: 'var_dim_jar',
          name: 'Dim Jar',
          price: 60.0,
          stock: 120,
          lowStockThreshold: 25,
        ),
        ProductVariant(
          id: 'var_med_jar',
          name: 'Medium Jar',
          price: 80.0,
          stock: 180,
          lowStockThreshold: 30,
        ),
        ProductVariant(
          id: 'var_best_jar',
          name: 'Best Jar',
          price: 100.0,
          stock: 95,
          lowStockThreshold: 20,
        ),
      ],
    ),

    // 2. Aquajaal Premium 2000ml (2L bottle case)
    Product(
      id: 'prod_prem_2000ml',
      name: 'Aquajaal Premium 2000ml (2L bottle case)',
      category: 'Packaged Bottles',
      hsnCode: '2201',
      description: 'Case pack of 2 Litre premium mineral water bottles',
      hasVariants: false,
      standalonePrice: 120.0,
      standaloneStock: 75,
      lowStockThreshold: 15,
    ),

    // 3. Aquajal SN Shrink Pack 1000ml (1L bottle case)
    Product(
      id: 'prod_sn_1000ml',
      name: 'Aquajal SN Shrink Pack 1000ml (1L bottle case)',
      category: 'Packaged Bottles',
      hsnCode: '2201',
      description: 'Shrink-wrapped wholesale case of 1000ml (1L) mineral drinking water bottles',
      hasVariants: false,
      standalonePrice: 110.0,
      standaloneStock: 140,
      lowStockThreshold: 25,
    ),

    // 4. Aquajal SN Shrink Pack 500ml (0.5L bottle case)
    Product(
      id: 'prod_sn_500ml',
      name: 'Aquajal SN Shrink Pack 500ml (0.5L bottle case)',
      category: 'Packaged Bottles',
      hsnCode: '2201',
      description: 'Shrink-wrapped wholesale case of 500ml (0.5L) mineral drinking water bottles',
      hasVariants: false,
      standalonePrice: 135.0,
      standaloneStock: 85,
      lowStockThreshold: 20,
    ),

    // 5. Aquajal SN Shrink Pack 300ml (300ml pet bottle case)
    Product(
      id: 'prod_sn_300ml',
      name: 'Aquajal SN Shrink Pack 300ml (300ml pet bottle case)',
      category: 'Packaged Bottles',
      hsnCode: '2201',
      description: 'Shrink-wrapped event & catering case of 300ml mini PET mineral water bottles',
      hasVariants: false,
      standalonePrice: 145.0,
      standaloneStock: 110,
      lowStockThreshold: 20,
    ),
  ];

  static List<StockMovement> get initialStockMovements {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return [
      StockMovement(
        id: 'seed_init_1',
        productId: 'prod_jar_20l',
        productName: 'Aquajaal JAR 20 Ltr Filling',
        variantId: 'var_dim_jar',
        variantName: 'Dim Jar',
        quantityDelta: 120,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 120,
        notes: 'Opening stock count at counter opening',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_2',
        productId: 'prod_jar_20l',
        productName: 'Aquajaal JAR 20 Ltr Filling',
        variantId: 'var_med_jar',
        variantName: 'Medium Jar',
        quantityDelta: 180,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 180,
        notes: 'Opening stock count at counter opening',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_3',
        productId: 'prod_jar_20l',
        productName: 'Aquajaal JAR 20 Ltr Filling',
        variantId: 'var_best_jar',
        variantName: 'Best Jar',
        quantityDelta: 95,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 95,
        notes: 'Opening stock count at counter opening',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_4',
        productId: 'prod_prem_2000ml',
        productName: 'Aquajaal Premium 2000ml (2L bottle case)',
        quantityDelta: 75,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 75,
        notes: 'Opening stock count',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_5',
        productId: 'prod_sn_1000ml',
        productName: 'Aquajal SN Shrink Pack 1000ml (1L bottle case)',
        quantityDelta: 140,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 140,
        notes: 'Opening stock count',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_6',
        productId: 'prod_sn_500ml',
        productName: 'Aquajal SN Shrink Pack 500ml (0.5L bottle case)',
        quantityDelta: 85,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 85,
        notes: 'Opening stock count',
        timestamp: now,
      ),
      StockMovement(
        id: 'seed_init_7',
        productId: 'prod_sn_300ml',
        productName: 'Aquajal SN Shrink Pack 300ml (300ml pet bottle case)',
        quantityDelta: 110,
        type: 'intake',
        reference: 'Initial Stock Intake',
        previousStock: 0,
        newStock: 110,
        notes: 'Opening stock count',
        timestamp: now,
      ),
    ];
  }
}
