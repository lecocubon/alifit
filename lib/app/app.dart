import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import/usda_import_provider.dart';
import '../domain/profile/profile_providers.dart';
import '../domain/settings/settings_providers.dart';
import '../presentation/profile/profile_onboarding_screen.dart';
import '../presentation/shell/main_shell.dart';
import 'theme/app_theme.dart';

class AliFitApp extends ConsumerWidget {
  const AliFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final catalogSetup = ref.watch(catalogSetupProvider);
    final profileAsync = ref.watch(activeProfileProvider);

    return MaterialApp(
      title: 'AliFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: catalogSetup.when(
        data: (_) => profileAsync.when(
          data: (profile) {
            // El catálogo y el perfil ya están listos: recién acá se
            // quita la splash nativa, para que no se vea una pantalla de
            // carga aparte entre medio.
            FlutterNativeSplash.remove();
            return profile == null
                ? const ProfileOnboardingScreen()
                : const MainShell();
          },
          loading: () => const _Splash(),
          error: (error, _) {
            FlutterNativeSplash.remove();
            return Scaffold(body: Center(child: Text('Error: $error')));
          },
        ),
        loading: () => const _Splash(message: 'Preparando catálogo...'),
        error: (error, _) {
          FlutterNativeSplash.remove();
          return Scaffold(body: Center(child: Text('Error: $error')));
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}
