import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/material_categories_controller.dart';
import '../domain/material_category.dart';

class MaterialCategoriesPage extends ConsumerWidget {
  const MaterialCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);
    final actionState = ref.watch(materialCategoriesControllerProvider);
    final actionError = actionState.hasError ? actionState.error : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de materias primas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading
            ? null
            : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return Column(
            children: [
              if (actionError != null)
                _ConnectionErrorBanner(message: actionError.toString()),
              Expanded(
                child: categories.isEmpty
                    ? _EmptyState(
                        onCreate: actionState.isLoading ? null : () => _openForm(context, ref),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryCard(
                            category: category,
                            busy: actionState.isLoading,
                            onEdit: () => _openForm(context, ref, category: category),
                            onDelete: () => _confirmDelete(context, ref, category),
                            onToggle: (value) {
                              ref.read(materialCategoriesControllerProvider.notifier).toggleActive(
                                    id: category.id,
                                    isActive: value,
                                  );
                            },
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
            child: Text('No se pudieron cargar las categorías.'),
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    MaterialCategory? category,
  }) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (dialogContext) => _CategoryFormDialog(category: category),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final controller = ref.read(materialCategoriesControllerProvider.notifier);
    final message = category == null
        ? await controller.createCategory(
            name: result.name,
            isActive: result.isActive,
          )
        : await controller.updateCategory(
            id: category.id,
            name: result.name,
            isActive: result.isActive,
          );

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MaterialCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.name}"?'),
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
        .read(materialCategoriesControllerProvider.notifier)
        .deleteCategory(category.id);

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final MaterialCategory category;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(category.name)),
            if (category.isLona) ...[
              const SizedBox(width: 8),
              const _LonaBadge(),
            ],
          ],
        ),
        subtitle: Text(category.isActive ? 'Activa' : 'Inactiva'),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Switch(
              value: category.isActive,
              onChanged: busy ? null : onToggle,
            ),
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

class _LonaBadge extends StatelessWidget {
  const _LonaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'lona',
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
            const Icon(Icons.category_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Aún no hay categorías',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea la primera categoría para clasificar materias primas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormResult {
  const _CategoryFormResult({required this.name, required this.isActive});

  final String name;
  final bool isActive;
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final MaterialCategory? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameController;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nueva categoría' : 'Editar categoría'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              _CategoryFormResult(
                name: _nameController.text.trim(),
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}