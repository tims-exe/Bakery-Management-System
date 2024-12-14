import 'package:flutter/material.dart';
import 'package:nissy_bakes_app/components/coming_soon.dart';

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



  // OLD CODE
  /* List<Map<String, dynamic>> customers = [];

  List<Map<String, dynamic>> notProducedOrderHeader = [];
  List orderDetails = [];

  Future<List<Map<String, dynamic>>> getOrderDetails() async {
    List<Map<String, dynamic>> getHeader =
        await _dbhelper.getNotProducedOrderHeader('order_header');
    for (int i = 0; i < getHeader.length; i++) {
      List<Map<String, dynamic>> fetchedOrder = await _dbhelper.getOrderItems(
        'order_details',
        [
          'bill_number_type = ?',
          'bill_number_financial_year = ?',
          'bill_number = ?',
        ],
        [
          getHeader[i]['bill_number_type'],
          getHeader[i]['bill_number_financial_year'],
          getHeader[i]['bill_number'],
        ],
      );
      orderDetails.add(fetchedOrder);
    }
    notProducedOrderHeader =
        getHeader.map((item) => Map<String, dynamic>.from(item)).toList();
    debugPrint(notProducedOrderHeader.toString());
    debugPrint('***');
    debugPrint(orderDetails.toString());

    return notProducedOrderHeader;
  }

  Future getCustomerList() async {
    customers = await _dbhelper.getCustomers('customer_master');
  }

  String getCustomer(int id) {
    for (var c in customers) {
      if (c['customer_id'] == id) {
        return c['customer_name'];
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        getCustomerList();
      });
    });
  } */

  final String _filter = 'all';

  //List<Map<String, dynamic>> morningOrder = [];

  List<Map<String, dynamic>> productionList = [];
  

  Future<List<Map<String, dynamic>>> getProductionOrders(String productionTime) async {
    List<Map<String, dynamic>> orderHeader = [];
    List<Map<String, dynamic>> orderDetails = [];
    List<Map<String, dynamic>> productionItems = [];
    /*
    {
      item_id : 
      item_name :
      sell_unit :
      qnty :  
      produced :
    }
     */

    if (_filter == 'all'){
      // select * from order_header where produced = 0 and delivery_time
      if (productionTime == 'morning'){
        orderHeader = await _dbhelper.getOrderHeaderProduction('order_header', ['delivery_time <= ?'], ['11:00:00']);
      }
      else if (productionTime == 'afternoon'){
        orderHeader = await _dbhelper.getOrderHeaderProduction('order_header', ['delivery_time > ?', 'delivery_time <= ?'], ['11:00:00', '15:00:00']);
      }
      else {
        orderHeader = await _dbhelper.getOrderHeaderProduction('order_header', ['delivery_time > ?'], ['15:00:00']);
      }
    }
    // add other filters for today, tomorrow, specific date

    // get items from this order header
    
    List<String> conditions = [
      'bill_number_type = ?',
      'bill_number_financial_year = ?',
      'bill_number = ?',
      'produced = ?',
    ];
    
    for (int i = 0; i < orderHeader.length; i++){

      String orderDate = orderHeader[i]['delivery_date'];
      String orderTime = orderHeader[i]['delivery_time'];

      List<dynamic> conditionArgs = [
        orderHeader[i]['bill_number_type'],
        orderHeader[i]['bill_number_financial_year'],
        orderHeader[i]['bill_number'],
        0,
      ];
      orderDetails = await _dbhelper.getOrderItems('order_details', conditions, conditionArgs);
      productionList = productionList + orderDetails;

      // update morning order with order details (check if morning, noon, evening)
      // on checking an item check through morning order and set produced of item as 1

      for (int j = 0; j < orderDetails.length; j++){
        String sellUnit = await _dbhelper.getUnitName(orderDetails[j]['sell_unit_id']);
        String itemName = await _dbhelper.getItemName(orderDetails[j]['item_id']);
        //bool check = productionItems.any((map) => map['item_id'] == targetItemId);
        if (
          productionItems.any((map) => map['item_id'] == orderDetails[j]['item_id']) &&
          productionItems.any((map) => map['sell_unit'] == sellUnit) &&
          productionItems.any((map) => map['sell_weight'] == orderDetails[j]['sell_quantity'])
        ){
          for (var map in productionItems) {
            if (
              map['item_id'] == orderDetails[j]['item_id'] &&
              map['sell_unit'] == sellUnit &&
              map['sell_weight'] == orderDetails[j]['sell_quantity']
            ) {
              map['quantity'] += orderDetails[j]['number_of_items'];
              map['produced'] = orderDetails[j]['produced'];

              if (map['formula'] == 'num_x_sellqnty'){
                map['display'] = '${(map['quantity'] * orderDetails[j]['sell_quantity'])} $itemName';
              }
              else if (map['formula'] == 'num_item_sellqnty'){
                map['display'] = '${map['quantity']} $itemName (${orderDetails[j]['sell_quantity']} $sellUnit)';
              }
              else{
                map['display'] = '${(map['quantity'] * orderDetails[j]['sell_quantity'])} $itemName ($sellUnit)';
              }
            }
          }
        }
        else {
          sellUnit = await _dbhelper.getUnitName(orderDetails[j]['sell_unit_id']);
          String unitFormula = await _dbhelper.getUnitFormula(orderDetails[j]['sell_unit_id']);
          String displayText = '';

          if (unitFormula == 'num_x_sellqnty'){
            displayText = '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName';
          }
          else if (unitFormula == 'num_item_sellqnty'){
            displayText = '${orderDetails[j]['number_of_items']} $itemName (${orderDetails[j]['sell_quantity']} $sellUnit)';
          }
          else{
            displayText = '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName ($sellUnit)';
          }


          productionItems.add({
            'item_id': orderDetails[j]['item_id'],
            'item_name': itemName,
            'sell_unit' : sellUnit,
            'sell_unit_id': orderDetails[j]['sell_unit_id'],
            'sell_weight': orderDetails[j]['sell_quantity'],
            'quantity' : orderDetails[j]['number_of_items'],
            'produced': orderDetails[j]['produced'],
            'time': productionTime,
            'date': orderDate,
            'formula': unitFormula,
            'display' : displayText,
          });
        }
      }
    }

    /* print('*********');
    for (int i = 0; i < productionItems.length; i++){
      print(productionItems[i]);
    } */

    return productionItems;
  }

  void handleCheckBox(Map<String, dynamic> item) async {
    String startTime = '';
    String endTime = '';
    if (_filter == 'all'){
      if (item['time'] == 'morning'){
        startTime = '00:00:00';
        endTime = '11:00:00';
      }
      else if (item['time'] == 'afternoon') {
        startTime = '11:00:01';
        endTime = '15:00:00';
      }
      else {
        startTime = '15:00:01';
        endTime = '23:59:59';
      }
    }

    await _dbhelper.updateProducedItem(item['item_id'].toString(), item['sell_weight'].toString(), item['sell_unit_id'].toString(), startTime, endTime);
    
    // for all the other filters specify the date as well
    setState(() {});
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
                    },
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 30,
                  ),
                  // title
                  Text(
                    'Production',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(
                    width: 45,
                  )
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
              Container(
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Text(
                                '(Till 11am)',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 15,),

                          // Divider
                          Divider(
                            thickness: 1,
                            color: _grey,
                            height: 5, // Space above and below the line
                            indent: 20,
                            endIndent: 20,
                          ),

                          // Contents
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 15, top: 10),
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: getProductionOrders('morning'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error : ${snapshot.error}'),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  item['display'], 
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.check_box_outline_blank)
                                            ],
                                          ),
                                          onTap: () {
                                            if (item['produced'] == 0) {
                                              handleCheckBox(item);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  );
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Text(
                                '(11am to 3pm)',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 15,),

                          // Divider
                          Divider(
                            thickness: 1,
                            color: _grey,
                            height: 5, // Space above and below the line
                            indent: 20,
                            endIndent: 20,
                          ),

                          // Contents
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 15, top: 10),
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: getProductionOrders('afternoon'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error : ${snapshot.error}'),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  item['display'], 
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.check_box_outline_blank)
                                            ],
                                          ),
                                          onTap: () {
                                            if (item['produced'] == 0) {
                                              handleCheckBox(item);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  );
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
                    // Evening Section
                    Expanded(
                      child: Column(
                        children: [
                          const Column(
                            children: [
                              Text(
                                'Evening',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Text(
                                '(After 3pm)',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 15,),

                          // Divider
                          Divider(
                            thickness: 1,
                            color: _grey,
                            height: 5, // Space above and below the line
                            indent: 20,
                            endIndent: 20,
                          ),

                          // Contents
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 15, top: 10),
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: getProductionOrders('evening'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error : ${snapshot.error}'),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                                          title: item['produced'] == 0 ?
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 300,
                                                  child: Text(
                                                    item['display'], 
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.check_box_outline_blank)
                                              ],
                                            ) :
                                            Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                child: Text(
                                                  item['display'], 
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.check_box, color: _orange,)
                                            ],
                                          ),
                                          onTap: () {
                                            if (item['produced'] == 0) {
                                              handleCheckBox(item);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
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
