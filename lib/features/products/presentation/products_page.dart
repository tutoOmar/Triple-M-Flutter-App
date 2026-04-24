import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/display_number.dart';
import '../../../core/formatting/money_text_input_formatter.dart';
import '../../../core/widgets/app_dialog_transitions.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../material_categories/application/material_categories_controller.dart';
import '../../material_categories/domain/material_category.dart';
import '../../materials/application/materials_controller.dart';
import '../../materials/domain/material_item.dart';
import '../../subproducts/application/subproducts_controller.dart';
import '../../subproducts/domain/subproduct.dart';
import '../application/products_controller.dart';
import '../domain/product.dart';

const _productCostCalculator = ProductCostCalculator();

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final subproductsAsync = ref.watch(subproductsStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);
    final actionState = ref.watch(productsControllerProvider);
    final actionError = actionState.hasError ? actionState.error : null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Productos finales'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return materialsAsync.when(
            data: (materials) {
              return subproductsAsync.when(
                data: (subproducts) {
                  return productsAsync.when(
                    data: (products) {
                      final materialsById = {
                        for (final material in materials) material.id: material,
                      };
                      final subproductsById = {
                        for (final subproduct in subproducts) subproduct.id: subproduct,
                      };
                      final excludedCategoryIds = categories
                          .where((category) => category.isLona)
                          .map((category) => category.id)
                          .toSet();
                      final filteredProducts = products.where((product) {
                        if (_searchQuery.isEmpty) {
                          return true;
                        }
                        return product.nameKey.contains(_searchQuery);
                      }).toList(growable: false);

                      return Column(
                        children: [
                          if (actionError != null)
                            _ConnectionErrorBanner(message: _friendlyError(actionError)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Buscar productos',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () => _searchController.clear(),
                                        icon: const Icon(Icons.clear),
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: filteredProducts.isEmpty
                                ? _ProductsEmptyState(
                                    hasQuery: _searchQuery.isNotEmpty,
                                    onCreate: actionState.isLoading ? null : () => _openForm(context, ref),
                                    onClearSearch: _searchQuery.isEmpty ? null : () => _searchController.clear(),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredProducts.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final product = filteredProducts[index];
                                      final breakdown = _productCostCalculator.calculate(
                                        components: product.components,
                                        subproductsById: subproductsById,
                                        materialsById: materialsById,
                                        excludedCategoryIds: product.clientProvidesLona
                                            ? excludedCategoryIds
                                            : const <String>{},
                                      );

                                      return _ProductCard(
                                        product: product,
                                        breakdown: breakdown,
                                        busy: actionState.isLoading,
                                        onOpenDetail: () => context.push('/products/${product.id}'),
                                        onEdit: () => _openForm(context, ref, product: product),
                                        onDelete: () => _confirmDelete(context, ref, product),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No se pudieron cargar los productos.'),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No se pudieron cargar los subproductos.'),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No se pudieron cargar las materias primas.'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se pudieron cargar las categorías.'),
          ),
        ),
      ),
    );
  }
}

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final subproductsAsync = ref.watch(subproductsStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);
    final actionState = ref.watch(productsControllerProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) {
          return materialsAsync.when(
            data: (materials) {
              return subproductsAsync.when(
                data: (subproducts) {
                  return productsAsync.when(
                    data: (products) {
                      Product? product;
                      for (final item in products) {
                        if (item.id == widget.productId) {
                          product = item;
                          break;
                        }
                      }

                      if (product == null) {
                        return Scaffold(
                          appBar: AppBar(
                            leading: const AppBackButton(),
                            title: const Text('Detalle del producto'),
                          ),
                          body: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No se encontró el producto solicitado.'),
                            ),
                          ),
                        );
                      }

                      final currentProduct = product;

                      final materialsById = {
                        for (final material in materials) material.id: material,
                      };
                      final subproductsById = {
                        for (final subproduct in subproducts) subproduct.id: subproduct,
                      };
                      final excludedCategoryIds = categories
                          .where((category) => category.isLona)
                          .map((category) => category.id)
                          .toSet();
                      final breakdown = _productCostCalculator.calculate(
                        components: currentProduct.components,
                        subproductsById: subproductsById,
                        materialsById: materialsById,
                        excludedCategoryIds: currentProduct.clientProvidesLona
                            ? excludedCategoryIds
                            : const <String>{},
                      );
                      final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
                      final hasValidQuantity = quantity > 0;
                      final totalForQuantity = hasValidQuantity ? breakdown.unitCost * quantity : null;

                      return Scaffold(
                        appBar: AppBar(
                          leading: const AppBackButton(),
                          title: const Text('Detalle del producto'),
                          actions: [
                            IconButton(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => context.push('/simulator?productId=${currentProduct.id}'),
                              icon: const Icon(Icons.play_arrow_outlined),
                            ),
                            IconButton(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => _openForm(context, ref, product: currentProduct),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => _confirmDelete(context, ref, currentProduct),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProductSummaryCard(product: currentProduct, breakdown: breakdown),
                              const SizedBox(height: 16),
                              _ProductComponentsCard(product: currentProduct, breakdown: breakdown),
                              const SizedBox(height: 16),
                              _QuickSimulationCard(
                                quantityController: _quantityController,
                                breakdown: breakdown,
                                totalForQuantity: totalForQuantity,
                                product: currentProduct,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No se pudo cargar el producto.'),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No se pudieron cargar los subproductos.'),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No se pudieron cargar las materias primas.'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se pudieron cargar las categorías.'),
          ),
        ),
      ),
    );
  }
}

Future<void> _openForm(
  BuildContext context,
  WidgetRef ref, {
  Product? product,
}) async {
  final subproducts = await ref.read(subproductsStreamProvider.future);
  final materials = await ref.read(materialsStreamProvider.future);
  final categories = await ref.read(materialCategoriesStreamProvider.future);

  if (!context.mounted) {
    return;
  }

  final result = await showSlidingDialog<_ProductFormResult>(
    context: context,
    builder: (dialogContext) => _ProductFormDialog(
      subproducts: subproducts,
      materials: materials,
      categories: categories,
      product: product,
    ),
  );

  if (result == null || !context.mounted) {
    return;
  }

  final controller = ref.read(productsControllerProvider.notifier);
  final message = product == null
      ? await controller.createProduct(
          name: result.name,
          description: result.description,
          outputUnit: result.outputUnit,
          salePrice: result.salePrice,
          clientProvidesLona: result.clientProvidesLona,
          isActive: result.isActive,
          components: result.components,
        )
      : await controller.updateProduct(
          id: product.id,
          name: result.name,
          description: result.description,
          outputUnit: result.outputUnit,
          salePrice: result.salePrice,
          clientProvidesLona: result.clientProvidesLona,
          isActive: result.isActive,
          components: result.components,
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
  Product product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar producto'),
      content: Text('¿Eliminar "${product.name}"?'),
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

  final message = await ref.read(productsControllerProvider.notifier).deleteProduct(product.id);
  if (message != null && context.mounted) {
    AppToast.showError(context, message);
  } else if (context.mounted) {
    AppToast.showSuccess(context, 'Producto eliminado');
    context.go('/products');
  }
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Firestore rechazó la operación. Revisa las reglas de la colección products.';
  }
  if (text.contains('unauthenticated')) {
    return 'La sesión no está autenticada para escribir en Firestore.';
  }
  if (text.contains('obligatorio')) {
    return 'Completa los campos obligatorios.';
  }
  if (text.contains('componente')) {
    return 'Revisa los componentes del producto.';
  }
  return 'No se pudo completar la acción. Intenta nuevamente.';
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.breakdown,
    required this.busy,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final ProductCostBreakdown breakdown;
  final bool busy;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    _StatusChip(isActive: product.isActive, label: 'Activo'),
                    if (product.clientProvidesLona) const _TagChip(label: 'Cliente pone lona'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${product.outputUnit} · Costo unitario ${formatDisplayNumber(breakdown.unitCost)}'),
            Text('Precio de venta ${formatDisplayNumber(product.salePrice)}'),
            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(product.description!),
            ],
            const SizedBox(height: 8),
            Text('Componentes: ${product.components.length}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onOpenDetail, child: const Text('Detalle')),
                OutlinedButton(onPressed: busy ? null : onEdit, child: const Text('Editar')),
                OutlinedButton(onPressed: busy ? null : onDelete, child: const Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.product, required this.breakdown});

  final Product product;
  final ProductCostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                ),
                if (product.clientProvidesLona) const _TagChip(label: 'Cliente pone lona'),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.outputUnit),
            const SizedBox(height: 12),
            Text('Costo unitario ${formatDisplayNumber(breakdown.unitCost)}', style: Theme.of(context).textTheme.titleLarge),
            Text('Precio de venta ${formatDisplayNumber(product.salePrice)}', style: Theme.of(context).textTheme.titleMedium),
            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(product.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductComponentsCard extends StatelessWidget {
  const _ProductComponentsCard({required this.product, required this.breakdown});

  final Product product;
  final ProductCostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Componentes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (breakdown.componentCosts.isEmpty)
              const Text('El producto aún no tiene componentes.')
            else
              ...breakdown.componentCosts.map(
                (component) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(component.subproductName, style: Theme.of(context).textTheme.titleSmall),
                              ),
                              if (component.isMissing) const _TagChip(label: 'Eliminado'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${formatDisplayNumber(component.quantityPerUnit)} ${component.outputUnit} · Costo ${formatDisplayNumber(component.subtotal)}'),
                          if (component.notes != null && component.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(component.notes!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickSimulationCard extends StatelessWidget {
  const _QuickSimulationCard({
    required this.quantityController,
    required this.breakdown,
    required this.totalForQuantity,
    required this.product,
  });

  final TextEditingController quantityController;
  final ProductCostBreakdown breakdown;
  final double? totalForQuantity;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simulación rápida', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad a producir',
                helperText: 'Ingresa un valor mayor a cero.',
              ),
            ),
            const SizedBox(height: 12),
            if (totalForQuantity == null)
              const Text('Ingresa una cantidad válida para ver el total.')
            else ...[
              Text(
                'Costo total para ${formatDisplayNumber(quantity)} ${product.outputUnit}: ${formatDisplayNumber(totalForQuantity!)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...breakdown.componentCosts.map(
                (component) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${component.subproductName}: ${formatDisplayNumber(component.quantityPerUnit * quantity)} ${component.outputUnit} · ${formatDisplayNumber(component.subtotal * quantity)}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState({
    required this.hasQuery,
    required this.onCreate,
    required this.onClearSearch,
  });

  final bool hasQuery;
  final VoidCallback? onCreate;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasQuery ? 'No hay coincidencias' : 'Aún no hay productos',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Prueba con otro término de búsqueda o limpia el filtro.'
                  : 'Crea tu primer producto final para comenzar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (onClearSearch != null)
                  OutlinedButton(
                    onPressed: onClearSearch,
                    child: const Text('Limpiar búsqueda'),
                  ),
                FilledButton(
                  onPressed: onCreate,
                  child: const Text('Crear producto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormResult {
  const _ProductFormResult({
    required this.name,
    required this.description,
    required this.outputUnit,
    required this.salePrice,
    required this.clientProvidesLona,
    required this.isActive,
    required this.components,
  });

  final String name;
  final String? description;
  final String outputUnit;
  final double salePrice;
  final bool clientProvidesLona;
  final bool isActive;
  final List<ProductComponent> components;
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({
    required this.subproducts,
    required this.materials,
    required this.categories,
    this.product,
  });

  final List<Subproduct> subproducts;
  final List<MaterialItem> materials;
  final List<MaterialCategory> categories;
  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _outputUnitController;
  late final TextEditingController _salePriceController;
  late final ScrollController _formScrollController;
  late bool _isActive;
  late bool _clientProvidesLona;
  late final List<_ComponentDraft> _components;
  String? _formError;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _outputUnitController = TextEditingController(text: widget.product?.outputUnit ?? '');
    _salePriceController = TextEditingController(
      text: formatDisplayNumber(widget.product?.salePrice ?? 0, fractionDigits: 0),
    );
    _formScrollController = ScrollController();
    _isActive = widget.product?.isActive ?? true;
    _clientProvidesLona = widget.product?.clientProvidesLona ?? false;
    _components = widget.product?.components
            .map(
              (component) => _ComponentDraft(
                subproductId: component.subproductId,
                quantityText: component.quantityPerUnit.toString(),
                notesText: component.notes ?? '',
              ),
            )
            .toList(growable: true) ??
        <_ComponentDraft>[];
    if (_components.isEmpty) {
      _components.add(_ComponentDraft());
    }
    for (final draft in _components) {
      draft.quantityController.addListener(_onFieldChanged);
      draft.notesController.addListener(_onFieldChanged);
    }
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _outputUnitController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _outputUnitController.dispose();
    _salePriceController.dispose();
    _formScrollController.dispose();
    for (final draft in _components) {
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
    final subproducts = _availableSubproducts();
    final subproductsById = {for (final subproduct in widget.subproducts) subproduct.id: subproduct};
    final materialsById = {for (final material in widget.materials) material.id: material};
    final excludedCategoryIds = widget.categories.where((category) => category.isLona).map((category) => category.id).toSet();
    final breakdown = _previewBreakdown(subproductsById, materialsById, excludedCategoryIds);
    final dependenciesMissing = widget.subproducts.isEmpty || widget.materials.isEmpty;

    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo producto final' : 'Editar producto final'),
      content: SizedBox(
        width: 900,
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
                if (dependenciesMissing) ...[
                  const _InlineFormError(
                    message: 'Debes crear materias primas y subproductos antes de crear productos.',
                  ),
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
                TextFormField(
                  controller: _salePriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [MoneyTextInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Precio de venta'),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cliente pone la lona'),
                  subtitle: const Text('Excluye ingredientes de categoría lona en el cálculo.'),
                  value: _clientProvidesLona,
                  onChanged: (value) => setState(() => _clientProvidesLona = value),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Componentes', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: dependenciesMissing
                          ? null
                          : () {
                              final draft = _ComponentDraft();
                              setState(() {
                                draft.quantityController.addListener(_onFieldChanged);
                                draft.notesController.addListener(_onFieldChanged);
                                _components.add(draft);
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }
                                FocusScope.of(context).requestFocus(draft.subproductFocusNode);
                                _scrollToBottom();
                              });
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar componente'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.subproducts.isEmpty)
                  const _InlineFormError(
                    message: 'Debes crear subproductos antes de crear productos.',
                  )
                else
                  ..._components.asMap().entries.map(
                    (entry) => _ComponentRow(
                      index: entry.key,
                      draft: entry.value,
                      subproducts: subproducts,
                      onRemove: _components.length == 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _components.removeAt(entry.key);
                                removed.dispose();
                              });
                            },
                      onChanged: _onFieldChanged,
                    ),
                  ),
                const SizedBox(height: 16),
                _ProductPreviewCard(breakdown: breakdown),
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
          onPressed: dependenciesMissing
              ? null
              : () {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  final components = <ProductComponent>[];
                  final seenSubproductIds = <String>{};
                  for (final draft in _components) {
                    final subproductId = draft.subproductId;
                    final parsedQuantity = double.tryParse(draft.quantityController.text.replaceAll(',', '.'));

                    if (subproductId == null || subproductId.isEmpty) {
                      setState(() => _formError = 'Debes seleccionar un subproducto en cada componente.');
                      return;
                    }
                    if (parsedQuantity == null || parsedQuantity <= 0) {
                      setState(() => _formError = 'Cada componente debe tener una cantidad mayor a cero.');
                      return;
                    }
                    if (!seenSubproductIds.add(subproductId)) {
                      setState(() => _formError = 'Cada subproducto debe aparecer una sola vez por producto.');
                      return;
                    }

                    components.add(
                      ProductComponent(
                        subproductId: subproductId,
                        quantityPerUnit: parsedQuantity,
                        notes: draft.notesController.text.trim().isEmpty
                            ? null
                            : draft.notesController.text.trim(),
                      ),
                    );
                  }

                  if (components.isEmpty) {
                    setState(() => _formError = 'Debes agregar al menos un componente.');
                    return;
                  }

                  Navigator.of(context).pop(
                    _ProductFormResult(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                      outputUnit: _outputUnitController.text.trim(),
                      salePrice: parseMoneyText(_salePriceController.text)?.toDouble() ?? 0,
                      clientProvidesLona: _clientProvidesLona,
                      isActive: _isActive,
                      components: components,
                    ),
                  );
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  List<Subproduct> _availableSubproducts() {
    final available = [...widget.subproducts];
    final existingIds = available.map((subproduct) => subproduct.id).toSet();

    if (widget.product != null) {
      for (final component in widget.product!.components) {
        if (existingIds.contains(component.subproductId)) {
          continue;
        }

        available.add(
          Subproduct(
            id: component.subproductId,
            name: 'Subproducto eliminado',
            nameKey: component.subproductId,
            description: null,
            outputUnit: '-',
            manufacturaCost: 0,
            patinajejeCost: 0,
            armadoBolsillosCost: 0,
            ingredients: const [],
            isActive: false,
            createdAt: null,
            updatedAt: null,
          ),
        );
      }
    }

    return available;
  }

  ProductCostBreakdown _previewBreakdown(
    Map<String, Subproduct> subproductsById,
    Map<String, MaterialItem> materialsById,
    Set<String> excludedCategoryIds,
  ) {
    final components = _components
        .where((draft) => draft.subproductId != null && draft.subproductId!.isNotEmpty)
        .map(
          (draft) => ProductComponent(
            subproductId: draft.subproductId!,
            quantityPerUnit: double.tryParse(draft.quantityController.text.replaceAll(',', '.')) ?? 0,
            notes: draft.notesController.text.trim().isEmpty ? null : draft.notesController.text.trim(),
          ),
        )
        .toList(growable: false);

    return _productCostCalculator.calculate(
      components: components,
      subproductsById: subproductsById,
      materialsById: materialsById,
      excludedCategoryIds: _clientProvidesLona ? excludedCategoryIds : const <String>{},
    );
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

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.index,
    required this.draft,
    required this.subproducts,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _ComponentDraft draft;
  final List<Subproduct> subproducts;
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
                Text('Componente ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            DropdownButtonFormField<String?>(
              initialValue: draft.subproductId,
              focusNode: draft.subproductFocusNode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Subproducto'),
              items: subproducts
                  .map(
                    (subproduct) => DropdownMenuItem<String?>(
                      value: subproduct.id,
                      child: Text(
                        _subproductLabel(subproduct),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                draft.subproductId = value;
                onChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona un subproducto.';
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
            const SizedBox(height: 12),
            TextFormField(
              controller: draft.notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
          ],
        ),
      ),
    );
  }

  String _subproductLabel(Subproduct subproduct) {
    if (subproduct.name == 'Subproducto eliminado') {
      return '${subproduct.name} (${subproduct.id})';
    }
    return '${subproduct.name} · ${subproduct.outputUnit}';
  }
}

class _ComponentDraft {
  _ComponentDraft({
    String? subproductId,
    String quantityText = '',
    String notesText = '',
  })  : subproductId = subproductId,
        quantityController = TextEditingController(text: quantityText),
        notesController = TextEditingController(text: notesText);

  String? subproductId;
  final TextEditingController quantityController;
  final TextEditingController notesController;
  final FocusNode subproductFocusNode = FocusNode();

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    subproductFocusNode.dispose();
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({required this.breakdown});

  final ProductCostBreakdown breakdown;

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
          Text('Costo unitario: ${formatDisplayNumber(breakdown.unitCost)}', style: Theme.of(context).textTheme.titleMedium),
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
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Text(message),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive, required this.label});

  final bool isActive;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
