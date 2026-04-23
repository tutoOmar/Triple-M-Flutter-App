import 'package:flutter_test/flutter_test.dart';

import 'package:mi_app/features/materials/domain/material_item.dart';
import 'package:mi_app/features/material_categories/domain/material_category.dart';
import 'package:mi_app/features/products/domain/product.dart';
import 'package:mi_app/features/subproducts/domain/subproduct.dart';

void main() {
  group('ProductCostCalculator', () {
    test('excluye la categoría lona cuando clientProvidesLona está activo', () {
      final lonaCategory = MaterialCategory(
        id: 'lona',
        name: 'Lona',
        nameKey: 'lona',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final otherCategory = MaterialCategory(
        id: 'otros',
        name: 'Otros',
        nameKey: 'otros',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final lonaMaterial = MaterialItem(
        id: 'material-lona',
        name: 'Lona 14 oz',
        nameKey: 'lona-14-oz',
        categoryId: lonaCategory.id,
        unit: 'metro',
        currentPrice: 10,
        notes: null,
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );
      final otherMaterial = MaterialItem(
        id: 'material-hilo',
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
        id: 'subproduct-1',
        name: 'Panel',
        nameKey: 'panel',
        description: null,
        outputUnit: 'pieza',
        manufacturaCost: 3,
        patinajejeCost: 2,
        armadoBolsillosCost: 1,
        ingredients: const [
          SubproductIngredient(materialId: 'material-lona', quantityPerUnit: 2, notes: null),
          SubproductIngredient(materialId: 'material-hilo', quantityPerUnit: 1, notes: null),
        ],
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      const calculator = ProductCostCalculator();
      final breakdown = calculator.calculate(
        components: const [
          ProductComponent(subproductId: 'subproduct-1', quantityPerUnit: 2, notes: null),
        ],
        subproductsById: {'subproduct-1': subproduct},
        materialsById: {
          lonaMaterial.id: lonaMaterial,
          otherMaterial.id: otherMaterial,
        },
        excludedCategoryIds: {lonaCategory.id},
      );

      expect(breakdown.componentCosts, hasLength(1));
      expect(breakdown.componentCosts.first.isMissing, isFalse);
      expect(breakdown.componentCosts.first.unitCost, 11);
      expect(breakdown.componentCosts.first.subtotal, 22);
      expect(breakdown.unitCost, 22);
    });

    test('marca como faltante un subproducto eliminado', () {
      const calculator = ProductCostCalculator();

      final breakdown = calculator.calculate(
        components: const [
          ProductComponent(subproductId: 'missing', quantityPerUnit: 1, notes: null),
        ],
        subproductsById: const {},
        materialsById: const {},
        excludedCategoryIds: const {},
      );

      expect(breakdown.unitCost, 0);
      expect(breakdown.componentCosts, hasLength(1));
      expect(breakdown.componentCosts.first.isMissing, isTrue);
      expect(breakdown.componentCosts.first.subproductName, 'Subproducto eliminado');
    });
  });
}