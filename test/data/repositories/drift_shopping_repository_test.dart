import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_menu_repository.dart';
import 'package:alifit/data/repositories/drift_recipe_repository.dart';
import 'package:alifit/data/repositories/drift_shopping_repository.dart';
import 'package:alifit/domain/shopping/shopping_category.dart';
import 'package:alifit/domain/shopping/shopping_item.dart';

void main() {
  late AppDatabase db;
  late DriftShoppingRepository repo;
  late DriftMenuRepository menuRepo;
  late int planId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftShoppingRepository(db);
    menuRepo = DriftMenuRepository(db, DriftRecipeRepository(db));
    planId = await menuRepo.createPlan(
      label: 'Semana de prueba',
      startDate: DateTime(2026, 7, 20),
    );
  });

  tearDown(() => db.close());

  test('agrega un producto manual', () async {
    await repo.addManualItem(
      menuPlanId: planId,
      name: 'Detergente',
      quantity: 1,
      unitLabel: 'unidad',
      category: ShoppingCategory.otros,
    );

    final items = await repo.watchItems(planId).first;
    expect(items, hasLength(1));
    expect(items.first.name, 'Detergente');
    expect(items.first.isManual, isTrue);
  });

  test(
    'regenerar reemplaza solo los productos generados, no los manuales',
    () async {
      await repo.addManualItem(
        menuPlanId: planId,
        name: 'Detergente',
        quantity: 1,
        unitLabel: 'unidad',
        category: ShoppingCategory.otros,
      );
      await repo.regenerateFromMenu(planId, [
        const ShoppingItemDraft(
          name: 'Arroz',
          quantity: 200,
          unitLabel: 'g',
          category: ShoppingCategory.despensa,
        ),
      ]);

      var items = await repo.watchItems(planId).first;
      expect(items.map((i) => i.name).toSet(), {'Detergente', 'Arroz'});

      await repo.regenerateFromMenu(planId, [
        const ShoppingItemDraft(
          name: 'Pollo',
          quantity: 500,
          unitLabel: 'g',
          category: ShoppingCategory.carnes,
        ),
      ]);

      items = await repo.watchItems(planId).first;
      expect(items.map((i) => i.name).toSet(), {'Detergente', 'Pollo'});
    },
  );

  test('marcar como comprado persiste el cambio', () async {
    await repo.addManualItem(
      menuPlanId: planId,
      name: 'Detergente',
      quantity: 1,
      unitLabel: 'unidad',
      category: ShoppingCategory.otros,
    );
    final items = await repo.watchItems(planId).first;

    await repo.setChecked(items.first.id, true);

    final updated = await repo.watchItems(planId).first;
    expect(updated.first.isChecked, isTrue);
  });

  test('guardar precio manual persiste el valor', () async {
    await repo.addManualItem(
      menuPlanId: planId,
      name: 'Detergente',
      quantity: 1,
      unitLabel: 'unidad',
      category: ShoppingCategory.otros,
    );
    final items = await repo.watchItems(planId).first;

    await repo.setManualPrice(items.first.id, 2500);

    final updated = await repo.watchItems(planId).first;
    expect(updated.first.manualPrice, 2500);
  });

  test('eliminar un producto lo quita de la lista', () async {
    await repo.addManualItem(
      menuPlanId: planId,
      name: 'Detergente',
      quantity: 1,
      unitLabel: 'unidad',
      category: ShoppingCategory.otros,
    );
    final items = await repo.watchItems(planId).first;

    await repo.deleteItem(items.first.id);

    final updated = await repo.watchItems(planId).first;
    expect(updated, isEmpty);
  });

  test(
    'eliminar el plan de menú elimina también su lista de compras',
    () async {
      await repo.addManualItem(
        menuPlanId: planId,
        name: 'Detergente',
        quantity: 1,
        unitLabel: 'unidad',
        category: ShoppingCategory.otros,
      );

      await menuRepo.deletePlan(planId);

      final items = await repo.watchItems(planId).first;
      expect(items, isEmpty);
    },
  );
}
