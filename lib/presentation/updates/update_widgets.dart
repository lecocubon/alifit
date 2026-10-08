import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/updates/app_release.dart';
import '../../domain/updates/update_providers.dart';

/// Aviso en Inicio cuando hay una versión nueva publicada.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableUpdateProvider).value;
    if (release == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: Text('Hay una versión nueva (${release.version})'),
          subtitle: const Text('Toca para ver qué trae y descargarla.'),
          onTap: () => showUpdateDialog(context, release),
        ),
      ),
    );
  }
}

Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  final notes = release.notes?.trim() ?? '';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('AliFit ${release.version}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes.isNotEmpty) ...[Text(notes), const SizedBox(height: 12)],
            const Text(
              'Se descarga con el navegador. Al terminar, abre el archivo y '
              'toca "Actualizar". Tus datos se conservan.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Después'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Descargar'),
          onPressed: () async {
            Navigator.of(context).pop();
            await launchUrl(
              Uri.parse(release.apkUrl),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ],
    ),
  );
}

/// Sección de Configuración: versión instalada y revisión manual.
class UpdatesSection extends ConsumerStatefulWidget {
  const UpdatesSection({super.key});

  @override
  ConsumerState<UpdatesSection> createState() => _UpdatesSectionState();
}

class _UpdatesSectionState extends ConsumerState<UpdatesSection> {
  bool _checking = false;

  Future<void> _check() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    try {
      final installed = await ref.read(installedVersionProvider.future);
      final latest = await ref.read(updateCheckerProvider).fetchLatest();
      if (!mounted) {
        return;
      }
      if (latest != null && isNewerVersion(latest.version, installed)) {
        await showUpdateDialog(context, latest);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Ya tienes la última versión.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo revisar. ¿Hay conexión a internet?'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = ref.watch(installedVersionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Versión instalada: ${installed ?? '...'}'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: _checking
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.system_update_outlined),
          label: const Text('Buscar actualización'),
          onPressed: _checking ? null : _check,
        ),
      ],
    );
  }
}
