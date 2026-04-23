import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/material_service.dart';
import '../domain/material_item.dart';

final materialsStreamProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(materialServiceProvider).watchAll();
});

final materialsControllerProvider =
    AsyncNotifierProvider<MaterialsController, void>(
  MaterialsController.new,
);

class MaterialsController extends AsyncNotifier<void> {
  MaterialService get _service => ref.read(materialServiceProvider);

  @override
  Future<void> build() async {
    await _service.ensureConnected();
  }

  Future<String?> createMaterial({
    required String name,
    required String categoryId,
    required String unit,
    required double currentPrice,
    required bool isActive,
    String? notes,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        name: name,
        categoryId: categoryId,
        unit: unit,
        currentPrice: currentPrice,
      );
      await _service.create(
        name: name,
        categoryId: categoryId,
        unit: unit,
        currentPrice: currentPrice,
        isActive: isActive,
        notes: notes,
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

  Future<String?> updateMaterial({
    required String id,
    required String name,
    required String categoryId,
    required String unit,
    required double currentPrice,
    required bool isActive,
    String? notes,
  }) async {
    state = const AsyncLoading();

    try {
      await _validatePayload(
        ignoreId: id,
        name: name,
        categoryId: categoryId,
        unit: unit,
        currentPrice: currentPrice,
      );
      await _service.update(
        id: id,
        name: name,
        categoryId: categoryId,
        unit: unit,
        currentPrice: currentPrice,
        isActive: isActive,
        notes: notes,
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

  Future<String?> deleteMaterial(String id) async {
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
    required String categoryId,
    required String unit,
    required double currentPrice,
  }) async {
    if (name.trim().isEmpty) {
      throw StateError('El nombre es obligatorio.');
    }
    if (categoryId.trim().isEmpty) {
      throw StateError('La categoría es obligatoria.');
    }
    if (unit.trim().isEmpty) {
      throw StateError('La unidad es obligatoria.');
    }
    if (currentPrice < 0) {
      throw StateError('El precio actual debe ser mayor o igual a cero.');
    }

    final nameExists = await _service.existsByName(name: name, ignoreId: ignoreId);
    if (nameExists) {
      throw StateError('Ya existe una materia prima con ese nombre.');
    }

    await _service.validateCategoryExists(categoryId);
  }

  String _messageFor(Object error) {
    final text = error.toString();

    if (text.contains('obligatorio')) {
      return 'Completa los campos obligatorios.';
    }
    if (text.contains('materia prima con ese nombre')) {
      return 'Ya existe una materia prima con ese nombre.';
    }
    if (text.contains('categoría seleccionada no existe')) {
      return 'La categoría seleccionada no existe.';
    }
    return 'No se pudo completar la acción. Intenta nuevamente.';
  }

  String _messageForFirebase(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore rechazó la operación. Revisa las reglas de la colección materials.';
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
