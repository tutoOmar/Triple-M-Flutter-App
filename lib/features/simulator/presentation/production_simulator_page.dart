import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/display_number.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../material_categories/application/material_categories_controller.dart';
import '../../materials/domain/material_item.dart';
import '../../materials/application/materials_controller.dart';
import '../../products/application/products_controller.dart';
import '../../products/domain/product.dart';
import '../../subproducts/application/subproducts_controller.dart';
import '../../subproducts/domain/subproduct.dart';
import '../domain/production_simulation.dart';

const _simulatorCalculator = ProductionSimulatorCalculator();

class ProductionSimulatorPage extends ConsumerStatefulWidget {
  const ProductionSimulatorPage({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<ProductionSimulatorPage> createState() => _ProductionSimulatorPageState();
}

class _ProductionSimulatorPageState extends ConsumerState<ProductionSimulatorPage> {
  late final TextEditingController _quantityController;
  String? _selectedProductId;
  ProductionSimulationBreakdown? _breakdown;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _selectedProductId = widget.initialProductId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final subproductsAsync = ref.watch(subproductsStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(materialCategoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Simulador de producción'),
      ),
      body: productsAsync.when(
        data: (products) {
          return subproductsAsync.when(
            data: (subproducts) {
              return materialsAsync.when(
                data: (materials) {
                  return categoriesAsync.when(
                    data: (categories) {
                      if (products.isEmpty) {
                        return const _EmptyProductsState();
                      }

                      _syncInitialSelection(products);

                      final selectedProduct = _selectedProduct(products);
                      final materialsById = {for (final material in materials) material.id: material};
                      final subproductsById = {for (final subproduct in subproducts) subproduct.id: subproduct};
                      final categoryNamesById = {for (final category in categories) category.id: category.name};
                      final excludedCategoryIds = categories
                          .where((category) => category.isLona)
                          .map((category) => category.id)
                          .toSet();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_formError != null) ...[
                              _InlineError(message: _formError!),
                              const SizedBox(height: 16),
                            ],
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Selecciona el producto y la cantidad a producir',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedProduct?.id,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Producto final'),
                                      items: products
                                          .map(
                                            (product) => DropdownMenuItem<String>(
                                              value: product.id,
                                              child: Text(product.name),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProductId = value;
                                          _breakdown = null;
                                          _formError = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad X',
                                        helperText: 'Debe ser mayor a cero.',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: selectedProduct == null
                                          ? null
                                          : () => _calculate(
                                                product: selectedProduct,
                                                materialsById: materialsById,
                                                subproductsById: subproductsById,
                                                categoryNamesById: categoryNamesById,
                                                excludedCategoryIds: excludedCategoryIds,
                                              ),
                                      child: const Text('Calcular'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_breakdown == null)
                              _PlaceholderCard(
                                message: selectedProduct == null
                                    ? 'Selecciona un producto para ver su simulación.'
                                    : 'Ingresa una cantidad y presiona Calcular para ver el desglose.',
                              )
                            else ...[
                              _SummaryCard(breakdown: _breakdown!),
                              const SizedBox(height: 16),
                              _SubproductBreakdownCard(breakdown: _breakdown!),
                              const SizedBox(height: 16),
                              _MaterialBreakdownCard(breakdown: _breakdown!),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const Center(child: Text('No se pudieron cargar las categorías.')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(child: Text('No se pudieron cargar las materias primas.')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(child: Text('No se pudieron cargar los subproductos.')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('No se pudieron cargar los productos.')),
      ),
    );
  }

  void _syncInitialSelection(List<Product> products) {
    final hasSelectedProduct = _selectedProductId != null && products.any((product) => product.id == _selectedProductId);
    if (hasSelectedProduct) {
      return;
    }

    final fallbackProduct = widget.initialProductId != null
        ? products.where((product) => product.id == widget.initialProductId).cast<Product?>().firstOrNull
        : products.firstOrNull;

    if (fallbackProduct == null || fallbackProduct.id == _selectedProductId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProductId = fallbackProduct.id;
      });
    });
  }

  Product? _selectedProduct(List<Product> products) {
    for (final product in products) {
      if (product.id == _selectedProductId) {
        return product;
      }
    }
    return products.firstOrNull;
  }

  Future<void> _calculate({
    required Product product,
    required Map<String, MaterialItem> materialsById,
    required Map<String, Subproduct> subproductsById,
    required Map<String, String> categoryNamesById,
    required Set<String> excludedCategoryIds,
  }) async {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      setState(() {
        _formError = 'La cantidad debe ser mayor a cero.';
        _breakdown = null;
      });
      return;
    }

    final loadingToast = AppToast.showLoading(context, 'Calculando...');
    try {
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) {
        return;
      }

      setState(() {
        _formError = null;
        _breakdown = _simulatorCalculator.calculate(
          product: product,
          quantity: quantity,
          subproductsById: subproductsById,
          materialsById: materialsById,
          categoryNamesById: categoryNamesById,
          excludedCategoryIds: product.clientProvidesLona ? excludedCategoryIds : const <String>{},
        );
      });
    } finally {
      loadingToast.close();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.breakdown});

  final ProductionSimulationBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Producto: ${breakdown.productName}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text('Cantidad: ${formatDisplayNumber(breakdown.quantity)} ${breakdown.outputUnit}'),
            const SizedBox(height: 12),
            Text('Costo unitario: ${formatDisplayNumber(breakdown.unitCost)}', style: Theme.of(context).textTheme.titleLarge),
            Text('Costo total: ${formatDisplayNumber(breakdown.totalCost)}', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _SubproductBreakdownCard extends StatelessWidget {
  const _SubproductBreakdownCard({required this.breakdown});

  final ProductionSimulationBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Desglose por subproducto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (breakdown.subproducts.isEmpty)
              const Text('Este producto no tiene componentes.')
            else
              ...breakdown.subproducts.map(
                (subproduct) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(subproduct.subproductName),
                    subtitle: Text(
                      '${formatDisplayNumber(subproduct.quantityForSimulation)} ${subproduct.outputUnit} · ${formatDisplayNumber(subproduct.subtotal)}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Cantidad por unidad de producto: ${formatDisplayNumber(subproduct.quantityPerProductUnit)}'),
                            Text('Costo de materiales: ${formatDisplayNumber(subproduct.ingredientsCost)}'),
                            Text('Costos fijos: ${formatDisplayNumber(subproduct.fixedCost)}'),
                            Text('Costo unitario del subproducto: ${formatDisplayNumber(subproduct.unitCost)}'),
                            const SizedBox(height: 12),
                            if (subproduct.isMissing)
                              const Text('Este subproducto ya no existe.'),
                            ...subproduct.ingredients.map(
                              (ingredient) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${ingredient.materialName}: ${formatDisplayNumber(ingredient.quantityForSimulation)} ${ingredient.unit} · ${formatDisplayNumber(ingredient.subtotal)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MaterialBreakdownCard extends StatelessWidget {
  const _MaterialBreakdownCard({required this.breakdown});

  final ProductionSimulationBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Materiales requeridos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (breakdown.materials.isEmpty)
              const Text('No hay materiales requeridos para esta simulación.')
            else
              ...breakdown.materials.map(
                (material) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(material.materialName, style: Theme.of(context).textTheme.titleSmall),
                              ),
                              if (material.isMissing) const Chip(label: Text('Eliminada')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Categoría: ${material.categoryName ?? '-'}'),
                          Text('Cantidad: ${formatDisplayNumber(material.quantity)} ${material.unit}'),
                          Text('Precio unitario: ${formatDisplayNumber(material.unitPrice)}'),
                          Text('Subtotal: ${formatDisplayNumber(material.subtotal)}'),
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

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Primero necesitas productos finales para poder simular.'),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}