import '../../materials/domain/material_item.dart';
import '../../products/domain/product.dart';
import '../../subproducts/domain/subproduct.dart';

class ProductionSimulationMaterialEntry {
  const ProductionSimulationMaterialEntry({
    required this.materialId,
    required this.materialName,
    required this.categoryName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.isMissing,
  });

  final String materialId;
  final String materialName;
  final String? categoryName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final bool isMissing;
}

class ProductionSimulationIngredientEntry {
  const ProductionSimulationIngredientEntry({
    required this.materialId,
    required this.materialName,
    required this.categoryName,
    required this.unit,
    required this.quantityPerSubproductUnit,
    required this.quantityForSimulation,
    required this.unitPrice,
    required this.subtotal,
    required this.isMissing,
  });

  final String materialId;
  final String materialName;
  final String? categoryName;
  final String unit;
  final double quantityPerSubproductUnit;
  final double quantityForSimulation;
  final double unitPrice;
  final double subtotal;
  final bool isMissing;
}

class ProductionSimulationSubproductEntry {
  const ProductionSimulationSubproductEntry({
    required this.subproductId,
    required this.subproductName,
    required this.outputUnit,
    required this.quantityPerProductUnit,
    required this.quantityForSimulation,
    required this.ingredientsCost,
    required this.fixedCost,
    required this.unitCost,
    required this.subtotal,
    required this.ingredients,
    required this.isMissing,
  });

  final String subproductId;
  final String subproductName;
  final String outputUnit;
  final double quantityPerProductUnit;
  final double quantityForSimulation;
  final double ingredientsCost;
  final double fixedCost;
  final double unitCost;
  final double subtotal;
  final List<ProductionSimulationIngredientEntry> ingredients;
  final bool isMissing;
}

class ProductionSimulationBreakdown {
  const ProductionSimulationBreakdown({
    required this.productId,
    required this.productName,
    required this.outputUnit,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.subproducts,
    required this.materials,
  });

  final String productId;
  final String productName;
  final String outputUnit;
  final double quantity;
  final double unitCost;
  final double totalCost;
  final List<ProductionSimulationSubproductEntry> subproducts;
  final List<ProductionSimulationMaterialEntry> materials;
}

class ProductionSimulatorCalculator {
  const ProductionSimulatorCalculator();

  ProductionSimulationBreakdown calculate({
    required Product product,
    required double quantity,
    required Map<String, Subproduct> subproductsById,
    required Map<String, MaterialItem> materialsById,
    required Map<String, String> categoryNamesById,
    required Set<String> excludedCategoryIds,
  }) {
    final materialTotals = <String, _MaterialAccumulator>{};
    final subproductEntries = <ProductionSimulationSubproductEntry>[];
    var totalCost = 0.0;

    for (final component in product.components) {
      final subproduct = subproductsById[component.subproductId];
      final quantityForSimulation = component.quantityPerUnit * quantity;

      if (subproduct == null) {
        subproductEntries.add(
          ProductionSimulationSubproductEntry(
            subproductId: component.subproductId,
            subproductName: 'Subproducto eliminado',
            outputUnit: '-',
            quantityPerProductUnit: component.quantityPerUnit,
            quantityForSimulation: quantityForSimulation,
            ingredientsCost: 0,
            fixedCost: 0,
            unitCost: 0,
            subtotal: 0,
            ingredients: const [],
            isMissing: true,
          ),
        );
        continue;
      }

      var ingredientsCost = 0.0;
      final ingredientEntries = <ProductionSimulationIngredientEntry>[];

      for (final ingredient in subproduct.ingredients) {
        final material = materialsById[ingredient.materialId];
        if (material != null && excludedCategoryIds.contains(material.categoryId)) {
          continue;
        }

        final quantityForMaterial = ingredient.quantityPerUnit * quantityForSimulation;

        if (material == null) {
          ingredientEntries.add(
            ProductionSimulationIngredientEntry(
              materialId: ingredient.materialId,
              materialName: 'Materia prima eliminada',
              categoryName: null,
              unit: '-',
              quantityPerSubproductUnit: ingredient.quantityPerUnit,
              quantityForSimulation: quantityForMaterial,
              unitPrice: 0,
              subtotal: 0,
              isMissing: true,
            ),
          );
          _accumulateMaterial(
            materialTotals,
            materialId: ingredient.materialId,
            materialName: 'Materia prima eliminada',
            categoryName: null,
            unit: '-',
            quantity: quantityForMaterial,
            unitPrice: 0,
            subtotal: 0,
            isMissing: true,
          );
          continue;
        }

        final subtotal = quantityForMaterial * material.currentPrice;
        ingredientsCost += ingredient.quantityPerUnit * material.currentPrice;

        ingredientEntries.add(
          ProductionSimulationIngredientEntry(
            materialId: material.id,
            materialName: material.name,
            categoryName: categoryNamesById[material.categoryId],
            unit: material.unit,
            quantityPerSubproductUnit: ingredient.quantityPerUnit,
            quantityForSimulation: quantityForMaterial,
            unitPrice: material.currentPrice,
            subtotal: subtotal,
            isMissing: false,
          ),
        );

        _accumulateMaterial(
          materialTotals,
          materialId: material.id,
          materialName: material.name,
          categoryName: categoryNamesById[material.categoryId],
          unit: material.unit,
          quantity: quantityForMaterial,
          unitPrice: material.currentPrice,
          subtotal: subtotal,
          isMissing: false,
        );
      }

      final fixedCost = subproduct.fixedCost;
      final unitCost = ingredientsCost + fixedCost;
      final subtotal = unitCost * quantityForSimulation;
      totalCost += subtotal;

      subproductEntries.add(
        ProductionSimulationSubproductEntry(
          subproductId: subproduct.id,
          subproductName: subproduct.name,
          outputUnit: subproduct.outputUnit,
          quantityPerProductUnit: component.quantityPerUnit,
          quantityForSimulation: quantityForSimulation,
          ingredientsCost: ingredientsCost,
          fixedCost: fixedCost,
          unitCost: unitCost,
          subtotal: subtotal,
          ingredients: ingredientEntries,
          isMissing: false,
        ),
      );
    }

    return ProductionSimulationBreakdown(
      productId: product.id,
      productName: product.name,
      outputUnit: product.outputUnit,
      quantity: quantity,
      unitCost: quantity == 0 ? 0 : totalCost / quantity,
      totalCost: totalCost,
      subproducts: subproductEntries,
      materials: materialTotals.values.map((entry) => entry.toEntry()).toList(growable: false),
    );
  }

  void _accumulateMaterial(
    Map<String, _MaterialAccumulator> materialTotals, {
    required String materialId,
    required String materialName,
    required String? categoryName,
    required String unit,
    required double quantity,
    required double unitPrice,
    required double subtotal,
    required bool isMissing,
  }) {
    final existing = materialTotals[materialId];
    if (existing == null) {
      materialTotals[materialId] = _MaterialAccumulator(
        materialId: materialId,
        materialName: materialName,
        categoryName: categoryName,
        unit: unit,
        quantity: quantity,
        unitPrice: unitPrice,
        subtotal: subtotal,
        isMissing: isMissing,
      );
      return;
    }

    existing.quantity += quantity;
    existing.subtotal += subtotal;
  }
}

class _MaterialAccumulator {
  _MaterialAccumulator({
    required this.materialId,
    required this.materialName,
    required this.categoryName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.isMissing,
  });

  final String materialId;
  final String materialName;
  final String? categoryName;
  final String unit;
  double quantity;
  final double unitPrice;
  double subtotal;
  final bool isMissing;

  ProductionSimulationMaterialEntry toEntry() {
    return ProductionSimulationMaterialEntry(
      materialId: materialId,
      materialName: materialName,
      categoryName: categoryName,
      unit: unit,
      quantity: quantity,
      unitPrice: unitPrice,
      subtotal: subtotal,
      isMissing: isMissing,
    );
  }
}