import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../subproducts/application/subproducts_controller.dart';
import '../data/product_service.dart';
import '../domain/product.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).watchAll();
});

final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, void>(
  ProductsController.new,
);

class ProductsController extends AsyncNotifier<void> {
  ProductService get _service => ref.read(productServiceProvider);

  @override
  Future<void> build() async {
    await _service.ensureConnected();
  }

  Future<String?> createProduct({
    required String name,
    required String? description,
    required String outputUnit,
    required bool clientProvidesLona,
    required bool isActive,
    required List<ProductComponent> components,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        name: name,
        outputUnit: outputUnit,
        components: components,
      );
      await _service.create(
        name: name,
        description: description,
        outputUnit: outputUnit,
        clientProvidesLona: clientProvidesLona,
        isActive: isActive,
        components: components,
      );
      state = const AsyncData(null);
      return null;
    } on FirebaseException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageForFirebase(error);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageFor(error);
    }
  }

  Future<String?> updateProduct({
    required String id,
    required String name,
    required String? description,
    required String outputUnit,
    required bool clientProvidesLona,
    required bool isActive,
    required List<ProductComponent> components,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        ignoreId: id,
        name: name,
        outputUnit: outputUnit,
        components: components,
      );
      await _service.update(
        id: id,
        name: name,
        description: description,
        outputUnit: outputUnit,
        clientProvidesLona: clientProvidesLona,
        isActive: isActive,
        components: components,
      );
      state = const AsyncData(null);
      return null;
    } on FirebaseException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageForFirebase(error);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageFor(error);
    }
  }

  Future<String?> deleteProduct(String id) async {
    state = const AsyncLoading();

    try {
      await _service.delete(id);
      state = const AsyncData(null);
      return null;
    } on FirebaseException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageForFirebase(error);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageFor(error);
    }
  }

  Future<void> _validatePayload({
    String? ignoreId,
    required String name,
    required String outputUnit,
    required List<ProductComponent> components,
  }) async {
    if (name.trim().isEmpty) {
      throw StateError('El nombre es obligatorio.');
    }
    if (outputUnit.trim().isEmpty) {
      throw StateError('La unidad de salida es obligatoria.');
    }
    if (components.isEmpty) {
      throw StateError('Debes agregar al menos un componente.');
    }

    final subproducts = await ref.read(subproductsStreamProvider.future);
    final subproductsById = {for (final subproduct in subproducts) subproduct.id: subproduct};

    final seenSubproductIds = <String>{};
    for (final component in components) {
      if (component.subproductId.trim().isEmpty) {
        throw StateError('Debes seleccionar un subproducto para cada componente.');
      }
      if (component.quantityPerUnit <= 0) {
        throw StateError('Todas las cantidades deben ser mayores a cero.');
      }
      if (!seenSubproductIds.add(component.subproductId)) {
        throw StateError('Cada subproducto debe aparecer una sola vez por producto.');
      }
      if (!subproductsById.containsKey(component.subproductId)) {
        throw StateError('Algún subproducto ya no existe.');
      }
    }

    final exists = await _service.existsByName(name: name, ignoreId: ignoreId);
    if (exists) {
      throw StateError('Ya existe un producto con ese nombre.');
    }
  }

  String _messageFor(Object error) {
    final text = error.toString();

    if (text.contains('agregar al menos un componente')) {
      return 'Debes agregar al menos un componente.';
    }
    if (text.contains('subproducto debe aparecer una sola vez')) {
      return 'Cada subproducto debe aparecer una sola vez por producto.';
    }
    if (text.contains('subproducto ya no existe')) {
      return 'Algún subproducto ya no existe.';
    }
    if (text.contains('producto con ese nombre')) {
      return 'Ya existe un producto con ese nombre.';
    }
    if (text.contains('obligatorio')) {
      return 'Completa los campos obligatorios.';
    }
    if (text.contains('mayores a cero')) {
      return 'Todas las cantidades deben ser mayores a cero.';
    }
    return 'No se pudo completar la acción. Intenta nuevamente.';
  }

  String _messageForFirebase(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore rechazó la operación. Revisa las reglas de la colección products.';
      case 'unauthenticated':
        return 'La sesión no está autenticada para escribir en Firestore.';
      case 'unavailable':
        return 'Firestore no está disponible en este momento.';
      case 'failed-precondition':
        return 'Firestore requiere una condición previa. Revisa índices o reglas.';
      case 'not-found':
        return 'No se encontró el documento o la colección destino.';
      default:
        return 'Firestore respondió con error ${error.code}. Revisa conexión y reglas.';
    }
  }
}