import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';
import 'package:nissy_bakes_original/services/price_calculator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // every run works on its own fresh copy of the database
  databaseFactoryFfi.setDatabasesPath(
    Directory.systemTemp.createTempSync('nissy_test_db').path,
  );

  // On Windows the app builds the asset key with a backslash, which the
  // asset bundle cannot find, so the database asset is served by hand.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key.contains('nissybakesdb.db')) {
      final bytes = File('assets/nissybakesdb.db').readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    return null;
  });

  group('PriceCalculator', () {
    test('matches the seeded Wheat Bread numbers', () {
      final p = PriceCalculator.calculate(
        edibleCost: 46.48,
        packingCost: 14,
        workPct: 30,
        profitPct: 40,
        retailPct: 8,
      );
      expect(p.wholesale, 93);
      expect(p.retail, 100);
    });

    test('retail uses the rounded wholesale and normal rounding', () {
      final p = PriceCalculator.calculate(
        edibleCost: 100,
        packingCost: 0,
        workPct: 0,
        profitPct: 0,
        retailPct: 8,
      );
      expect(p.wholesale, 100);
      expect(p.retail, 108);
      expect(
        PriceCalculator.calculate(
          edibleCost: 62.5,
          packingCost: 0,
          workPct: 0,
          profitPct: 0,
          retailPct: 0,
        ).wholesale,
        63,
      );
    });
  });

  group('database', () {
    final db = DbHelper();
    final unitIds = <String, int>{};

    // The tests build their own data in the temporary test copy of the
    // database, so they do not depend on what is stored in the asset file.
    Future<int> addRm(String name, num weight, int unit, num cost, String type,
        {Database? database}) async {
      final d = database ?? await db.database;
      return d.insert('raw_material_master', {
        'rm_name': name,
        'weight': weight,
        'base_unit_id': unit,
        'cost': cost,
        'rm_type': type,
        'modified_datetime': '2026-01-01 00:00:00',
        'created_datetime': '2026-01-01 00:00:00',
      });
    }

    late int maida, butter, cashew;

    setUpAll(() async {
      final d = await db.database;
      const gms = 3;
      unitIds['gms'] = gms;
      maida = await addRm('Maida', 1000, gms, 45, 'edible');
      butter = await addRm('Butter', 1000, gms, 560, 'edible');
      final box = await addRm('Box', 1, 10, 14, 'packing');
      cashew = await addRm('Cashew nuts', 1000, gms, 1040, 'edible');

      // items 1 and 3 use Maida; item 1 has a known total
      await db.saveItemIngredients(1, [
        {'rm_id': maida, 'quantity': 400, 'unit_id': gms},
        {'rm_id': butter, 'quantity': 100, 'unit_id': gms},
        {'rm_id': box, 'quantity': 1, 'unit_id': 10},
      ]);
      await db.saveItemIngredients(3, [
        {'rm_id': maida, 'quantity': 500, 'unit_id': gms},
      ]);
      expect(d, isNotNull);
    });

    test('ingredients are saved and prices come from the shared function',
        () async {
      final database = await db.database;
      final rows = await db.getItemIngredients(1);
      expect(rows.length, 3);

      // item 1 percentages in the data: work 30, profit 40, retail 8
      // edible = 400/1000*45 + 100/1000*560 = 18 + 56 = 74, packing = 14
      final expected = PriceCalculator.calculate(
        edibleCost: 74,
        packingCost: 14,
        workPct: 30,
        profitPct: 40,
        retailPct: 8,
      );
      final item = await database.query('item_master', where: 'item_id = 1');
      expect(item.first['price_wholesale'], expected.wholesale);
      expect(item.first['price_retail'], expected.retail);
    });

    test('recalculation never changes the menu price', () async {
      final database = await db.database;
      await database.update('item_master', {'menu_price': 80},
          where: 'item_id = 1');
      await db.recalculateItemPrices(1);
      final item = await database.query('item_master', where: 'item_id = 1');
      expect(item.first['menu_price'], 80);
    });

    test('raw material cost change updates every item using it', () async {
      final database = await db.database;
      expect(await db.isRawMaterialInUse(maida), isTrue);

      final before = await database.query('item_master',
          columns: ['item_id', 'price_wholesale'],
          where: 'item_id IN (1, 3)',
          orderBy: 'item_id');

      await database.update('raw_material_master', {'cost': 450},
          where: 'rm_id = ?', whereArgs: [maida]);
      await db.recalculateItemsUsingRm(maida);

      final after = await database.query('item_master',
          columns: ['item_id', 'price_wholesale', 'menu_price'],
          where: 'item_id IN (1, 3)',
          orderBy: 'item_id');
      expect(after[0]['price_wholesale'] as num,
          greaterThan(before[0]['price_wholesale'] as num));
      expect(after[1]['price_wholesale'] as num,
          greaterThan(before[1]['price_wholesale'] as num));
      expect(after[0]['menu_price'], 80);
    });

    test('unused raw material is not in use; items without ingredients '
        'keep their prices', () async {
      final database = await db.database;
      expect(await db.isRawMaterialInUse(cashew), isFalse);

      final before = await database.query('item_master', where: 'item_id = 2');
      await db.recalculateItemPrices(2);
      final after = await database.query('item_master', where: 'item_id = 2');
      expect(after.first['price_wholesale'], before.first['price_wholesale']);
      expect(after.first['price_retail'], before.first['price_retail']);
    });

    test('saving ingredients replaces them and keeps created time', () async {
      final database = await db.database;
      final before =
          await database.query('item_ingredient', where: 'item_id = 1');
      final maidaRow = before.firstWhere((r) => r['rm_id'] == maida);
      await db.saveItemIngredients(1, [
        {'rm_id': maida, 'quantity': 100, 'unit_id': maidaRow['unit_id']},
      ]);
      final after =
          await database.query('item_ingredient', where: 'item_id = 1');
      expect(after.length, 1);
      expect(after.first['created_datetime'], maidaRow['created_datetime']);
    });

    test('deleting an item removes its ingredients', () async {
      final database = await db.database;
      await db.deleteItem('item_master', 3);
      final left =
          await database.query('item_ingredient', where: 'item_id = 3');
      expect(left, isEmpty);
    });
  });
}
