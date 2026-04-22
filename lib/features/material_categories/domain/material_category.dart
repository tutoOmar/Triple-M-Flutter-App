import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialCategory {
  const MaterialCategory({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameKey;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLona => nameKey == 'lona';

  factory MaterialCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return MaterialCategory(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      nameKey: data['nameKey'] as String? ?? '',
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
