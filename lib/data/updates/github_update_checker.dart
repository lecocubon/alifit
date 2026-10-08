import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/updates/app_release.dart';

/// Repositorio público donde se publican las versiones de la app.
const githubRepository = 'lecocubon/alifit';

/// Enlace que siempre descarga la última versión publicada.
const latestApkUrl =
    'https://github.com/$githubRepository/releases/latest/download/AliFit.apk';

/// Consulta la última release de GitHub. Solo lee datos públicos: no envía
/// nada del usuario.
class GithubUpdateChecker {
  GithubUpdateChecker({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// La última versión publicada, o null si todavía no hay ninguna con APK.
  /// Lanza una excepción si no hay conexión o GitHub no responde.
  Future<AppRelease?> fetchLatest() async {
    final response = await _client
        .get(
          Uri.parse(
            'https://api.github.com/repos/$githubRepository/releases/latest',
          ),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'GitHub respondió ${response.statusCode}',
        response.request?.url,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = json['tag_name'] as String?;
    final apk = (json['assets'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((asset) => (asset['name'] as String? ?? '').endsWith('.apk'))
        .firstOrNull;
    if (tag == null || apk == null) {
      return null;
    }
    return AppRelease(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      apkUrl: apk['browser_download_url'] as String,
      notes: json['body'] as String?,
    );
  }
}
