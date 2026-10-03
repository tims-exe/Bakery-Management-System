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

    test('seeded ingredients and stored prices agree', () async {
      final database = await db.database;
      final rows = await db.getItemIngredients(1);
      expect(rows.length, 10);

      await db.recalculateItemPrices(1);
      final item = await database.query(
        'item_master',
        where: 'item_id = 1',
      );
      expect(item.first['price_wholesale'], 93);
      expect(item.first['price_retail'], 100);
      // menu price is never changed by recalculation
      expect(item.first['menu_price'], 80);
    });

    test('raw material cost change updates every item using it', () async {
      final database = await db.database;
      final maida = await database.query(
        'raw_material_master',
        where: "rm_name = 'Maida'",
      );
      final rmId = maida.first['rm_id'] as int;
      expect(await db.isRawMaterialInUse(rmId), isTrue);

      await database.update(
        'raw_material_master',
        {'cost': 450}, // 10x
        where: 'rm_id = ?',
        whereArgs: [rmId],
      );
      await db.recalculateItemsUsingRm(rmId);

      final items = await database.query(
        'item_master',
        columns: ['item_id', 'price_wholesale', 'menu_price'],
        where: 'item_id IN (1, 3, 5)',
        orderBy: 'item_id',
      );
      // all three items using Maida went up, menu prices untouched
      expect(items[0]['price_wholesale'] as num, greaterThan(93));
      expect(items[1]['price_wholesale'] as num, greaterThan(166));
      expect(items[2]['price_wholesale'] as num, greaterThan(222));
      expect(items[0]['menu_price'], 80);
    });

    test('unused raw material is not in use; items without ingredients '
        'keep their prices', () async {
      final database = await db.database;
      final cashew = await database.query(
        'raw_material_master',
        where: "rm_name = 'Cashew nuts'",
      );
      expect(await db.isRawMaterialInUse(cashew.first['rm_id'] as int), isFalse);

      final before = await database.query('item_master', where: 'item_id = 2');
      await db.recalculateItemPrices(2);
      final after = await database.query('item_master', where: 'item_id = 2');
      expect(after.first['price_wholesale'], before.first['price_wholesale']);
      expect(after.first['price_retail'], before.first['price_retail']);
    });

    test('saving ingredients replaces them and keeps created time', () async {
      final database = await db.database;
      final before = await database.query(
        'item_ingredient',
        where: 'item_id = 1',
      );
      final first = before.first;
      await db.saveItemIngredients(1, [
        {
          'rm_id': first['rm_id'],
          'quantity': 100,
          'unit_id': first['unit_id'],
        },
      ]);
      final after = await database.query(
        'item_ingredient',
        where: 'item_id = 1',
      );
      expect(after.length, 1);
      expect(after.first['created_datetime'], first['created_datetime']);
    });

    test('deleting an item removes its ingredients', () async {
      final database = await db.database;
      await db.deleteItem('item_master', 3);
      final left = await database.query(
        'item_ingredient',
        where: 'item_id = 3',
      );
      expect(left, isEmpty);
    });
  });
}
