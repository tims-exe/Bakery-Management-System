import 'package:flutter/material.dart';
//import 'package:nissy_bakes_app/components/coming_soon.dart';
import '../database/dbhelper.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final DbHelper _dbhelper = DbHelper();

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  DateTime _date = DateTime.now();

  String _filter = 'Today';
  final List<String> _allFilters = ['All', 'Today', 'Tomorrow'];
  int _filterIndex = 1;

  Map<String, dynamic> allOrderDetails = {};

  Future<List<Map<String, dynamic>>> getDeliveryLine() async {
    List<Map<String, dynamic>> orderHeader = [];
    List<Map<String, dynamic>> orderDetails = [];
    List<Map<String, dynamic>> deliveryLine = [];

    if (_filter == 'All') {
      orderHeader = await _dbhelper.getOrderHeaderCondition(
          'order_header', ['delivered = ?'], [0], true);
    } else {
      String currentDate =
          '${_date.year.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      orderHeader = await _dbhelper.getOrderHeaderCondition(
          'order_header', ['delivery_date = ?'], [currentDate], true);
    }

    List<String> conditions = [
      'bill_number_type = ?',
      'bill_number_financial_year = ?',
      'bill_number = ?',
    ];

    for (int i = 0; i < orderHeader.length; i++) {
      Map<String, dynamic> item = {};

      item['date'] = orderHeader[i]['delivery_date'];
      item['customer'] = await _dbhelper.getCustomerName(orderHeader[i]['customer_id']);
      item['bill_number'] = '${orderHeader[i]['bill_number_type']}${orderHeader[i]['bill_number_financial_year']}-${orderHeader[i]['bill_number']}';
      item['time'] = orderHeader[i]['delivery_time'];
      item['sticker'] = orderHeader[i]['sticker_print'];
      item['bill'] = orderHeader[i]['bill_sent'];
      item['paid'] = orderHeader[i]['payment_done'];
      item['delivered'] = orderHeader[i]['delivered'];
      item['items'] = [];
      item['bill_num_type'] = orderHeader[i]['bill_number_type'];
      item['bill_num_financial_year'] = orderHeader[i]['bill_number_financial_year'];
      item['bill_num'] = orderHeader[i]['bill_number'];

      List<dynamic> conditionArgs = [
        orderHeader[i]['bill_number_type'],
        orderHeader[i]['bill_number_financial_year'],
        orderHeader[i]['bill_number'],
      ];
      orderDetails = await _dbhelper.getOrderItems(
          'order_details', conditions, conditionArgs);

      for (int j = 0; j < orderDetails.length; j++) {
        String unitFormula =
            await _dbhelper.getUnitFormula(orderDetails[j]['sell_unit_id']);
        String itemName =
            await _dbhelper.getItemName(orderDetails[j]['item_id']);
        String sellUnit =
            await _dbhelper.getUnitName(orderDetails[j]['sell_unit_id']);
        String orderedItem = '';

        if (unitFormula == 'num_x_sellqnty') {
          orderedItem =
              '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName';
        } else if (unitFormula == 'num_item_sellqnty') {
          orderedItem =
              '${orderDetails[j]['number_of_items']} $itemName (${orderDetails[j]['sell_quantity']} $sellUnit)';
        } else {
          orderedItem =
              '${(orderDetails[j]['number_of_items'] * orderDetails[j]['sell_quantity'])} $itemName ($sellUnit)';
        }
        item['items'] += [
          [orderedItem, orderDetails[j]['produced']]
        ];
      }
      deliveryLine.add(item);
    }

    return deliveryLine;
  }

  String formatTime(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    String period = hour >= 12 ? 'pm' : 'am';

    hour = hour % 12;
    if (hour == 0) hour = 12; // Handle midnight and noon

    String formattedMinute = minute.toString().padLeft(2, '0');

    return '$hour:$formattedMinute $period';
  }

  void updateItem(String update, int value,  Map<String, dynamic> item) async {
    // if update is bill sent then send bill in whatsapp
    // if update is payment done then update final payment
    // once bill sent is checked then dont allow to uncheck that bill sent

    value == 0 ? value = 1 : value = 0;

    await _dbhelper.updateOrderHeader(update, value, item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']);
    setState(() {
      print('UPDATED !!!');
    }); 
  }

  @override
  Widget build(BuildContext context) {
    allOrderDetails.clear();
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
                    'Delivery',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_allFilters.contains(_filter)) {
                        _filterIndex =
                            (_filterIndex + 1) % (_allFilters.length);
                        _filterIndex == 1
                            ? _date = DateTime.now()
                            : _date = DateTime.now().add(Duration(days: 1));
                      } else {
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
                          _filter =
                              '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year.toString().padLeft(2, '0')}';
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getDeliveryLine(),
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
                  for (int i = 0; i < items.length; i++){
                    print(items[i]);
                    if (allOrderDetails.containsKey(items[i]['date'])){
                      allOrderDetails[items[i]['date']] += [items[i]];
                    }
                    else {
                      allOrderDetails[items[i]['date']] = [items[i]];
                    }
                  }

                  allOrderDetails = Map.fromEntries(
                    allOrderDetails.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
                  );
                  
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Column(
                        children: [
                          ListTile(
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  //color: Colors.amber,
                                  width: MediaQuery.of(context).size.width / 2 -
                                      110,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customer : ${item['customer']}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Time : ${formatTime(item['time'])}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      ...item['items'].map<Widget>((i) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 350,
                                              //color: Colors.amber,
                                              child: Text(i[0],
                                                  style: const TextStyle(
                                                      fontSize: 20)),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            i[1] == 0
                                                ? const Icon(Icons
                                                    .check_box_outline_blank)
                                                : Icon(
                                                    Icons.check_box,
                                                    color: _orange,
                                                  )
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                                Container(
                                  //color: Colors.blue,
                                  alignment: Alignment.topRight,
                                  width: MediaQuery.of(context).size.width / 2 +
                                      20,
                                  child: Column(
                                    children: [
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Bill Sent',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            'Sticker Print',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            'Paid',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            'Delivered',
                                            style: TextStyle(fontSize: 18),
                                          )
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 50,
                                      ),
                                      Row(
                                        children: [
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              updateItem('bill_sent', item['bill'], item);
                                            },
                                            // once bill is sent then dont allow to uncheck that button
                                            icon: item['bill'] == 0 ?
                                              const Icon(Icons.check_box_outline_blank)
                                            :
                                              Icon(Icons.check_box, color: _orange,),
                                            iconSize: 40,
                                          ),
                                          const SizedBox(
                                            width: 155,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              updateItem('sticker_print', item['sticker'], item);
                                            },
                                            icon: item['sticker'] == 0 ?
                                              const Icon(Icons.check_box_outline_blank)
                                            :
                                              Icon(Icons.check_box, color: _orange,),
                                            iconSize: 40,
                                          ),
                                          const SizedBox(
                                            width: 140,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              updateItem('payment_done', item['paid'], item);
                                            },
                                            icon: item['paid'] == 0 ?
                                              const Icon(Icons.check_box_outline_blank)
                                            :
                                              Icon(Icons.check_box, color: _orange,),
                                            iconSize: 40,
                                          ),
                                          const SizedBox(
                                            width: 125,
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              updateItem('delivered', item['delivered'], item);
                                            },
                                            icon: item['delivered'] == 0 ?
                                              const Icon(Icons.check_box_outline_blank)
                                            :
                                              Icon(Icons.check_box, color: _orange,),
                                            iconSize: 40,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            color: _grey,
                            height: 15,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
