import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('inserta y lee un perfil', () async {
    await db
        .into(db.userProfiles)
        .insert(
          UserProfilesCompanion.insert(
            name: 'Nico',
            conditions: const Value('diabetes'),
          ),
        );

    final profiles = await db.select(db.userProfiles).get();
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Nico');
    expect(profiles.first.conditions, 'diabetes');
  });

  test('actualiza (upsert) una preferencia de tema', () async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          const AppSettingsCompanion(
            key: Value('theme_mode'),
            value: Value('dark'),
          ),
        );
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          const AppSettingsCompanion(
            key: Value('theme_mode'),
            value: Value('light'),
          ),
        );

    final settings = await db.select(db.appSettings).get();
    expect(settings, hasLength(1));
    expect(settings.first.value, 'light');
  });
}
