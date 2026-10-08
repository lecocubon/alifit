import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_inventory_repository.dart';
import 'package:alifit/domain/inventory/inventory_location.dart';

void main() {
  late AppDatabase db;
  late DriftInventoryRepository repo;
  late int foodId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftInventoryRepository(db);
    foodId = await db
        .into(db.foods)
        .insert(
          FoodsCompanion.insert(
            name: 'Leche',
            normalizedName: 'leche',
            source: const Value('user'),
            calories: 60,
            carbs: 5,
            protein: 3.2,
            fat: 3.3,
            fiber: 0,
            sugar: 5,
            sodium: 40,
          ),
        );
  });

  tearDown(() => db.close());

  test('agrega un item y calcula vencimiento próximo', () async {
    await repo.addItem(
      foodId: foodId,
      quantity: 1000,
      unitLabel: 'ml',
      location: InventoryLocation.refrigerator,
      expiresAt: DateTime.now().add(const Duration(days: 2)),
    );

    final items = await repo.watchItems().first;
    expect(items, hasLength(1));
    expect(items.first.isExpiringSoon, isTrue);
    expect(items.first.isExpired, isFalse);
  });

  test('detecta un item ya vencido', () async {
    await repo.addItem(
      foodId: foodId,
      quantity: 1000,
      unitLabel: 'ml',
      location: InventoryLocation.refrigerator,
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    final items = await repo.watchItems().first;
    expect(items.first.isExpired, isTrue);
  });

  test('sin fecha de vencimiento no está ni vencido ni por vencer', () async {
    await repo.addItem(
      foodId: foodId,
      quantity: 1000,
      unitLabel: 'ml',
      location: InventoryLocation.pantry,
    );

    final items = await repo.watchItems().first;
    expect(items.first.daysUntilExpiry, isNull);
    expect(items.first.isExpiringSoon, isFalse);
    expect(items.first.isExpired, isFalse);
  });

  test('eliminar item lo quita de la lista', () async {
    await repo.addItem(
      foodId: foodId,
      quantity: 500,
      unitLabel: 'ml',
      location: InventoryLocation.pantry,
    );
    final items = await repo.watchItems().first;

    await repo.deleteItem(items.first.id);
    final afterDelete = await repo.watchItems().first;
    expect(afterDelete, isEmpty);
  });
}
