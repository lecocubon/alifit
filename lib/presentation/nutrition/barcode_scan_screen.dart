import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/openfoodfacts/off_client.dart';
import '../../domain/openfoodfacts/off_product.dart';
import '../../domain/openfoodfacts/off_providers.dart';
import 'food_form_screen.dart';

/// Escanea (o permite ingresar manualmente) un código de barras, consulta
/// primero el catálogo local (caché) y luego, si hay conexión, Open Food
/// Facts. Devuelve el [Food] elegido/creado vía Navigator.pop, o null si
/// el usuario cancela.
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final _manualController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_processing) {
      return;
    }
    setState(() => _processing = true);

    final existing = await ref
        .read(foodRepositoryProvider)
        .getByBarcode(barcode);
    if (existing != null) {
      if (mounted) {
        Navigator.of(context).pop(existing);
      }
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final product = await ref.read(offClientProvider).fetchProduct(barcode);
      if (!mounted) {
        return;
      }
      final food = await showModalBottomSheet<Food>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _OffConfirmationSheet(product: product),
      );
      if (food != null && mounted) {
        Navigator.of(context).pop(food);
        return;
      }
    } on OffNotFoundException {
      if (mounted) {
        await _offerManualCreation(
          barcode,
          'Este código no está en Open Food Facts. Puedes crear el '
          'alimento manualmente.',
        );
      }
    } on OffNetworkException {
      if (mounted) {
        await _offerManualCreation(
          barcode,
          'No se pudo consultar Open Food Facts (revisa tu conexión). '
          'Puedes crear el alimento manualmente y editarlo después.',
        );
      }
    } catch (_) {
      // Una respuesta con un formato inesperado no puede dejar la pantalla
      // trabada con el indicador de carga.
      if (mounted) {
        await _offerManualCreation(
          barcode,
          'No se pudieron leer los datos de este producto en Open Food '
          'Facts. Puedes crear el alimento manualmente.',
        );
      }
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }

  Future<void> _offerManualCreation(String barcode, String message) async {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver a escanear'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Crear manualmente'),
          ),
        ],
      ),
    );
    if (create == true && mounted) {
      final food = await Navigator.of(context).push<Food>(
        MaterialPageRoute(
          builder: (_) => FoodFormScreen(prefilledBarcode: barcode),
        ),
      );
      if (food != null && mounted) {
        Navigator.of(context).pop(food);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código de barras')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull?.rawValue;
                      if (barcode != null) {
                        _handleBarcode(barcode);
                      }
                    },
                  ),
                  if (_processing)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'O ingresa el código manualmente',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isNotEmpty) {
                          _handleBarcode(trimmed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _processing
                        ? null
                        : () {
                            final value = _manualController.text.trim();
                            if (value.isNotEmpty) {
                              _handleBarcode(value);
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffConfirmationSheet extends ConsumerStatefulWidget {
  const _OffConfirmationSheet({required this.product});

  final OffProduct product;

  @override
  ConsumerState<_OffConfirmationSheet> createState() =>
      _OffConfirmationSheetState();
}

class _OffConfirmationSheetState extends ConsumerState<_OffConfirmationSheet> {
  bool _saving = false;

  String _formatDate(DateTime date) =>
      DateFormat('d MMM y, HH:mm', 'es').format(date);

  Future<void> _save() async {
    setState(() => _saving = true);
    final product = widget.product;
    final repo = ref.read(foodRepositoryProvider);
    final id = await repo.createFood(
      name: product.name,
      brand: product.brand,
      nutritionPer100: product.nutritionPer100,
      baseUnit: 'g',
      barcode: product.barcode,
      notes:
          'Datos de Open Food Facts, consultados el '
          '${_formatDate(product.fetchedAt)}.',
      source: FoodSource.openFoodFacts,
    );
    final food = await repo.getById(id);
    if (mounted) {
      Navigator.of(context).pop(food);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final n = product.nutritionPer100;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Fuente: Open Food Facts · consultado el '
            '${_formatDate(product.fetchedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (product.brand != null) Text('Marca: ${product.brand}'),
          if (product.country != null) Text('País: ${product.country}'),
          Text('Código de barras: ${product.barcode}'),
          const SizedBox(height: 12),
          Text('${n.calories.round()} kcal / 100 g'),
          Text(
            'Carbohidratos: ${n.carbs.round()} g · '
            'Proteínas: ${n.protein.round()} g · '
            'Grasas: ${n.fat.round()} g',
          ),
          if (!product.isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Open Food Facts no informó: ${product.missingFields.join(', ')}. '
              'Se completaron como 0; revísalos antes de guardar.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ],
          if (product.inconsistencyWarning != null) ...[
            const SizedBox(height: 8),
            Text(
              product.inconsistencyWarning!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar en mi catálogo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
