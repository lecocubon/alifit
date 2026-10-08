import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile/biological_sex.dart';
import '../../domain/profile/chronic_condition.dart';
import '../../domain/profile/diabetes_type.dart';
import '../../domain/profile/profile_providers.dart';
import '../../domain/profile/user_profile.dart';
import '../common/medical_disclaimer_banner.dart';
import '../../core/text/decimal_format.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.existingProfile});

  final UserProfile? existingProfile;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late Set<ChronicCondition> _conditions;
  DiabetesType? _diabetesType;
  BiologicalSex? _biologicalSex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProfile;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _notesController = TextEditingController(
      text: existing?.healthConditionNotes ?? '',
    );
    _heightController = TextEditingController(
      text: existing?.heightCm == null
          ? ''
          : existing!.heightCm!.toStringAsFixed(0),
    );
    _ageController = TextEditingController(
      text: existing?.age == null ? '' : existing!.age!.toString(),
    );
    _conditions = {...(existing?.conditions ?? const [])};
    _diabetesType = existing?.diabetesType;
    _biologicalSex = existing?.biologicalSex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(profileRepositoryProvider)
        .saveProfile(
          name: _nameController.text.trim(),
          conditions: _conditions.toList(),
          diabetesType: _conditions.contains(ChronicCondition.diabetes)
              ? _diabetesType
              : null,
          healthConditionNotes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          heightCm: parseDecimalEs(_heightController.text),
          biologicalSex: _biologicalSex,
          age: int.tryParse(_ageController.text.trim()),
        );
    if (mounted) {
      setState(() => _saving = false);
      if (widget.existingProfile != null) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProfile != null;
    return Scaffold(
      appBar: isEditing ? AppBar(title: const Text('Editar perfil')) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditing) ...[
                  Text(
                    'Bienvenido a AliFit',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este perfil se guarda solo en tu teléfono. Cada '
                    'persona que instale la app configura el suyo por '
                    'separado.',
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tu nombre'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Altura en cm (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad en años (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sexo biológico (opcional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Solo se usa para calcular con más precisión el % de '
                  'grasa corporal si decides usar esa calculadora. Puedes '
                  'dejarlo sin marcar.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: BiologicalSex.values.map((sex) {
                    return ChoiceChip(
                      label: Text(sex.label),
                      selected: _biologicalSex == sex,
                      onSelected: (selected) => setState(
                        () => _biologicalSex = selected ? sex : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Tienes alguna condición a considerar?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Puedes marcar más de una.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ChronicCondition.values.map((condition) {
                    return FilterChip(
                      label: Text(condition.label),
                      selected: _conditions.contains(condition),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _conditions.add(condition);
                        } else {
                          _conditions.remove(condition);
                        }
                      }),
                    );
                  }).toList(),
                ),
                if (_conditions.contains(ChronicCondition.diabetes)) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DiabetesType>(
                    initialValue: _diabetesType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de diabetes (opcional)',
                    ),
                    items: DiabetesType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _diabetesType = value),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: alergias, preferencias, etc.',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const MedicalDisclaimerBanner(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Guardar cambios' : 'Comenzar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
