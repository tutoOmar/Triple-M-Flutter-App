import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/display_number.dart';
import '../../../core/formatting/money_text_input_formatter.dart';
import '../../../core/widgets/app_dialog_transitions.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../material_categories/application/material_categories_controller.dart';
import '../../material_categories/domain/material_category.dart';
import '../application/materials_controller.dart';
import '../domain/material_item.dart';

class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({super.key});

  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);
    final actionState = ref.watch(materialsControllerProvider);
    final actionError = actionState.hasError ? actionState.error : null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Materias primas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva materia prima'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return materialsAsync.when(
            data: (materials) {
              final visibleMaterials = _filterMaterials(materials);

              return Column(
                children: [
                  if (actionError != null)
                    _ConnectionErrorBanner(message: _friendlyError(actionError)),
                  _FiltersBar(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    selectedCategoryId: _selectedCategoryId,
                    categories: categories,
                    onSearchChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                    onCategoryChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  Expanded(
                    child: visibleMaterials.isEmpty
                        ? _EmptyState(
                            onCreate: actionState.isLoading ? null : () => _openForm(context),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleMaterials.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final material = visibleMaterials[index];
                              final categoryName = _categoryName(categories, material.categoryId);
                              return _MaterialCard(
                                material: material,
                                categoryName: categoryName,
                                busy: actionState.isLoading,
                                onEdit: () => _openForm(context, material: material),
                                onDelete: () => _confirmDelete(context, material),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudieron cargar las materias primas.'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudieron cargar las categorías.'),
          ),
        ),
      ),
    );
  }

  List<MaterialItem> _filterMaterials(List<MaterialItem> materials) {
    return materials.where((material) {
      final matchesSearch = _searchQuery.isEmpty ||
          material.name.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedCategoryId == null || material.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList(growable: false);
  }

  String _categoryName(List<MaterialCategory> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return 'Sin categoría';
  }

  Future<void> _openForm(
    BuildContext context, {
    MaterialItem? material,
  }) async {
    final categories = await ref.read(materialCategoriesStreamProvider.future);
    if (!context.mounted) {
      return;
    }

    final result = await showSlidingDialog<_MaterialFormResult>(
      context: context,
      builder: (dialogContext) => _MaterialFormDialog(
        categories: categories,
        material: material,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final controller = ref.read(materialsControllerProvider.notifier);
    final message = material == null
        ? await controller.createMaterial(
            name: result.name,
            categoryId: result.categoryId,
            unit: result.unit,
            currentPrice: result.currentPrice,
            isActive: result.isActive,
            notes: result.notes,
          )
        : await controller.updateMaterial(
            id: material.id,
            name: result.name,
            categoryId: result.categoryId,
            unit: result.unit,
            currentPrice: result.currentPrice,
            isActive: result.isActive,
            notes: result.notes,
          );

    if (message != null && context.mounted) {
      AppToast.showError(context, message);
    } else if (context.mounted) {
      AppToast.showSuccess(context, 'Guardado');
    }
  }

  Future<void> _confirmDelete(BuildContext context, MaterialItem material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar materia prima'),
        content: Text('¿Eliminar "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final message = await ref
        .read(materialsControllerProvider.notifier)
        .deleteMaterial(material.id);

    if (message != null && context.mounted) {
      AppToast.showError(context, message);
      return;
    }

    if (context.mounted) {
      AppToast.showSuccess(context, 'Materia prima eliminada');
      ref.invalidate(materialsStreamProvider);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Firestore rechazó la operación. Revisa las reglas de la colección materials.';
    }
    if (text.contains('unauthenticated')) {
      return 'La sesión no está autenticada para escribir en Firestore.';
    }
    if (text.contains('obligatorio')) {
      return 'Completa los campos obligatorios.';
    }
    return 'No se pudo completar la acción. Intenta nuevamente.';
  }
}

class _ConnectionErrorBanner extends StatelessWidget {
  const _ConnectionErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategoryId;
  final List<MaterialCategory> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Buscar por nombre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: selectedCategoryId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ...categories.map(
                (category) => DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(category.isLona ? '${category.name} (lona)' : category.name),
                ),
              ),
            ],
            onChanged: onCategoryChanged,
            decoration: const InputDecoration(labelText: 'Filtrar por categoría'),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.categoryName,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final MaterialItem material;
  final String categoryName;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(material.name)),
            const SizedBox(width: 8),
            _StatusChip(isActive: material.isActive),
          ],
        ),
        subtitle: Text(
          '$categoryName · ${material.unit} · ${formatDisplayNumber(material.currentPrice)}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Activa' : 'Inactiva',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Aún no hay materias primas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea la primera materia prima para empezar a cargar costos y recetas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Crear materia prima'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialFormResult {
  const _MaterialFormResult({
    required this.name,
    required this.categoryId,
    required this.unit,
    required this.currentPrice,
    required this.isActive,
    required this.notes,
  });

  final String name;
  final String categoryId;
  final String unit;
  final double currentPrice;
  final bool isActive;
  final String? notes;
}

class _MaterialFormDialog extends StatefulWidget {
  const _MaterialFormDialog({
    required this.categories,
    this.material,
  });

  final List<MaterialCategory> categories;
  final MaterialItem? material;

  @override
  State<_MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<_MaterialFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;
  late bool _isActive;
  String? _categoryId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.material?.name ?? '');
    _unitController = TextEditingController(text: widget.material?.unit ?? '');
    _priceController = TextEditingController(
      text: widget.material == null ? '' : formatDisplayNumber(widget.material!.currentPrice, fractionDigits: 0),
    );
    _notesController = TextEditingController(text: widget.material?.notes ?? '');
    _isActive = widget.material?.isActive ?? true;
    _categoryId = widget.material?.categoryId ?? widget.categories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = widget.categories.isNotEmpty;

    return AlertDialog(
      title: Text(widget.material == null ? 'Nueva materia prima' : 'Editar materia prima'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El nombre es obligatorio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.isLona ? '${category.name} (lona)' : category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: hasCategories ? (value) => setState(() => _categoryId = value) : null,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (value) {
                    if (!hasCategories) {
                      return 'Debes crear al menos una categoría.';
                    }
                    if (value == null || value.isEmpty) {
                      return 'La categoría es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Unidad'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'La unidad es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [MoneyTextInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Precio actual'),
                  validator: (value) {
                    final parsed = parseMoneyText(value ?? '');
                    if (parsed == null) {
                      return 'Ingresa un precio válido.';
                    }
                    if (parsed < 0) {
                      return 'El precio debe ser mayor o igual a cero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }

            Navigator.of(context).pop(
              _MaterialFormResult(
                name: _nameController.text.trim(),
                categoryId: _categoryId ?? '',
                unit: _unitController.text.trim(),
                currentPrice: parseMoneyText(_priceController.text)?.toDouble() ?? 0,
                isActive: _isActive,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
