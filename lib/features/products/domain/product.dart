import 'package:cloud_firestore/cloud_firestore.dart';

import '../../materials/domain/material_item.dart';
import '../../subproducts/domain/subproduct.dart';

class ProductComponent {
  const ProductComponent({
    required this.subproductId,
    required this.quantityPerUnit,
    required this.notes,
  });

  final String subproductId;
  final double quantityPerUnit;
  final String? notes;

  factory ProductComponent.fromMap(Map<String, dynamic> data) {
    return ProductComponent(
      subproductId: data['subproductId'] as String? ?? '',
      quantityPerUnit: (data['quantityPerUnit'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subproductId': subproductId,
      'quantityPerUnit': quantityPerUnit,
      'notes': notes,
    };
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.description,
    required this.outputUnit,
    required this.clientProvidesLona,
    required this.components,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameKey;
  final String? description;
  final String outputUnit;
  final bool clientProvidesLona;
  final List<ProductComponent> components;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawComponents = data['components'] as List<dynamic>? ?? const [];

    return Product(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      nameKey: data['nameKey'] as String? ?? '',
      description: data['description'] as String?,
      outputUnit: data['outputUnit'] as String? ?? '',
      clientProvidesLona: data['clientProvidesLona'] as bool? ?? false,
      components: rawComponents
          .whereType<Map<String, dynamic>>()
          .map(ProductComponent.fromMap)
          .toList(growable: false),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameKey': nameKey,
      'description': description,
      'outputUnit': outputUnit,
      'clientProvidesLona': clientProvidesLona,
      'components': components.map((component) => component.toMap()).toList(growable: false),
      'isActive': isActive,
    };
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}

class ProductComponentCost {
  const ProductComponentCost({
    required this.subproductId,
    required this.subproductName,
    required this.outputUnit,
    required this.quantityPerUnit,
    required this.unitCost,
    required this.subtotal,
    required this.notes,
    required this.isMissing,
  });

  final String subproductId;
  final String subproductName;
  final String outputUnit;
  final double quantityPerUnit;
  final double unitCost;
  final double subtotal;
  final String? notes;
  final bool isMissing;
}

class ProductCostBreakdown {
  const ProductCostBreakdown({
    required this.unitCost,
    required this.componentCosts,
  });

  final double unitCost;
  final List<ProductComponentCost> componentCosts;
}

class ProductCostCalculator {
  const ProductCostCalculator();

  ProductCostBreakdown calculate({
    required List<ProductComponent> components,
    required Map<String, Subproduct> subproductsById,
    required Map<String, MaterialItem> materialsById,
    required Set<String> excludedCategoryIds,
  }) {
    var unitCost = 0.0;
    final componentCosts = <ProductComponentCost>[];

    for (final component in components) {
      final subproduct = subproductsById[component.subproductId];
      if (subproduct == null) {
        componentCosts.add(
          ProductComponentCost(
            subproductId: component.subproductId,
            subproductName: 'Subproducto eliminado',
            outputUnit: '-',
            quantityPerUnit: component.quantityPerUnit,
            unitCost: 0,
            subtotal: 0,
            notes: component.notes,
            isMissing: true,
          ),
        );
        continue;
      }

      final subproductUnitCost = _calculateSubproductCost(
        subproduct: subproduct,
        materialsById: materialsById,
        excludedCategoryIds: excludedCategoryIds,
      );
      final subtotal = component.quantityPerUnit * subproductUnitCost;
      unitCost += subtotal;

      componentCosts.add(
        ProductComponentCost(
          subproductId: subproduct.id,
          subproductName: subproduct.name,
          outputUnit: subproduct.outputUnit,
          quantityPerUnit: component.quantityPerUnit,
          unitCost: subproductUnitCost,
          subtotal: subtotal,
          notes: component.notes,
          isMissing: false,
        ),
      );
    }

    return ProductCostBreakdown(
      unitCost: unitCost,
      componentCosts: componentCosts,
    );
  }

  double _calculateSubproductCost({
    required Subproduct subproduct,
    required Map<String, MaterialItem> materialsById,
    required Set<String> excludedCategoryIds,
  }) {
    var ingredientsCost = 0.0;

    for (final ingredient in subproduct.ingredients) {
      final material = materialsById[ingredient.materialId];
      if (material == null) {
        continue;
      }
      if (excludedCategoryIds.contains(material.categoryId)) {
        continue;
      }

      ingredientsCost += ingredient.quantityPerUnit * material.currentPrice;
    }

    return ingredientsCost + subproduct.fixedCost;
  }
}