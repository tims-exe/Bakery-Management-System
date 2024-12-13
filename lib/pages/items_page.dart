// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import '../database/dbhelper.dart';
import 'order_page.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  // colours
  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  // database helper
  final DbHelper _dbhelper = DbHelper();

  double headingTextSize = 20;
  double headingSize = 120;
  double orderSize = 90;
  double orderTextSize = 18;
  String rs = '₹';
  String currentCustomer = 'All Customers';
  int currentCustomerId = 0;

  String _ordersFilter = 'delivery_date DESC';

  //final Map<String, dynamic> _currentBill = {};
  List<Map<String, dynamic>> _currentOrder = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _allItems = [];

  List<Map<String, dynamic>> customers = [];

  // fetch order header and items
  List<Map<String, dynamic>> orderHeader = [];
  List allOrderDetails = [];

  void getOrderDetails() async {
    List<Map<String, dynamic>> getHeader =
        await _dbhelper.getOrderHeader('order_header', 'bill_number DESC');
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
      allOrderDetails.add(fetchedOrder);
    }
    orderHeader =
        getHeader.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<Map<String, dynamic>>> getOrder(String filter) async {
    List<Map<String, dynamic>> getHeader;
    if (currentCustomer == 'All Customers') {
      getHeader = await _dbhelper.getOrderHeader('order_header', filter);
    } else {
      getHeader = await _dbhelper.getOrderHeaderCustomer(
          'order_header', currentCustomerId);
    }
    orderHeader =
        getHeader.map((item) => Map<String, dynamic>.from(item)).toList();
    return getHeader;
  }

  String getBillDate(String date) {
    List<String> parts = date.split('-');
    return parts.reversed.join('-');
  }

  void getCustomerList() async {
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

  bool getCheckBoxValue(int value) {
    if (value == 1) {
      return true;
    }
    return false;
  }

  void setCheckBoxValue(String key, int index, bool? value) {
    if (value != null) {
      orderHeader[index] = Map.from(orderHeader[index]);
      orderHeader[index][key] = value ? 1 : 0;
    }
  }

  void _loadUnits() async {
    List<Map<String, dynamic>> units = await _dbhelper.getUnits('unit_master');
    List<Map<String, dynamic>> items = await _dbhelper
        .getUnits('item_master'); // reuse same method for similar db request
    _units = units;
    _allItems = items;
  }

  String _getItemName(int index) {
    for (int i = 0; i < _allItems.length; i++) {
      if (_allItems[i]['item_id'] == index) {
        return _allItems[i]['item_name'];
      }
    }
    return '.';
  }

  String _getUnitId(int index) {
    for (int i = 0; i < _units.length; i++) {
      if (_units[i]['unit_id'] == index) {
        return _units[i]['unit_name'];
      }
    }
    return '.';
  }

  String formatDate(String date) {
    List<String> parts = date.split('-');

    String formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';

    return formattedDate;
  }

  Future<void> getCurrentOrder(String bill_number_type,
      int bill_number_financial_year, int bill_number) async {
    String tableName = 'order_details';
    List<String> conditions = [
      'bill_number_type = ?',
      'bill_number_financial_year = ?',
      'bill_number = ?',
    ];
    List<dynamic> conditionArgs = [
      bill_number_type,
      bill_number_financial_year,
      bill_number,
    ];

    List<Map<String, dynamic>> orderItems =
        await _dbhelper.getOrderItems(tableName, conditions, conditionArgs);
    _currentOrder.clear();
    for (Map<String, dynamic> item in orderItems) {
      _currentOrder.add({
        'id': item['item_id'],
        'item': _getItemName(item['item_id']), //
        'no': item['number_of_items'],
        'price': item['base_rate'],
        'weight': item['base_quantity'],
        'unit': _getUnitId(item['base_unit_id']),
        'sell_unit': _getUnitId(item['sell_unit_id']),
        'unit_id': item['base_unit_id'],
        'sell_qnty': item['sell_quantity'],
        'sell_unit_id': item['sell_unit_id'],
        'conversion': item['base_quantity'],
        'sell_rate': item['sell_rate'],
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCustomerList();
    _loadUnits();
    /* Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        
      });
    }); */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
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
                    'Orders',
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
              // main container
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40, left: 30),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 620,
                        child: Column(
                          children: [
                            // list of headers
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                      alignment: Alignment.centerLeft,
                                      //color: Colors.amber,
                                      width: 100,
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                              _ordersFilter = 'bill_number DESC';
                                          });
                                        },
                                        child: Text(
                                          'Bill No',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: headingTextSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _ordersFilter = 'delivery_date DESC';
                                        });
                                      },
                                      child: Text(
                                        'Delivery',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: headingTextSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize + 20,
                                    child: TextButton(
                                      onPressed: () {},
                                      onLongPress: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            var m_customers =
                                                List<Map<String, dynamic>>.from(
                                                    customers);
                                            m_customers.insert(0, {
                                              'customer_id': 0,
                                              'customer_name': 'All Customers'
                                            });
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text(
                                                'Customers',
                                                textAlign: TextAlign.center,
                                              ),
                                              content: SizedBox(
                                                height: double.maxFinite,
                                                width: 900,
                                                child: SingleChildScrollView(
                                                  child: Wrap(
                                                    spacing:
                                                        8.0, // Horizontal spacing between items
                                                    runSpacing:
                                                        8.0, // Vertical spacing between rows
                                                    children: m_customers
                                                        .map((customer) {
                                                      return SizedBox(
                                                        width:
                                                            200, // Set width for each item
                                                        child: ListTile(
                                                          title: Text(customer[
                                                              'customer_name']),
                                                          onTap: () {
                                                            setState(() {
                                                              currentCustomer =
                                                                  customer[
                                                                      'customer_name'];
                                                              currentCustomerId =
                                                                  customer[
                                                                      'customer_id'];
                                                              Navigator.pop(
                                                                  context);
                                                            });
                                                            m_customers.remove({
                                                              'customer_id': 0,
                                                              'customer_name':
                                                                  'All Customers'
                                                            });
                                                          },
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        'Customer',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: headingTextSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize,
                                    child: Text(
                                      'Total Amt',
                                      style: TextStyle(
                                        fontSize: headingTextSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize,
                                    child: Text(
                                      'Paid Amt',
                                      style: TextStyle(
                                        fontSize: headingTextSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize,
                                    child: Text(
                                      'Balance Amt',
                                      style: TextStyle(
                                        fontSize: headingTextSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: headingSize,
                                    child: Text(
                                      'Delivered',
                                      style: TextStyle(
                                        fontSize: headingTextSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    width: headingSize,
                                    child: Text(
                                      'Bill Sent',
                                      style: TextStyle(
                                        fontSize: headingTextSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Divider(
                                thickness: 1.5,
                                color: _grey,
                                height: 10, // Space above and below the line
                              ),
                            ),
                            Expanded(
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: getOrder(_ordersFilter),
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
                                  final data = snapshot.data!;
                                  return ListView.builder(
                                    itemCount: data.length,
                                    itemBuilder: (context, index) {
                                      final header = data[index];
                                      var mutableHeader =
                                          Map<String, dynamic>.from(
                                              data[index]);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: MaterialButton(
                                                onLongPress: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Colors.white,
                                                        content: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              //width: 150,
                                                              height: 30,
                                                              alignment: Alignment
                                                                  .bottomCenter,
                                                              child: const Text(
                                                                'Delete Order ?',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 20,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.delete),
                                                              color: Colors.red,
                                                              iconSize: 30,
                                                              onPressed:
                                                                  () async {
                                                                await _dbhelper.deleteOrder(
                                                                    'order_details',
                                                                    header[
                                                                        'bill_number_type'],
                                                                    header[
                                                                        'bill_number_financial_year'],
                                                                    header[
                                                                        'bill_number']);
                                                                await _dbhelper.deleteOrder(
                                                                    'order_header',
                                                                    header[
                                                                        'bill_number_type'],
                                                                    header[
                                                                        'bill_number_financial_year'],
                                                                    header[
                                                                        'bill_number']);
                                                                setState(() {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                onPressed: () async {
                                                  mutableHeader['produced'] == 1
                                                      ? mutableHeader[
                                                          'produced'] = true
                                                      : mutableHeader[
                                                          'produced'] = false;
                                                  mutableHeader[
                                                              'sticker_print'] ==
                                                          1
                                                      ? mutableHeader[
                                                              'sticker_print'] =
                                                          true
                                                      : mutableHeader[
                                                              'sticker_print'] =
                                                          false;
                                                  mutableHeader['bill_sent'] ==
                                                          1
                                                      ? mutableHeader[
                                                          'bill_sent'] = true
                                                      : mutableHeader[
                                                          'bill_sent'] = false;
                                                  mutableHeader['delivered'] ==
                                                          1
                                                      ? mutableHeader[
                                                          'delivered'] = true
                                                      : mutableHeader[
                                                          'delivered'] = false;
                                                  mutableHeader[
                                                              'payment_done'] ==
                                                          1
                                                      ? mutableHeader[
                                                          'payment_done'] = true
                                                      : mutableHeader[
                                                              'payment_done'] =
                                                          false;
                                                  mutableHeader['bill_date'] =
                                                      formatDate(mutableHeader[
                                                          'bill_date']);
                                                  mutableHeader[
                                                          'delivery_date'] =
                                                      formatDate(mutableHeader[
                                                          'delivery_date']);
                                                  await getCurrentOrder(
                                                      header[
                                                          'bill_number_type'],
                                                      header[
                                                          'bill_number_financial_year'],
                                                      header['bill_number']);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderPage(
                                                        getBill: mutableHeader,
                                                        getOrder: _currentOrder,
                                                        onSaveBill:
                                                            (updatedBill) {
                                                          setState(() {});
                                                        },
                                                        onSaveOrder:
                                                            (updatedOrder) {},
                                                        isEdit: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      width: orderSize,
                                                      child: Text(
                                                        header['bill_number']
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 35,
                                                    ),
                                                    Container(
                                                      //color: Colors.amber,
                                                      alignment:
                                                          Alignment.center,
                                                      width: orderSize + 10,
                                                      child: Text(
                                                        getBillDate(header[
                                                            'delivery_date']),
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 30,
                                                    ),
                                                    Container(
                                                      //color: Colors.amber,
                                                      alignment:
                                                          Alignment.center,
                                                      width: orderSize + 50,
                                                      child: Text(
                                                        getCustomer(header[
                                                                'customer_id'])
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 35,
                                                    ),
                                                    Container(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      width: orderSize,
                                                      child: Text(
                                                        '$rs${(header['total_amount'] + header['delivery_charges'] - header['discount_amount']).toString()}',
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 60,
                                                    ),
                                                    Container(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      width: orderSize,
                                                      child: Text(
                                                        '$rs${(header['advance_paid'] + header['final_payment']).toString()}',
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 80,
                                                    ),
                                                    Container(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      width: orderSize,
                                                      child: Text(
                                                        //'$rs${(header['total_amount'] + header['delivery_charges'] - header['discount_amount'] - (header['advance_paid'] + header['final_payment'])).toString()}',
                                                        () {
                                                          num amount = header[
                                                                  'total_amount'] +
                                                              header[
                                                                  'delivery_charges'] -
                                                              header[
                                                                  'discount_amount'] -
                                                              (header['advance_paid'] +
                                                                  header[
                                                                      'final_payment']);
                                                          String
                                                              formattedAmount =
                                                              amount % 1 == 0
                                                                  ? amount
                                                                      .toInt()
                                                                      .toString()
                                                                  : amount
                                                                      .toString();

                                                          // Return the formatted text with the currency symbol
                                                          return '$rs$formattedAmount';
                                                        }(),
                                                        style: TextStyle(
                                                            fontSize:
                                                                orderTextSize),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 230,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Checkbox(
                                                    activeColor: _orange,
                                                    value: getCheckBoxValue(
                                                        orderHeader[index]
                                                            ['delivered']),
                                                    onChanged: (bool? value) {},
                                                  ),
                                                  Checkbox(
                                                    activeColor: _orange,
                                                    value: getCheckBoxValue(
                                                        orderHeader[index]
                                                            ['bill_sent']),
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
