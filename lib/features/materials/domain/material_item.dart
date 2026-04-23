import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.categoryId,
    required this.unit,
    required this.currentPrice,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameKey;
  final String categoryId;
  final String unit;
  final double currentPrice;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MaterialItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return MaterialItem(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      nameKey: data['nameKey'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String?,
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
