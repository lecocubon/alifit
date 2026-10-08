import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Abre un selector de rueda para elegir una altura entre 0 y 240 cm.
Future<double?> showHeightPicker(BuildContext context, double? initialCm) {
  final initial = (initialCm ?? 170).round().clamp(0, 240);
  var selected = initial;
  return showModalBottomSheet<double>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Altura',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(
                initialItem: initial,
              ),
              onSelectedItemChanged: (index) => selected = index,
              children: List.generate(
                241,
                (index) => Center(child: Text('$index cm')),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(selected.toDouble()),
                child: const Text('Listo'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Abre un selector de rueda (parte entera + un decimal) para elegir un
/// peso entre 0 y 300 kg.
Future<double?> showWeightPicker(BuildContext context, double? initialKg) {
  final wholeInitial = (initialKg ?? 70).floor().clamp(0, 300);
  final decimalInitial = (((initialKg ?? 70) - wholeInitial) * 10)
      .round()
      .clamp(0, 9);
  var whole = wholeInitial;
  var decimal = decimalInitial;
  return showModalBottomSheet<double>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Peso', style: Theme.of(context).textTheme.titleMedium),
          ),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: CupertinoPicker(
                    itemExtent: 36,
                    scrollController: FixedExtentScrollController(
                      initialItem: wholeInitial,
                    ),
                    onSelectedItemChanged: (index) => whole = index,
                    children: List.generate(
                      301,
                      (index) => Center(child: Text('$index')),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(',', style: TextStyle(fontSize: 24)),
                ),
                SizedBox(
                  width: 60,
                  child: CupertinoPicker(
                    itemExtent: 36,
                    scrollController: FixedExtentScrollController(
                      initialItem: decimalInitial,
                    ),
                    onSelectedItemChanged: (index) => decimal = index,
                    children: List.generate(
                      10,
                      (index) => Center(child: Text('$index')),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('kg'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(whole + decimal / 10),
                child: const Text('Listo'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Campo tipo TextField que al tocarlo abre [showHeightPicker].
class HeightPickerTile extends StatelessWidget {
  const HeightPickerTile({
    super.key,
    required this.valueCm,
    required this.onChanged,
    this.label = 'Altura (cm)',
  });

  final double? valueCm;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showHeightPicker(context, valueCm);
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(valueCm == null ? 'Seleccionar' : '${valueCm!.round()} cm'),
      ),
    );
  }
}

/// Campo tipo TextField que al tocarlo abre [showWeightPicker].
class WeightPickerTile extends StatelessWidget {
  const WeightPickerTile({
    super.key,
    required this.valueKg,
    required this.onChanged,
    this.label = 'Peso (kg)',
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showWeightPicker(context, valueKg);
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          valueKg == null
              ? 'Seleccionar'
              : '${valueKg!.toStringAsFixed(1).replaceAll('.', ',')} kg',
        ),
      ),
    );
  }
}
