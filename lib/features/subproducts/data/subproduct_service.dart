import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/subproduct.dart';

class SubproductService {
  SubproductService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _subproductsCollection =>
      _firestore.collection('subproducts');

  Future<void> ensureConnected() async {
    await _subproductsCollection.limit(1).get();
  }

  Stream<List<Subproduct>> watchAll() {
    return _subproductsCollection.orderBy('nameKey').snapshots().map(
          (snapshot) => snapshot.docs
              .map(Subproduct.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> create({
    required String name,
    required String outputUnit,
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
    required bool isActive,
    required List<SubproductIngredient> ingredients,
    String? description,
  }) async {
    await _subproductsCollection.add({
      'name': name.trim(),
      'nameKey': _normalize(name),
      'description': _cleanOptional(description),
      'outputUnit': outputUnit.trim(),
      'manufacturaCost': manufacturaCost,
      'patinajejeCost': patinajejeCost,
      'armadoBolsillosCost': armadoBolsillosCost,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(growable: false),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String outputUnit,
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
    required bool isActive,
    required List<SubproductIngredient> ingredients,
    String? description,
  }) async {
    await _subproductsCollection.doc(id).update({
      'name': name.trim(),
      'nameKey': _normalize(name),
      'description': _cleanOptional(description),
      'outputUnit': outputUnit.trim(),
      'manufacturaCost': manufacturaCost,
      'patinajejeCost': patinajejeCost,
      'armadoBolsillosCost': armadoBolsillosCost,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(growable: false),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _subproductsCollection.doc(id).delete();

  Future<bool> existsByName({required String name, String? ignoreId}) async {
    final snapshot = await _subproductsCollection
        .where('nameKey', isEqualTo: _normalize(name))
        .get();

    return snapshot.docs.any((doc) => doc.id != ignoreId);
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

final subproductServiceProvider = Provider<SubproductService>((ref) {
  return SubproductService(ref.watch(firebaseFirestoreProvider));
});
