import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

// initDb -> to help copy the database from the assets folder to sqflite database
// run this code once by calling the init function

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  Database? _database;

  factory DbHelper() {
    return _instance;
  }

  DbHelper._internal();

  Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nissybakesdb.db');

    // for deleting existing database......use carefully
    // await deleteDatabase(path);
    // debugPrint('Databse Deleted');

    final exist = await databaseExists(path);

    if (exist) {
      debugPrint('DB exists');
      debugPrint(dbPath);
    } else {
      debugPrint('creating DB');

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join('assets', 'nissybakesdb.db'));

      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(path).writeAsBytes(bytes, flush: true);

      debugPrint('DB copied');
    }
    return await openDatabase(path);
  }

  // Fetch Categories
  Future<List<Map<String, dynamic>>> getCategory(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<List<Map<String, dynamic>>> getMenu(String tableName) async {
    final db = await database;
    return await db.query(tableName, orderBy: 'item_name ASC');
  }

  // Fetch Items
  Future<List<Map<String, dynamic>>> getItems(
    String tableName,
    String condition, [
    List<dynamic>? conditionArgs,
  ]) async {
    final db = await database;
    return await db.query(
      tableName,
      where: condition,
      whereArgs: conditionArgs,
      //orderBy: 'item_name DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getSettings(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<String> getItemName(int id) async {
    final db = await database;
    List<Map<String, dynamic>> item = await db.rawQuery(
      'SELECT item_name FROM item_master WHERE item_id = $id',
    );
    return item[0]['item_name'];
  }

  Future<String> getCustomerName(int id) async {
    final db = await database;
    List<Map<String, dynamic>> item = await db.rawQuery(
      'SELECT customer_name, reference FROM customer_master WHERE customer_id = $id',
    );
    String name = '';
    if (item[0]['reference'] == '') {
      name = '${item[0]['customer_name']}';
    } else {
      name = '${item[0]['customer_name']} (${item[0]['reference']})';
    }
    return name;
  }

  Future<String> getCustomerPhone(int id) async {
    final db = await database;
    List<Map<String, dynamic>> item = await db.rawQuery(
      'SELECT customer_phone FROM customer_master WHERE customer_id = $id',
    );

    return item[0]['customer_phone'];
  }

  Future<String> getUnitName(int id) async {
    final db = await database;
    List<Map<String, dynamic>> unit = await db.rawQuery(
      'SELECT unit_name FROM unit_master WHERE unit_id = $id',
    );
    return unit[0]['unit_name'];
  }

  Future<String> getUnitFormula(int id) async {
    final db = await database;
    List<Map<String, dynamic>> unit = await db.rawQuery(
      'SELECT print_formula FROM unit_master WHERE unit_id = $id',
    );
    return unit[0]['print_formula'];
  }

  Future<int> updateProduced(
    int value,
    String billNumberType,
    String billNumberFinancialYear,
    String billNumber,
  ) async {
    final db = await database;
    return await db.rawUpdate(
      '''
      UPDATE order_details
      SET produced = ?
      WHERE bill_number_type = ?
        AND bill_number_financial_year = ?
        AND bill_number = ?
    ''',
      [value, billNumberType, billNumberFinancialYear, billNumber],
    );
  }

  Future<int> updateProducedItem(
    String id,
    String sellqnty,
    String sellUnitId,
    startTime,
    endTime,
  ) async {
    final db = await database;
    return await db.rawUpdate(
      '''
      UPDATE order_details
      SET produced = 1
      WHERE EXISTS (
        SELECT 1
        FROM order_header
        WHERE order_details.bill_number_type = order_header.bill_number_type
          AND order_details.bill_number_financial_year = order_header.bill_number_financial_year
          AND order_details.bill_number = order_header.bill_number
          AND order_header.delivery_time >= ?
          AND order_header.delivery_time <= ?
      )
      AND item_id = ?
      AND sell_quantity = ?
      AND sell_unit_id = ?;
    ''',
      [startTime, endTime, id, sellqnty, sellUnitId],
    );
  }

  Future<int> updateProducedItemDate(
    String id,
    String sellqnty,
    String sellUnitId,
    String startTime,
    String endTime,
    String date,
  ) async {
    final db = await database;
    return await db.rawUpdate(
      '''
      UPDATE order_details
      SET produced = 1
      WHERE EXISTS (
        SELECT 1
        FROM order_header
        WHERE order_details.bill_number_type = order_header.bill_number_type
          AND order_details.bill_number_financial_year = order_header.bill_number_financial_year
          AND order_details.bill_number = order_header.bill_number
          AND order_header.delivery_time >= ?
          AND order_header.delivery_time <= ?
          AND order_header.delivery_date = ?
      )
      AND item_id = ?
      AND sell_quantity = ?
      AND sell_unit_id = ?;
    ''',
      [startTime, endTime, date, id, sellqnty, sellUnitId],
    );
  }

  // fetch units
  Future<List<Map<String, dynamic>>> getUnits(String tablename) async {
    final db = await database;
    return await db.query(tablename);
  }

  // fetch next bill number
  Future<int?> getBillNumber(String tablename) async {
    final db = await database;

    var result = await db.rawQuery(
      'SELECT MAX(bill_number) as max_bill_number FROM $tablename',
    );

    if (result.isNotEmpty) {
      return result.first['max_bill_number'] as int?;
    }

    return null;
  }

  // fetch units
  Future<List<Map<String, dynamic>>> getCustomers(String tablename) async {
    final db = await database;
    return await db.query(tablename, orderBy: 'customer_name ASC');
  }

  // insert order header
  Future<int> insertHeader(Map<String, dynamic> header) async {
    final db = await database;
    return await db.insert('order_header', header);
  }

  // insert order details
  Future<void> inserOrder(List<Map<String, dynamic>> order) async {
    final db = await database;

    for (var item in order) {
      await db.insert('order_details', item);
    }
  }

  //insert menu item
  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('item_master', item);
  }

  // update menu item
  Future<int> updateItem(Map<String, dynamic> item, int itemId) async {
    final db = await database;
    return await db.update(
      'item_master',
      item,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteItem(String tableName, int itemId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  // insert customer
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;

    return await db.insert('customer_master', customer);
  }

  // update customer
  Future<int> updateCustomer(
    Map<String, dynamic> customer,
    int customerID,
  ) async {
    final db = await database;

    return await db.update(
      'customer_master',
      customer,
      where: 'customer_id = ?',
      whereArgs: [customerID],
    );
  }

  Future<int> updateOrderHeader(
    condition,
    value,
    billNumberType,
    billNumberFinancialYear,
    billNumber,
  ) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE order_header SET $condition = ? WHERE bill_number_type = ? AND bill_number_financial_year = ? AND bill_number = ?',
      [value, billNumberType, billNumberFinancialYear, billNumber],
    );
  }

  //update order header
  Future<int> updateHeader(
    Map<String, dynamic> header,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(
      'order_header',
      header,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  // fetch order header
  Future<List<Map<String, dynamic>>> getOrderHeader(
    String tablename,
    String filter,
  ) async {
    final db = await database;
    return await db.query(tablename, orderBy: filter);
  }

  // 2 conditions
  // order headers where time <= time specified and date = date specified and produced = 0
  // all order headers where time <= time specified and produced = 0
  Future<List<Map<String, dynamic>>> getOrderHeaderCondition(
    String tableName,
    List<String> condition,
    List<dynamic>? args,
    bool sort,
  ) async {
    final db = await database;
    final whereClause = condition.join(' AND ');
    if (sort) {
      return await db.query(
        tableName,
        where: whereClause,
        whereArgs: args,
        orderBy: 'delivery_time ASC',
      );
    } else {
      return await db.query(tableName, where: whereClause, whereArgs: args);
    }
  }

  // fetch order header
  Future<List<Map<String, dynamic>>> getOrderHeaderCustomer(
    String tablename,
    int customerId,
  ) async {
    final db = await database;

    String whereClause = 'customer_id = ?';
    List<dynamic> whereArgs = [customerId];

    return await db.query(
      tablename,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'bill_number DESC',
    );
  }

  // fetch order items based on order id
  Future<List<Map<String, dynamic>>> getOrderItems(
    String tableName,
    List<String> conditions, [
    List<dynamic>? conditionArgs,
  ]) async {
    final db = await database;
    final whereClause = conditions.join(' AND ');
    return await db.query(
      tableName,
      where: whereClause,
      whereArgs: conditionArgs,
    );
  }

  Future<bool> getOrderItemById(int Id) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      "order_details",
      where: "item_id = ?",
      whereArgs: [Id],
    );

    if (res.isEmpty) {
      return false;
    }
    return true;
  }

  // fetch order header of unproduced bills
  Future<List<Map<String, dynamic>>> getNotProducedOrderHeader(
    String tableName,
  ) async {
    final db = await database;
    return await db.query(tableName, where: 'produced = 0');
  }

  Future<void> copyDatabaseToDesktop() async {
    // /data/user/0/com.example.nissy_bakes_app/databases
    // /storage/emulated/0/Android/data/com.example.nissy_bakes_app/files

    var status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    var status1 = await Permission.storage.status;

    if (!status1.isGranted) {
      await Permission.storage.request();
    }

    try {
      File dbPath = File(
        '/data/user/0/com.example.nissy_bakes_original/databases/nissybakesdb.db',
      );
      //Directory? folderPath = Directory('/storage/emulated/0/NissyBakesBackup');
      await dbPath.copy('/storage/emulated/0/NissyBakesBackup/nissybakesdb.db');

      print('DATABASE COPIED');
    } catch (e) {
      print('=======================*Error : ${e.toString()}');
    }
  }

  // delete order items
  Future<void> deleteOrder(
    String tableName,
    String billNumberType,
    int billNumberFinancialYear,
    int billNumber,
  ) async {
    final db = await database;

    String whereClause =
        'bill_number_type = ? AND bill_number_financial_year = ? AND bill_number = ?';
    List<dynamic> whereArgs = [
      billNumberType,
      billNumberFinancialYear,
      billNumber,
    ];

    await db.delete(tableName, where: whereClause, whereArgs: whereArgs);
    print('Order from $tableName DELETED');
  }

  Future<void> deleteCustomer(String tableName, int customerID) async {
    final db = await database;

    String whereClause = 'customer_id = ?';

    List<dynamic> whereArgs = [customerID];

    await db.delete(tableName, where: whereClause, whereArgs: whereArgs);

    print('Customer from $tableName DELETED');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }
}
