import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/material_item.dart';

class MaterialService {
  MaterialService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      _firestore.collection('materials');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('materialCategories');

  Future<void> ensureConnected() async {
    await _materialsCollection.limit(1).get();
  }

  Stream<List<MaterialItem>> watchAll() {
    return _materialsCollection.orderBy('nameKey').snapshots().map(
          (snapshot) => snapshot.docs
              .map(MaterialItem.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> create({
    required String name,
    required String categoryId,
    required String unit,
    required double currentPrice,
    required bool isActive,
    String? notes,
  }) async {
    final normalizedName = _normalize(name);

    await _materialsCollection.add({
      'name': name.trim(),
      'nameKey': normalizedName,
      'categoryId': categoryId,
      'unit': unit.trim(),
      'currentPrice': currentPrice,
      'notes': _cleanOptional(notes),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String categoryId,
    required String unit,
    required double currentPrice,
    required bool isActive,
    String? notes,
  }) async {
    final normalizedName = _normalize(name);

    await _materialsCollection.doc(id).update({
      'name': name.trim(),
      'nameKey': normalizedName,
      'categoryId': categoryId,
      'unit': unit.trim(),
      'currentPrice': currentPrice,
      'notes': _cleanOptional(notes),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return _materialsCollection.doc(id).delete();
  }

  Future<bool> existsByName({required String name, String? ignoreId}) async {
    final normalizedName = _normalize(name);
    final snapshot = await _materialsCollection
        .where('nameKey', isEqualTo: normalizedName)
        .get();

    return snapshot.docs.any((doc) => doc.id != ignoreId);
  }

  Future<void> validateCategoryExists(String categoryId) async {
    final snapshot = await _categoriesCollection.doc(categoryId).get();
    if (!snapshot.exists) {
      throw StateError('La categoría seleccionada no existe.');
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MaterialService(ref.watch(firebaseFirestoreProvider));
});
