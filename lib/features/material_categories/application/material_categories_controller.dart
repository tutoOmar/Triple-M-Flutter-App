import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/material_category_service.dart';
import '../domain/material_category.dart';

final materialCategoriesStreamProvider = StreamProvider<List<MaterialCategory>>((ref) {
  return ref.watch(materialCategoryServiceProvider).watchAll();
});

final materialCategoriesControllerProvider =
    AsyncNotifierProvider<MaterialCategoriesController, void>(
  MaterialCategoriesController.new,
);

class MaterialCategoriesController extends AsyncNotifier<void> {
  MaterialCategoryService get _service =>
      ref.read(materialCategoryServiceProvider);

  @override
  Future<void> build() async {
    await _service.ensureConnected();
  }

  Future<String?> createCategory({
    required String name,
    required bool isActive,
  }) async {
    state = const AsyncLoading();

    try {
      await _validateUniqueName(name: name);
      await _service.create(name: name, isActive: isActive);
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

  Future<String?> updateCategory({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    state = const AsyncLoading();

    try {
      await _validateUniqueName(name: name, ignoreId: id);
      await _service.update(id: id, name: name, isActive: isActive);
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

  Future<String?> deleteCategory(String id) async {
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

  Future<String?> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    state = const AsyncLoading();

    try {
      await _service.setActive(id: id, isActive: isActive);
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

  Future<void> _validateUniqueName({
    required String name,
    String? ignoreId,
  }) async {
    if (name.trim().isEmpty) {
      throw StateError('El nombre es obligatorio.');
    }

    final exists = await _service.existsByName(name: name, ignoreId: ignoreId);
    if (exists) {
      throw StateError('Ya existe una categoría con ese nombre.');
    }
  }

  String _messageFor(Object error) {
    final text = error.toString();

    if (text.contains('obligatorio')) {
      return 'El nombre es obligatorio.';
    }
    if (text.contains('categoría con ese nombre')) {
      return 'Ya existe una categoría con ese nombre.';
    }
    if (text.contains('ya está usada por materias primas')) {
      return 'No se puede eliminar porque ya está usada por materias primas.';
    }
    return 'No se pudo completar la acción. Intenta nuevamente.';
  }

  String _messageForFirebase(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore rechazó la operación. Revisa las reglas de lectura/escritura de la colección materialCategories.';
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
