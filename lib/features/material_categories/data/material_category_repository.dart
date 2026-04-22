import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/material_category.dart';

class MaterialCategoryRepository {
  MaterialCategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('materialCategories');

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      _firestore.collection('materials');

  Stream<List<MaterialCategory>> watchAll() {
    return _categoriesCollection
        .orderBy('nameKey')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MaterialCategory.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> create({
    required String name,
    required bool isActive,
  }) async {
    final normalizedName = _normalize(name);

    await _categoriesCollection.add({
      'name': name.trim(),
      'nameKey': normalizedName,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    final normalizedName = _normalize(name);

    await _categoriesCollection.doc(id).update({
      'name': name.trim(),
      'nameKey': normalizedName,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    final reference = await _materialsCollection
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();

    if (reference.docs.isNotEmpty) {
      throw StateError(
        'No se puede eliminar la categoría porque ya está usada por materias primas.',
      );
    }

    await _categoriesCollection.doc(id).delete();
  }

  Future<void> setActive({
    required String id,
    required bool isActive,
  }) {
    return _categoriesCollection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> existsByName({required String name, String? ignoreId}) async {
    final normalizedName = _normalize(name);
    final snapshot = await _categoriesCollection
        .where('nameKey', isEqualTo: normalizedName)
        .get();

    return snapshot.docs.any((doc) => doc.id != ignoreId);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

final materialCategoryRepositoryProvider = Provider<MaterialCategoryRepository>((ref) {
  return MaterialCategoryRepository(ref.watch(firebaseFirestoreProvider));
});
