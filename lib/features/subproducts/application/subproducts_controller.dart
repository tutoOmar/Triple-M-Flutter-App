import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../materials/application/materials_controller.dart';
import '../data/subproduct_service.dart';
import '../domain/subproduct.dart';

final subproductsStreamProvider = StreamProvider<List<Subproduct>>((ref) {
  return ref.watch(subproductServiceProvider).watchAll();
});

final subproductsControllerProvider =
    AsyncNotifierProvider<SubproductsController, void>(
  SubproductsController.new,
);

class SubproductsController extends AsyncNotifier<void> {
  SubproductService get _service => ref.read(subproductServiceProvider);

  @override
  Future<void> build() async {
    await _service.ensureConnected();
  }

  Future<String?> createSubproduct({
    required String name,
    required String? description,
    required String outputUnit,
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
    required bool isActive,
    required List<SubproductIngredient> ingredients,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        name: name,
        outputUnit: outputUnit,
        manufacturaCost: manufacturaCost,
        patinajejeCost: patinajejeCost,
        armadoBolsillosCost: armadoBolsillosCost,
        ingredients: ingredients,
      );
      await _service.create(
        name: name,
        description: description,
        outputUnit: outputUnit,
        manufacturaCost: manufacturaCost,
        patinajejeCost: patinajejeCost,
        armadoBolsillosCost: armadoBolsillosCost,
        isActive: isActive,
        ingredients: ingredients,
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

  Future<String?> updateSubproduct({
    required String id,
    required String name,
    required String? description,
    required String outputUnit,
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
    required bool isActive,
    required List<SubproductIngredient> ingredients,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        ignoreId: id,
        name: name,
        outputUnit: outputUnit,
        manufacturaCost: manufacturaCost,
        patinajejeCost: patinajejeCost,
        armadoBolsillosCost: armadoBolsillosCost,
        ingredients: ingredients,
      );
      await _service.update(
        id: id,
        name: name,
        description: description,
        outputUnit: outputUnit,
        manufacturaCost: manufacturaCost,
        patinajejeCost: patinajejeCost,
        armadoBolsillosCost: armadoBolsillosCost,
        isActive: isActive,
        ingredients: ingredients,
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

  Future<String?> deleteSubproduct(String id) async {
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
    required double manufacturaCost,
    required double patinajejeCost,
    required double armadoBolsillosCost,
    required List<SubproductIngredient> ingredients,
  }) async {
    if (name.trim().isEmpty) {
      throw StateError('El nombre es obligatorio.');
    }
    if (outputUnit.trim().isEmpty) {
      throw StateError('La unidad de salida es obligatoria.');
    }
    if (manufacturaCost < 0 || patinajejeCost < 0 || armadoBolsillosCost < 0) {
      throw StateError('Los costos fijos deben ser mayores o iguales a cero.');
    }
    if (ingredients.isEmpty) {
      throw StateError('La receta no puede estar vacía.');
    }

    final materials = await ref.read(materialsStreamProvider.future);
    final materialsById = {for (final material in materials) material.id: material};

    final seenMaterialIds = <String>{};
    for (final ingredient in ingredients) {
      if (ingredient.materialId.trim().isEmpty) {
        throw StateError('Debes seleccionar una materia prima para cada ingrediente.');
      }
      if (ingredient.quantityPerUnit <= 0) {
        throw StateError('Todas las cantidades deben ser mayores a cero.');
      }
      if (!seenMaterialIds.add(ingredient.materialId)) {
        throw StateError('Cada materia prima debe aparecer una sola vez por receta.');
      }
      if (!materialsById.containsKey(ingredient.materialId)) {
        throw StateError('Alguna materia prima ya no existe.');
      }
    }

    final exists = await _service.existsByName(name: name, ignoreId: ignoreId);
    if (exists) {
      throw StateError('Ya existe un subproducto con ese nombre.');
    }
  }

  String _messageFor(Object error) {
    final text = error.toString();

    if (text.contains('receta no puede estar vacía')) {
      return 'La receta no puede estar vacía.';
    }
    if (text.contains('materia prima con ese nombre')) {
      return 'Ya existe un subproducto con ese nombre.';
    }
    if (text.contains('cada materia prima debe aparecer una sola vez')) {
      return 'Cada materia prima debe aparecer una sola vez por receta.';
    }
    if (text.contains('alguna materia prima ya no existe')) {
      return 'Alguna materia prima ya no existe.';
    }
    if (text.contains('obligatorio')) {
      return 'Completa los campos obligatorios.';
    }
    if (text.contains('mayores o iguales a cero')) {
      return 'Los costos deben ser mayores o iguales a cero.';
    }
    return 'No se pudo completar la acción. Intenta nuevamente.';
  }

  String _messageForFirebase(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore rechazó la operación. Revisa las reglas de la colección subproducts.';
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
