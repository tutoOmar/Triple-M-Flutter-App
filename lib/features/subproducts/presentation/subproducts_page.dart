import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/display_number.dart';
import '../../../core/formatting/money_text_input_formatter.dart';
import '../../../core/widgets/app_dialog_transitions.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../material_categories/application/material_categories_controller.dart';
import '../../material_categories/domain/material_category.dart';
import '../../materials/application/materials_controller.dart';
import '../../materials/domain/material_item.dart';
import '../application/subproducts_controller.dart';
import '../domain/subproduct.dart';

class SubproductsPage extends ConsumerWidget {
  const SubproductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subproductsAsync = ref.watch(subproductsStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);
    final actionState = ref.watch(subproductsControllerProvider);
    final actionError = actionState.hasError ? actionState.error : null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Subproductos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo subproducto'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return materialsAsync.when(
            data: (materials) {
              return subproductsAsync.when(
                data: (subproducts) {
                  final materialsById = {for (final material in materials) material.id: material};
                  final categoryNamesById = {for (final category in categories) category.id: category.name};

                  return Column(
                    children: [
                      if (actionError != null)
                        _ConnectionErrorBanner(message: _friendlyError(actionError)),
                      Expanded(
                        child: subproducts.isEmpty
                            ? _EmptyState(
                                onCreate: actionState.isLoading ? null : () => _openForm(context, ref),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: subproducts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final subproduct = subproducts[index];
                                  final breakdown = const SubproductCostCalculator().calculate(
                                    ingredients: subproduct.ingredients,
                                    materialsById: materialsById,
                                    categoryNamesById: categoryNamesById,
                                    manufacturaCost: subproduct.manufacturaCost,
                                    patinajejeCost: subproduct.patinajejeCost,
                                    armadoBolsillosCost: subproduct.armadoBolsillosCost,
                                  );

                                  return _SubproductCard(
                                    subproduct: subproduct,
                                    breakdown: breakdown,
                                    categoriesById: categoryNamesById,
                                    materialsById: materialsById,
                                    busy: actionState.isLoading,
                                    onEdit: () => _openForm(context, ref, subproduct: subproduct),
                                    onDelete: () => _confirmDelete(context, ref, subproduct),
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
                    child: Text('No se pudieron cargar los subproductos.'),
                  ),
                ),
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

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Subproduct? subproduct,
  }) async {
    final materials = await ref.read(materialsStreamProvider.future);
    final categories = await ref.read(materialCategoriesStreamProvider.future);

    if (!context.mounted) {
      return;
    }

    final result = await showSlidingDialog<_SubproductFormResult>(
      context: context,
      builder: (dialogContext) => _SubproductFormDialog(
        materials: materials,
        categories: categories,
        subproduct: subproduct,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final controller = ref.read(subproductsControllerProvider.notifier);
    final message = subproduct == null
        ? await controller.createSubproduct(
            name: result.name,
            description: result.description,
            outputUnit: result.outputUnit,
            manufacturaCost: result.manufacturaCost,
            patinajejeCost: result.patinajejeCost,
            armadoBolsillosCost: result.armadoBolsillosCost,
            isActive: result.isActive,
            ingredients: result.ingredients,
          )
        : await controller.updateSubproduct(
            id: subproduct.id,
            name: result.name,
            description: result.description,
            outputUnit: result.outputUnit,
            manufacturaCost: result.manufacturaCost,
            patinajejeCost: result.patinajejeCost,
            armadoBolsillosCost: result.armadoBolsillosCost,
            isActive: result.isActive,
            ingredients: result.ingredients,
          );

    if (message != null && context.mounted) {
      AppToast.showError(context, message);
    } else if (context.mounted) {
      AppToast.showSuccess(context, 'Guardado');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subproduct subproduct,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar subproducto'),
        content: Text('¿Eliminar "${subproduct.name}"?'),
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

    final message = await ref.read(subproductsControllerProvider.notifier).deleteSubproduct(subproduct.id);

    if (message != null && context.mounted) {
      AppToast.showError(context, message);
      return;
    }

    if (context.mounted) {
      AppToast.showSuccess(context, 'Subproducto eliminado');
      ref.invalidate(subproductsStreamProvider);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Firestore rechazó la operación. Revisa las reglas de la colección subproducts.';
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

class _SubproductCard extends StatelessWidget {
  const _SubproductCard({
    required this.subproduct,
    required this.breakdown,
    required this.categoriesById,
    required this.materialsById,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final Subproduct subproduct;
  final SubproductCostBreakdown breakdown;
  final Map<String, String> categoriesById;
  final Map<String, MaterialItem> materialsById;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Flexible(child: Text(subproduct.name)),
            const SizedBox(width: 8),
            _StatusChip(isActive: subproduct.isActive),
          ],
        ),
        subtitle: Text(
          '${subproduct.outputUnit} · Costo ${formatDisplayNumber(breakdown.totalCost)}',
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
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (subproduct.description != null && subproduct.description!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(subproduct.description!),
              ),
            ),
          _CostSummary(breakdown: breakdown),
          const SizedBox(height: 12),
          Text('Material', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...breakdown.ingredientCosts.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.materialName),
              subtitle: Text(
                '${formatDisplayNumber(item.quantityPerUnit)} ${item.unit} x ${formatDisplayNumber(item.unitPrice)} = ${formatDisplayNumber(item.subtotal)}'
                '${item.categoryName == null ? '' : ' · ${item.categoryName}'}',
              ),
              trailing: item.isMissing ? const Icon(Icons.warning_amber_outlined) : null,
            ),
          ),
        ],
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

class _CostSummary extends StatelessWidget {
  const _CostSummary({required this.breakdown});

  final SubproductCostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Costo de materiales: ${formatDisplayNumber(breakdown.ingredientsCost)}'),
          Text('Costos fijos: ${formatDisplayNumber(breakdown.fixedCost)}'),
          const SizedBox(height: 4),
          Text(
            'Costo total: ${formatDisplayNumber(breakdown.totalCost)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
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
            const Icon(Icons.view_agenda_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Aún no hay subproductos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea el primero para definir recetas y costos fijos de fabricación.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Crear subproducto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubproductFormResult {
  const _SubproductFormResult({
    required this.name,
    required this.description,
    required this.outputUnit,
    required this.manufacturaCost,
    required this.patinajejeCost,
    required this.armadoBolsillosCost,
    required this.isActive,
    required this.ingredients,
  });

  final String name;
  final String? description;
  final String outputUnit;
  final double manufacturaCost;
  final double patinajejeCost;
  final double armadoBolsillosCost;
  final bool isActive;
  final List<SubproductIngredient> ingredients;
}

class _IngredientDraft {
  _IngredientDraft({
    this.materialId,
    String quantityText = '',
    String notesText = '',
  })  : materialFocusNode = FocusNode(),
        quantityController = TextEditingController(text: quantityText),
        notesController = TextEditingController(text: notesText);

  String? materialId;
  final FocusNode materialFocusNode;
  final TextEditingController quantityController;
  final TextEditingController notesController;

  void dispose() {
    materialFocusNode.dispose();
    quantityController.dispose();
    notesController.dispose();
  }
}

class _SubproductFormDialog extends StatefulWidget {
  const _SubproductFormDialog({
    required this.materials,
    required this.categories,
    this.subproduct,
  });

  final List<MaterialItem> materials;
  final List<MaterialCategory> categories;
  final Subproduct? subproduct;

  @override
  State<_SubproductFormDialog> createState() => _SubproductFormDialogState();
}

class _SubproductFormDialogState extends State<_SubproductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _outputUnitController;
  late final TextEditingController _manufacturaController;
  late final TextEditingController _patinajejeController;
  late final TextEditingController _armadoBolsillosController;
  late final ScrollController _formScrollController;
  late bool _isActive;
  late final List<_IngredientDraft> _ingredients;
  String? _formError;
  final _formKey = GlobalKey<FormState>();
  final _calculator = const SubproductCostCalculator();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subproduct?.name ?? '');
    _descriptionController = TextEditingController(text: widget.subproduct?.description ?? '');
    _outputUnitController = TextEditingController(text: widget.subproduct?.outputUnit ?? '');
    _manufacturaController = TextEditingController(text: _moneyText(widget.subproduct?.manufacturaCost));
    _patinajejeController = TextEditingController(text: _moneyText(widget.subproduct?.patinajejeCost));
    _armadoBolsillosController = TextEditingController(text: _moneyText(widget.subproduct?.armadoBolsillosCost));
    _formScrollController = ScrollController();
    _isActive = widget.subproduct?.isActive ?? true;
    _ingredients = widget.subproduct?.ingredients
            .map(
              (ingredient) => _IngredientDraft(
                materialId: ingredient.materialId,
                quantityText: ingredient.quantityPerUnit.toString(),
                notesText: ingredient.notes ?? '',
              ),
            )
            .toList(growable: true) ??
        <_IngredientDraft>[];
    if (_ingredients.isEmpty) {
      _ingredients.add(_IngredientDraft());
    }
    for (final draft in _ingredients) {
      draft.quantityController.addListener(_onFieldChanged);
      draft.notesController.addListener(_onFieldChanged);
    }
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _outputUnitController.addListener(_onFieldChanged);
    _manufacturaController.addListener(_onFieldChanged);
    _patinajejeController.addListener(_onFieldChanged);
    _armadoBolsillosController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _outputUnitController.dispose();
    _manufacturaController.dispose();
    _patinajejeController.dispose();
    _armadoBolsillosController.dispose();
    _formScrollController.dispose();
    for (final draft in _ingredients) {
      draft.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialsById = {for (final material in widget.materials) material.id: material};
    final categoriesById = {for (final category in widget.categories) category.id: category.name};
    final breakdown = _previewBreakdown(materialsById, categoriesById);
    final isNarrowLayout = MediaQuery.sizeOf(context).width < 600;

    return AlertDialog(
      title: Text(widget.subproduct == null ? 'Nuevo subproducto' : 'Editar subproducto'),
      content: SizedBox(
        width: 780,
        child: SingleChildScrollView(
          controller: _formScrollController,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_formError != null) ...[
                  _InlineFormError(message: _formError!),
                  const SizedBox(height: 12),
                ],
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _outputUnitController,
                  decoration: const InputDecoration(labelText: 'Unidad de salida'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'La unidad de salida es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                isNarrowLayout
                    ? Column(
                        children: [
                          TextFormField(
                            controller: _manufacturaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [MoneyTextInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Coste manufactura'),
                            validator: _integerValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _patinajejeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [MoneyTextInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Coste patinaje'),
                            validator: _integerValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _armadoBolsillosController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [MoneyTextInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Coste armado bolsillos'),
                            validator: _integerValidator,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _manufacturaController,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [MoneyTextInputFormatter()],
                              decoration: const InputDecoration(labelText: 'Coste manufactura'),
                              validator: _integerValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _patinajejeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [MoneyTextInputFormatter()],
                              decoration: const InputDecoration(labelText: 'Coste patinaje'),
                              validator: _integerValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _armadoBolsillosController,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [MoneyTextInputFormatter()],
                              decoration: const InputDecoration(labelText: 'Coste armado bolsillos'),
                              validator: _integerValidator,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Materiales', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: () {
                        final draft = _IngredientDraft();
                        setState(() {
                          draft.quantityController.addListener(_onFieldChanged);
                          draft.notesController.addListener(_onFieldChanged);
                          _ingredients.add(draft);
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }
                          FocusScope.of(context).requestFocus(draft.materialFocusNode);
                          _scrollToBottom();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Material'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.materials.isEmpty)
                  const _InlineFormError(
                    message: 'Debes crear materias primas antes de crear subproductos.',
                  )
                else
                  ..._ingredients.asMap().entries.map(
                    (entry) => _IngredientRow(
                      index: entry.key,
                      draft: entry.value,
                      materials: widget.materials,
                      categoryNamesById: categoriesById,
                      onRemove: _ingredients.length == 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _ingredients.removeAt(entry.key);
                                removed.dispose();
                              });
                            },
                      onChanged: _onFieldChanged,
                    ),
                  ),
                const SizedBox(height: 16),
                _SubproductPreviewCard(breakdown: breakdown),
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
          onPressed: widget.materials.isEmpty
              ? null
              : () {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  final ingredients = <SubproductIngredient>[];
                  final seenMaterialIds = <String>{};
                  for (final draft in _ingredients) {
                    final materialId = draft.materialId;
                    final parsedQuantity = double.tryParse(draft.quantityController.text.replaceAll(',', '.'));

                    if (materialId == null || materialId.isEmpty) {
                      setState(() => _formError = 'Debes seleccionar una materia prima en cada ingrediente.');
                      return;
                    }
                    if (parsedQuantity == null || parsedQuantity <= 0) {
                      setState(() => _formError = 'Cada ingrediente debe tener una cantidad mayor a cero.');
                      return;
                    }
                    if (!seenMaterialIds.add(materialId)) {
                      setState(() => _formError = 'Cada materia prima debe aparecer una sola vez por receta.');
                      return;
                    }

                    ingredients.add(
                      SubproductIngredient(
                        materialId: materialId,
                        quantityPerUnit: parsedQuantity,
                        notes: draft.notesController.text.trim().isEmpty
                            ? null
                            : draft.notesController.text.trim(),
                      ),
                    );
                  }

                  if (ingredients.isEmpty) {
                    setState(() => _formError = 'La receta no puede estar vacía.');
                    return;
                  }

                  Navigator.of(context).pop(
                    _SubproductFormResult(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                      outputUnit: _outputUnitController.text.trim(),
                      manufacturaCost: parseMoneyText(_manufacturaController.text)?.toDouble() ?? 0,
                      patinajejeCost: parseMoneyText(_patinajejeController.text)?.toDouble() ?? 0,
                      armadoBolsillosCost: parseMoneyText(_armadoBolsillosController.text)?.toDouble() ?? 0,
                      isActive: _isActive,
                      ingredients: ingredients,
                    ),
                  );
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String? _integerValidator(String? value) {
    final parsed = parseMoneyText(value ?? '');
    if (parsed == null) {
      return 'Ingresa un número válido.';
    }
    if (parsed < 0) {
      return 'El valor debe ser mayor o igual a cero.';
    }
    return null;
  }

  SubproductCostBreakdown _previewBreakdown(
    Map<String, MaterialItem> materialsById,
    Map<String, String> categoriesById,
  ) {
    final ingredients = _ingredients
        .where((draft) => draft.materialId != null && draft.materialId!.isNotEmpty)
        .map(
          (draft) => SubproductIngredient(
            materialId: draft.materialId!,
            quantityPerUnit: double.tryParse(draft.quantityController.text.replaceAll(',', '.')) ?? 0,
            notes: draft.notesController.text.trim().isEmpty ? null : draft.notesController.text.trim(),
          ),
        )
        .toList(growable: false);

    return _calculator.calculate(
      ingredients: ingredients,
      materialsById: materialsById,
      categoryNamesById: categoriesById,
      manufacturaCost: parseMoneyText(_manufacturaController.text)?.toDouble() ?? 0,
      patinajejeCost: parseMoneyText(_patinajejeController.text)?.toDouble() ?? 0,
      armadoBolsillosCost: parseMoneyText(_armadoBolsillosController.text)?.toDouble() ?? 0,
    );
  }

  String _moneyText(double? value) {
    if (value == null) {
      return '';
    }
    return formatDisplayNumber(value, fractionDigits: 0);
  }

  void _scrollToBottom() {
    if (!_formScrollController.hasClients) {
      return;
    }
    _formScrollController.animateTo(
      _formScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.index,
    required this.draft,
    required this.materials,
    required this.categoryNamesById,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _IngredientDraft draft;
  final List<MaterialItem> materials;
  final Map<String, String> categoryNamesById;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Ingrediente ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            DropdownButtonFormField<String?>(
              initialValue: draft.materialId,
              focusNode: draft.materialFocusNode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Materia prima'),
              items: materials
                  .map(
                    (material) => DropdownMenuItem<String?>(
                      value: material.id,
                      child: Text(
                        _materialLabel(material, categoryNamesById),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                draft.materialId = value;
                onChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona una materia prima.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: draft.quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad por unidad'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                if (parsed == null) {
                  return 'Ingresa una cantidad válida.';
                }
                if (parsed <= 0) {
                  return 'La cantidad debe ser mayor a cero.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  String _materialLabel(MaterialItem material, Map<String, String> categoryNamesById) {
    final categoryName = categoryNamesById[material.categoryId];
    final baseLabel = material.name;
    if (categoryName == null) {
      return baseLabel;
    }
    return baseLabel;
  }
}

class _SubproductPreviewCard extends StatelessWidget {
  const _SubproductPreviewCard({required this.breakdown});

  final SubproductCostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Previsualización de costo', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text('Materiales: ${formatDisplayNumber(breakdown.ingredientsCost)}'),
          Text('Costos fijos: ${formatDisplayNumber(breakdown.fixedCost)}'),
          Text(
            'Total: ${formatDisplayNumber(breakdown.totalCost)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _InlineFormError extends StatelessWidget {
  const _InlineFormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
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
