import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/product.dart';

class ProductService {
  ProductService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  Future<void> ensureConnected() async {
    await _productsCollection.limit(1).get();
  }

  Stream<List<Product>> watchAll() {
    return _productsCollection.orderBy('nameKey').snapshots().map(
          (snapshot) => snapshot.docs
              .map(Product.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> create({
    required String name,
    required String outputUnit,
    required bool clientProvidesLona,
    required bool isActive,
    required List<ProductComponent> components,
    String? description,
  }) async {
    final normalizedName = _normalize(name);

    await _productsCollection.add({
      'name': name.trim(),
      'nameKey': normalizedName,
      'description': _cleanOptional(description),
      'outputUnit': outputUnit.trim(),
      'clientProvidesLona': clientProvidesLona,
      'components': components.map((component) => component.toMap()).toList(growable: false),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String outputUnit,
    required bool clientProvidesLona,
    required bool isActive,
    required List<ProductComponent> components,
    String? description,
  }) async {
    await _productsCollection.doc(id).update({
      'name': name.trim(),
      'nameKey': _normalize(name),
      'description': _cleanOptional(description),
      'outputUnit': outputUnit.trim(),
      'clientProvidesLona': clientProvidesLona,
      'components': components.map((component) => component.toMap()).toList(growable: false),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _productsCollection.doc(id).delete();

  Future<bool> existsByName({required String name, String? ignoreId}) async {
    final snapshot = await _productsCollection
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

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(firebaseFirestoreProvider));
});