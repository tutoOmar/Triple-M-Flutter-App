import 'package:flutter_test/flutter_test.dart';

import 'package:mi_app/features/material_categories/domain/material_category.dart';
import 'package:mi_app/features/materials/domain/material_item.dart';
import 'package:mi_app/features/products/domain/product.dart';
import 'package:mi_app/features/simulator/domain/production_simulation.dart';
import 'package:mi_app/features/subproducts/domain/subproduct.dart';

void main() {
  group('ProductionSimulatorCalculator', () {
    test('expande subproductos y materiales con exclusión de lona', () {
      final lonaCategory = MaterialCategory(
        id: 'lona',
        name: 'Lona',
        nameKey: 'lona',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final otherCategory = MaterialCategory(
        id: 'otro',
        name: 'Otro',
        nameKey: 'otro',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final lonaMaterial = MaterialItem(
        id: 'mat-lona',
        name: 'Lona',
        nameKey: 'lona',
        categoryId: lonaCategory.id,
        unit: 'metro',
        currentPrice: 10,
        notes: null,
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final threadMaterial = MaterialItem(
        id: 'mat-hilo',
        name: 'Hilo',
        nameKey: 'hilo',
        categoryId: otherCategory.id,
        unit: 'pieza',
        currentPrice: 5,
        notes: null,
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final subproduct = Subproduct(
        id: 'sub-1',
        name: 'Panel',
        nameKey: 'panel',
        description: null,
        outputUnit: 'pieza',
        manufacturaCost: 3,
        patinajejeCost: 2,
        armadoBolsillosCost: 1,
        ingredients: const [
          SubproductIngredient(materialId: 'mat-lona', quantityPerUnit: 2, notes: null),
          SubproductIngredient(materialId: 'mat-hilo', quantityPerUnit: 1, notes: null),
        ],
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final product = Product(
        id: 'prod-1',
        name: 'Producto',
        nameKey: 'producto',
        description: null,
        outputUnit: 'pieza',
        clientProvidesLona: true,
        components: const [
          ProductComponent(subproductId: 'sub-1', quantityPerUnit: 2, notes: null),
        ],
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      const calculator = ProductionSimulatorCalculator();
      final breakdown = calculator.calculate(
        product: product,
        quantity: 3,
        subproductsById: {'sub-1': subproduct},
        materialsById: {
          lonaMaterial.id: lonaMaterial,
          threadMaterial.id: threadMaterial,
        },
        categoryNamesById: {
          lonaCategory.id: lonaCategory.name,
          otherCategory.id: otherCategory.name,
        },
        excludedCategoryIds: {lonaCategory.id},
      );

      expect(breakdown.unitCost, 22);
      expect(breakdown.totalCost, 66);
      expect(breakdown.subproducts, hasLength(1));
      expect(breakdown.subproducts.first.unitCost, 11);
      expect(breakdown.materials, hasLength(1));
      expect(breakdown.materials.first.materialName, 'Hilo');
      expect(breakdown.materials.first.quantity, 6);
      expect(breakdown.materials.first.subtotal, 30);
    });

    test('devuelve costo cero para un producto sin componentes', () {
      final product = Product(
        id: 'prod-empty',
        name: 'Vacio',
        nameKey: 'vacio',
        description: null,
        outputUnit: 'pieza',
        clientProvidesLona: false,
        components: const [],
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      const calculator = ProductionSimulatorCalculator();
      final breakdown = calculator.calculate(
        product: product,
        quantity: 5,
        subproductsById: const {},
        materialsById: const {},
        categoryNamesById: const {},
        excludedCategoryIds: const {},
      );

      expect(breakdown.unitCost, 0);
      expect(breakdown.totalCost, 0);
      expect(breakdown.subproducts, isEmpty);
      expect(breakdown.materials, isEmpty);
    });
  });
}