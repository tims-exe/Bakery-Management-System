import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:nissy_bakes_app/components/coming_soon.dart';

import '../database/dbhelper.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  // database helper
  final DbHelper _dbhelper = DbHelper();

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  DateTime _date = DateTime.now();

  String _filter = 'Today';
  final List<String> _allFilters = ['All', 'Today', 'Tomorrow'];
  int _filterIndex = 1;

  //List<Map<String, dynamic>> morningOrder = [];

  Map<String, dynamic> _allProductions = {};


  /* Future<List<Map<String, dynamic>>> getMorningProductionItems() async {
    List<Map<String, dynamic>> orderHeader = [];
    List<Map<String, dynamic>> orderDetails = [];
    List<Map<String, dynamic>> productionItems = [];

    String startTime = '00:00:00';
    String endTime = '11:00:00';

    if (_filter == 'All'){
      orderHeader = await _dbhelper.getOrderHeaderCondition('order_header', ['delivery_time >= ?', 'delivery_time <= ?'], [startTime, endTime], true);
    }
    else {
      String currentDate = '${_date.year.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      orderHeader = await _dbhelper.getOrderHeaderCondition('order_header', ['delivery_time >= ?', 'delivery_time <= ?', 'delivery_date = ?'],[startTime, endTime, currentDate], true);
    }

    List<String> conditions = [
      'bill_number_type = ?',
      'bill_number_financial_year = ?',
      'bill_number = ?',
    ];

  } */

  Future<List<Map<String, dynamic>>> getProductionOrders(
      String productionTime) async {
    List<Map<String, dynamic>> orderHeader = [];
    List<Map<String, dynamic>> orderDetails = [];
    List<Map<String, dynamic>> productionItems = [];
    _allProductions.clear();
    /*
    {
      item_id : 
      item_name :
      sell_unit :
      qnty :  
      produced :
    }
     */

    String startTime = '';
    String endTime = '';
    String currentDate = '';

    if (productionTime == 'morning') {
      startTime = '00:00:00';
      endTime = '11:00:00';
    } else if (productionTime == 'afternoon') {
      startTime = '11:00:01';
      endTime = '15:00:00';
    } else {
      startTime = '15:00:01';
      endTime = '23:59:59';
    }

    if (_filter == 'All') {
      // select * from order_header where produced = 0 and delivery_time
      orderHeader = await _dbhelper.getOrderHeaderCondition('order_header', ['delivery_time >= ?', 'delivery_time <= ?'], [startTime, endTime], false);
    } else {
      /* if (_filter == 'today'){
        _date = DateTime.now();
      }
      else if (_filter == 'tomorrow'){
        _date = DateTime.now().add(const Duration(days: 1));
      }
      else {
        
      } */
      currentDate = '${_date.year.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      orderHeader = await _dbhelper.getOrderHeaderCondition('order_header', ['delivery_time >= ?', 'delivery_time <= ?', 'delivery_date = ?'],[startTime, endTime, currentDate], false);
    }
    // add other filters for today, tomorrow, specific date

    // get items from this order header

    List<String> conditions = [
      'bill_number_type = ?',
      'bill_number_financial_year = ?',
      'bill_number = ?',
      'produced = ?',
    ];

    for (int i = 0; i < orderHeader.length; i++) {
      String orderDate = orderHeader[i]['delivery_date'];
      //String orderTime = orderHeader[i]['delivery_time'];

      List<dynamic> conditionArgs = [
        orderHeader[i]['bill_number_type'],
        orderHeader[i]['bill_number_financial_year'],
        orderHeader[i]['bill_number'],
        0,
      ];
      orderDetails = await _dbhelper.getOrderItems('order_details', conditions, conditionArgs);
      //productionList = productionList + orderDetails;

      // update morning order with order details (check if morning, noon, evening)
      // on checking an item check through morning order and set produced of item as 1

      for (int j = 0; j < orderDetails.length; j++) {

        String sellUnit = await _dbhelper.getUnitName(orderDetails[j]['sell_unit_id']);
        String itemName = await _dbhelper.getItemName(orderDetails[j]['item_id']);
        //bool check = productionItems.any((map) => map['item_id'] == targetItemId);
        //print('${orderDetails[j]['item_id']} : ${orderDetails[j]['delivery_date']}');

        /* if (_filter == 'All' && productionTime == 'morning'){
          print(_filter);
          print('***************');
          print('$itemName $sellUnit ${orderDetails[j]['item_id']} ${orderHeader[i]['delivery_date']} $productionTime');
          count++;
        }
        print(count); */

        if (
          productionItems.any((map) => map['item_id'] == orderDetails[j]['item_id']) &&
          productionItems.any((map) => map['sell_unit'] == sellUnit) &&
          productionItems.any((map) => map['sell_weight'] == orderDetails[j]['sell_quantity']) &&
          productionItems.any((map) => map['date'] == orderHeader[i]['delivery_date']) &&
          productionItems.any((map) => map['time'] == productionTime)
        ) {
          for (var map in productionItems) {
            if (
              map['item_id'] == orderDetails[j]['item_id'] &&
              map['sell_unit'] == sellUnit &&
              map['sell_weight'] == orderDetails[j]['sell_quantity'] &&
              map['date'] == orderHeader[i]['delivery_date'] &&
              map['time'] == productionTime
            ) {
              map['quantity'] += orderDetails[j]['number_of_items'];
              map['produced'] = orderDetails[j]['produced'];

              if (map['formula'] == 'num_x_sellqnty') {
                map['display'] =
                    '${(map['quantity'] * orderDetails[j]['sell_quantity'])} $itemName';
              } else if (map['formula'] == 'num_item_sellqnty') {
                map['display'] =
                    '${map['quantity']} $itemName (${orderDetails[j]['sell_quantity']} $sellUnit)';
              } else {
                map['display'] =
                    '${(map['quantity'] * orderDetails[j]['sell_quantity'])} $itemName ($sellUnit)';
              }
            }
          }
        } else {
          sellUnit =
              await _dbhelper.getUnitName(orderDetails[j]['sell_unit_id']);
          String unitFormula =
              await _dbhelper.getUnitFormula(orderDetails[j]['sell_unit_id']);
          String displayText = '';

          if (unitFormula == 'num_x_sellqnty') {
            displayText = '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName';
          } else if (unitFormula == 'num_item_sellqnty') {
            displayText = '${orderDetails[j]['number_of_items']} $itemName (${orderDetails[j]['sell_quantity']} $sellUnit)';
          } else {
            displayText = '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName ($sellUnit)';
          }

          productionItems.add({
            'bill_num': orderDetails[j]['bill_number'],
            'item_id': orderDetails[j]['item_id'],
            'item_name': itemName,
            'sell_unit': sellUnit,
            'sell_unit_id': orderDetails[j]['sell_unit_id'],
            'sell_weight': orderDetails[j]['sell_quantity'],
            'quantity': orderDetails[j]['number_of_items'],
            'produced': orderDetails[j]['produced'],
            'time': productionTime,
            'date': orderDate,
            'formula': unitFormula,
            'display': displayText, 
          });
        }
      }
    }

    if (_filter == 'All') {
      for (int i = 0; i < productionItems.length; i++){
        /* print('//////');
        print(productionItems[i]); */
        if (_allProductions.containsKey('${productionItems[i]['date']}:${productionItems[i]['time']}')){
          _allProductions['${productionItems[i]['date']}:${productionItems[i]['time']}'] = _allProductions['${productionItems[i]['date']}:${productionItems[i]['time']}'] + [productionItems[i]];
          //print([productionItems[i]]);
        }
        else {
          _allProductions['${productionItems[i]['date']}:${productionItems[i]['time']}'] = [productionItems[i]];
        }
      }

      _allProductions = Map.fromEntries(
        _allProductions.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key))
      );
    };

    return productionItems;
  }

  void handleCheckBox(Map<String, dynamic> item) async {
    String startTime = '';
    String endTime = '';
    if (item['time'] == 'morning') {
      startTime = '00:00:00';
      endTime = '11:00:00';
    } else if (item['time'] == 'afternoon') {
      startTime = '11:00:01';
      endTime = '15:00:00';
    } else {
      startTime = '15:00:01';
      endTime = '23:59:59';
    }
    /* if (_filter == 'All') {
      await _dbhelper.updateProducedItem(
        item['item_id'].toString(),
        item['sell_weight'].toString(),
        item['sell_unit_id'].toString(),
        startTime,
        endTime
      );
    }
    else {
      await _dbhelper.updateProducedItemDate(
        item['item_id'].toString(),
        item['sell_weight'].toString(),
        item['sell_unit_id'].toString(),
        startTime, 
        endTime, 
        item['date'],
      );
    } */
   await _dbhelper.updateProducedItemDate(
      item['item_id'].toString(),
      item['sell_weight'].toString(),
      item['sell_unit_id'].toString(),
      startTime, 
      endTime, 
      item['date'],
    );

    // for all the other filters specify the date as well
    setState(() {});
  }

  String getSectionDate(String input){
    DateTime parsedDate = DateTime.parse(input);
    String formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
    return formattedDate;
  }

  /* void display(){
    _allProductions.forEach((key, value) {
      print('$key: $value');
    });
  } */

  Widget dividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // close button
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    //display();
                  },
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 30,
                ),
                // title
                Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: Text(
                    'Production',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_allFilters.contains(_filter)){
                        _filterIndex = (_filterIndex + 1) % (_allFilters.length);
                        _filterIndex == 1 ? _date = DateTime.now() : _date = DateTime.now().add(Duration(days: 1));
                      }
                      else{
                        _filterIndex = 1;
                        _date = DateTime.now();
                      }
                      setState(() {
                        _filter = _allFilters[_filterIndex];
                      });
                    },
                    onLongPress: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(3000),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _date = pickedDate;
                          _filter = '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _filter,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            // heading line
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
              child: Divider(
                thickness: 2.5,
                color: _grey,
                height: 35, // Space above and below the line
              ),
            ),
            SizedBox(
              height: 630,
              child: Row(
                children: [
                  // Morning Section
                  Expanded(
                    child: Column(
                      children: [
                        const Column(
                          children: [
                            Text(
                              'Morning',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '(Till 11am)',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),

                        // Divider
                        Divider(
                          thickness: 1,
                          color: _grey,
                          height: 5, // Space above and below the line
                          indent: 20,
                          endIndent: 20,
                        ),

                        // Contents
                        /* Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: getMorningProductionItems(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error : ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('No items found'),
                                  );
                                }
                                final items = snapshot.data!;
                                return ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: ListTile(
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: 280,
                                              child: Text(
                                                item['display'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (item['produced'] == 0) {
                                                  handleCheckBox(item);
                                                }
                                              }, 
                                              icon: const Icon(Icons.check_box_outline_blank),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            ),
                          ),
                        ) */


                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 10),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: getProductionOrders('morning'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error : ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('No items found'),
                                  );
                                }
                                final items = snapshot.data!;
                                if (_filter == 'All') {
                                  /* for (var map in items) {
                                    print("Map:");
                                    for (var entry in map.entries) {
                                      print("${entry.key}: ${entry.value}");
                                    }
                                    print("");
                                  }
                                  print(items.length); */
                                  Map<String, dynamic> specificProduction = Map.fromEntries(
                                    _allProductions.entries.where((entry) => 
                                      entry.key.contains(':morning')
                                    )
                                  );
                                  return ListView.builder(
                                    itemCount: specificProduction.length,
                                    itemBuilder: (context, index) {
                                      // get section date 
                                      String sectionKey = specificProduction.keys.elementAt(index).split(':')[0];
                                      
                                      // Get the list of items for this section
                                      List<dynamic> sectionItems = specificProduction[specificProduction.keys.elementAt(index)];

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Section Header
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: dividerWithText(getSectionDate(sectionKey))
                                          ),
                                          
                                          // List of items for this section
                                          ...sectionItems.map((item) => ListTile(
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 280,
                                                  child: Text(
                                                    item['display'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                onPressed: () {
                                                  if (item['produced'] == 0) {
                                                    handleCheckBox(item);
                                                  }
                                                }, 
                                                icon: const Icon(Icons.check_box_outline_blank),
                                              ),
                                              ],
                                            ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                else {
                                  return ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 0),
                                        child: ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 280,
                                                child: Text(
                                                  item['display'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (item['produced'] == 0) {
                                                    handleCheckBox(item);
                                                  }
                                                }, 
                                                icon: const Icon(Icons.check_box_outline_blank),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: _grey,
                    thickness: 2.5,
                    width: 20, // Space around the divider
                  ),
                  // Afternoon Section
                  Expanded(
                    child: Column(
                      children: [
                        const Column(
                          children: [
                            Text(
                              'Afternoon',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '(11am to 3pm)',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),

                        // Divider
                        Divider(
                          thickness: 1,
                          color: _grey,
                          height: 5, // Space above and below the line
                          indent: 20,
                          endIndent: 20,
                        ),

                        // Contents
                        /* Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 15, top: 10),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: getProductionOrders('afternoon'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error : ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('No items found'),
                                  );
                                }
                                final items = snapshot.data!;
                                if (_filter == 'All') {
                                  Map<String, dynamic> specificProduction = Map.fromEntries(
                                    _allProductions.entries.where((entry) => 
                                      entry.key.contains(':afternoon')
                                    )
                                  );
                                  return ListView.builder(
                                    itemCount: specificProduction.length,
                                    itemBuilder: (context, index) {
                                      // get section date 
                                      String sectionKey = specificProduction.keys.elementAt(index).split(':')[0];
                                      
                                      // Get the list of items for this section
                                      List<dynamic> sectionItems = specificProduction[specificProduction.keys.elementAt(index)];

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Section Header
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: dividerWithText(getSectionDate(sectionKey))
                                          ),
                                          
                                          // List of items for this section
                                          ...sectionItems.map((item) => ListTile(
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 280,
                                                  child: Text(
                                                    item['display'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    if (item['produced'] == 0) {
                                                      handleCheckBox(item);
                                                    }
                                                  }, 
                                                  icon: const Icon(Icons.check_box_outline_blank),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                else {
                                  return ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 0),
                                        child: ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 280,
                                                child: Text(
                                                  item['display'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (item['produced'] == 0) {
                                                    handleCheckBox(item);
                                                  }
                                                }, 
                                                icon: const Icon(Icons.check_box_outline_blank),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ), */
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: _grey,
                    thickness: 2.5,
                    width: 20, // Space around the divider
                  ),
                  // Evening Section
                  Expanded(
                    child: Column(
                      children: [
                        const Column(
                          children: [
                            Text(
                              'Evening',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '(After 3pm)',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),

                        // Divider
                        Divider(
                          thickness: 1,
                          color: _grey,
                          height: 5, // Space above and below the line
                          indent: 20,
                          endIndent: 20,
                        ),

                        // Contents
                        /* Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 15, top: 10),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: getProductionOrders('evening'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error : ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('No items found'),
                                  );
                                }
                                final items = snapshot.data!;
                                if (_filter == 'All') {
                                  Map<String, dynamic> specificProduction = Map.fromEntries(
                                    _allProductions.entries.where((entry) => 
                                      entry.key.contains(':evening')
                                    )
                                  );
                                  return ListView.builder(
                                    itemCount: specificProduction.length,
                                    itemBuilder: (context, index) {
                                      // get section date 
                                      String sectionKey = specificProduction.keys.elementAt(index).split(':')[0];
                                      
                                      // Get the list of items for this section
                                      List<dynamic> sectionItems = specificProduction[specificProduction.keys.elementAt(index)];

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Section Header
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: dividerWithText(getSectionDate(sectionKey))
                                          ),
                                          
                                          // List of items for this section
                                          ...sectionItems.map((item) => ListTile(
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 280,
                                                  child: Text(
                                                    item['display'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    if (item['produced'] == 0) {
                                                      handleCheckBox(item);
                                                    }
                                                  }, 
                                                  icon: const Icon(Icons.check_box_outline_blank),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                else {
                                  return ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 0),
                                        child: ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 280,
                                                child: Text(
                                                  item['display'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (item['produced'] == 0) {
                                                    handleCheckBox(item);
                                                  }
                                                }, 
                                                icon: const Icon(Icons.check_box_outline_blank),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ), */
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
