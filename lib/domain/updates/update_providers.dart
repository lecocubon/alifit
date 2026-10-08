import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/updates/github_update_checker.dart';
import 'app_release.dart';

final updateCheckerProvider = Provider<GithubUpdateChecker>(
  (ref) => GithubUpdateChecker(),
);

final installedVersionProvider = FutureProvider<String>((ref) async {
  return (await PackageInfo.fromPlatform()).version;
});

/// La versión nueva que hay para descargar, o null si ya está al día. Se
/// revisa una vez al abrir la app; sin internet simplemente no avisa.
final availableUpdateProvider = FutureProvider<AppRelease?>((ref) async {
  final installed = await ref.watch(installedVersionProvider.future);
  try {
    final latest = await ref.watch(updateCheckerProvider).fetchLatest();
    if (latest == null || !isNewerVersion(latest.version, installed)) {
      return null;
    }
    return latest;
  } catch (_) {
    return null;
  }
});
