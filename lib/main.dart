import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Mantiene la splash nativa visible hasta que se llame a
  // FlutterNativeSplash.remove() (en AliFitApp, cuando el catálogo y el
  // perfil ya están listos), en vez de cortar a una pantalla de carga
  // aparte apenas termina de dibujarse el primer frame de Flutter.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: AliFitApp()));
}
