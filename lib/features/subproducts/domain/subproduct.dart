import 'package:cloud_firestore/cloud_firestore.dart';

class SubproductIngredient {
  const SubproductIngredient({
    required this.materialId,
    required this.quantityPerUnit,
    required this.notes,
  });

  final String materialId;
  final double quantityPerUnit;
  final String? notes;

  factory SubproductIngredient.fromMap(Map<String, dynamic> data) {
    return SubproductIngredient(
      materialId: data['materialId'] as String? ?? '',
      quantityPerUnit: (data['quantityPerUnit'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'quantityPerUnit': quantityPerUnit,
      'notes': notes,
    };
  }
}

class Subproduct {
  const Subproduct({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.description,
    required this.outputUnit,
    required this.manufacturaCost,
    required this.patinajejeCost,
    required this.armadoBolsillosCost,
    required this.ingredients,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameKey;
  final String? description;
  final String outputUnit;
  final double manufacturaCost;
  final double patinajejeCost;
  final double armadoBolsillosCost;
  final List<SubproductIngredient> ingredients;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get fixedCost => manufacturaCost + patinajejeCost + armadoBolsillosCost;

  factory Subproduct.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    final rawIngredients = data['ingredients'] as List<dynamic>? ?? const [];

    return Subproduct(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      nameKey: data['nameKey'] as String? ?? '',
      description: data['description'] as String?,
      outputUnit: data['outputUnit'] as String? ?? '',
      manufacturaCost: (data['manufacturaCost'] as num?)?.toDouble() ?? 0,
      patinajejeCost: (data['patinajejeCost'] as num?)?.toDouble() ?? 0,
      armadoBolsillosCost: (data['armadoBolsillosCost'] as num?)?.toDouble() ?? 0,
      ingredients: rawIngredients
          .whereType<Map<String, dynamic>>()
          .map(SubproductIngredient.fromMap)
          .toList(growable: false),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}

class SubproductIngredientCost {
  const SubproductIngredientCost({
    required this.materialId,
    required this.materialName,
    required this.categoryName,
    required this.quantityPerUnit,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    required this.isMissing,
  });

  final String materialId;
  final String materialName;
  final String? categoryName;
  final double quantityPerUnit;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final bool isMissing;
}

class SubproductCostBreakdown {
  const SubproductCostBreakdown({
    required this.ingredientsCost,
    required this.fixedCost,
    required this.totalCost,
    required this.ingredientCosts,
  });

  final double ingredientsCost;
  final double fixedCost;
  final double totalCost;
  final List<SubproductIngredientCost> ingredientCosts;
}

class SubproductCostCalculator {
  const SubproductCostCalculator();

  SubproductCostBreakdown calculate({
    required List<SubproductIngredient> ingredients,
    required Map<String, dynamic> materialsById,
    required Map<String, String> categoryNamesById,
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
  }) {
    var ingredientsCost = 0.0;
    final ingredientCosts = <SubproductIngredientCost>[];

    for (final ingredient in ingredients) {
      final material = materialsById[ingredient.materialId];
      final isMissing = material == null;
      final materialName = isMissing ? 'Materia prima eliminada' : material.name as String;
      final unit = isMissing ? '-' : material.unit as String;
      final unitPrice = isMissing ? 0.0 : (material.currentPrice as num).toDouble();
      final subtotal = ingredient.quantityPerUnit * unitPrice;

      ingredientsCost += subtotal;
      ingredientCosts.add(
        SubproductIngredientCost(
          materialId: ingredient.materialId,
          materialName: materialName,
          categoryName: isMissing
              ? null
              : categoryNamesById[(material.categoryId as String?) ?? ''],
          quantityPerUnit: ingredient.quantityPerUnit,
          unit: unit,
          unitPrice: unitPrice,
          subtotal: subtotal,
          isMissing: isMissing,
        ),
      );
    }

    final fixedCost = manufacturaCost + patinajejeCost + armadoBolsillosCost;
    return SubproductCostBreakdown(
      ingredientsCost: ingredientsCost,
      fixedCost: fixedCost,
      totalCost: ingredientsCost + fixedCost,
      ingredientCosts: ingredientCosts,
    );
  }
}
