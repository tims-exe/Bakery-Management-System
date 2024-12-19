// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);


  DateTime _date = DateTime.now();

  String _filter = 'Today';
  final List<String> _allFilters = ['All', 'Today', 'Tomorrow'];
  int _filterIndex = 1;

  TextEditingController mobileNumberFieldController = TextEditingController();

  final mobileNo = dotenv.env['MOBILE_NO'];
  final fssai = dotenv.env['FSSAI'];
  final upi = dotenv.env['UPI_ID'];
  final upiNo = dotenv.env['UPI_NO'];
  final link = dotenv.env['LINK'];
  final email = dotenv.env['EMAIL'];
  final int billNumberFinancialYear = int.parse(dotenv.env['BILL_NUMBER_FINANCIAL_YEAR']!);

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
      orderHeader = await _dbhelper.getOrderHeaderCondition('order_header', ['delivery_date = ?'], [currentDate], true);
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
      item['customer_phone'] = await _dbhelper.getCustomerPhone(orderHeader[i]['customer_id']);
      item['bill_number'] = '${orderHeader[i]['bill_number_type']}${orderHeader[i]['bill_number_financial_year']}-${orderHeader[i]['bill_number']}';
      item['time'] = orderHeader[i]['delivery_time'];
      item['sticker'] = orderHeader[i]['sticker_print'];
      item['bill'] = orderHeader[i]['bill_sent'];
      item['paid'] = orderHeader[i]['payment_done'];
      item['delivered'] = orderHeader[i]['delivered'];
      item['produced'] = orderHeader[i]['produced'];
      item['items'] = [];
      item['bill_num_type'] = orderHeader[i]['bill_number_type'];
      item['bill_num_financial_year'] = orderHeader[i]['bill_number_financial_year'];
      item['bill_num'] = orderHeader[i]['bill_number'];
      item['total_amount'] = orderHeader[i]['total_amount'];
      item['delivery_charges'] = orderHeader[i]['delivery_charges'];
      item['discount'] = orderHeader[i]['discount_amount'];
      item['advance'] = orderHeader[i]['advance_paid'];

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

    value == 0 ? value = 1 : value = 0;

    await _dbhelper.updateOrderHeader(update, value, item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']);

    List<Map<String, dynamic>> header = await _dbhelper.getOrderHeaderCondition('order_header', ['bill_number_type = ?', 'bill_number_financial_year = ?', 'bill_number = ?'], [item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']], false);

    print(header);


    // if update is payment done then update final payment
    if (update == 'payment_done' && value == 1){
      num finalAmount = item['total_amount'] + item['delivery_charges'] - item['advance'] - item['discount'];
      await _dbhelper.updateOrderHeader('final_payment', finalAmount, item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']);
    }
    else if (update == 'payment_done' && value == 0){
      await _dbhelper.updateOrderHeader('final_payment', 0, item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']);
    }

    // if produced is checked then make all items in that bill produced
    if (update == 'produced'){
      await _dbhelper.updateProduced(value, item['bill_num_type'].toString(), item['bill_num_financial_year'].toString(),  item['bill_num'].toString());
    }

    setState(() {
      print('UPDATED !!!');
    }); 
  }

  void sendWhatsAppMessage(String phoneNumber, String message) async {
    String formattedPhoneNumber = '+91$phoneNumber';
    if (phoneNumber.split(' ').where((number) => number.isNotEmpty).length > 1){
      formattedPhoneNumber = phoneNumber.replaceAll(' ', '').substring(1);
    } 
    final Uri whatsappUrl = Uri.parse(
        'https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(message)}');
    print(whatsappUrl);
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  String convertDate(String date) {
  DateTime parsedDate = DateTime.parse(date);
  String formattedDate = '${parsedDate.day.toString().padLeft(2, '0')}-'
      '${parsedDate.month.toString().padLeft(2, '0')}-'
      '${parsedDate.year}';
  
  return formattedDate;
}

  Future<String> getWhatsAppMessage(Map<String, dynamic> item) async {

    List<Map<String, dynamic>> header = await _dbhelper.getOrderHeaderCondition('order_header', ['bill_number_type = ?', 'bill_number_financial_year = ?', 'bill_number = ?'], [item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']], false);
    List<Map<String, dynamic>> details = await _dbhelper.getOrderHeaderCondition('order_details', ['bill_number_type = ?', 'bill_number_financial_year = ?', 'bill_number = ?'], [item['bill_num_type'], item['bill_num_financial_year'], item['bill_num']], false);

    String invoiceHeader = '*Nissy Bakes*\nIrumpanam, Kochi\n_fssai_: $fssai';
    String invoiceDetails = '*Invoice*\nBill# : ${header[0]['bill_number_type']}${header[0]['bill_number_financial_year']}-${header[0]['bill_number']}\nDate : ${convertDate(header[0]['delivery_date'])}';

    String invoiceItems = '';

    for (Map<String, dynamic> items in details) {
      String formula = await _dbhelper.getUnitFormula(items['sell_unit_id']);

      String itemName = await _dbhelper.getItemName(items['item_id']);
      String unitName = await _dbhelper.getUnitName(items['sell_unit_id']);

      num amt = items['sell_rate'] * items['number_of_items'];
      dynamic amount = (amt % 1 == 0) ? amt.toInt() : amt;

      if (amount != 0){
        if (formula == 'num_x_sellqnty') {
          // (number of items * sell qnty) name
          invoiceItems = '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} $itemName @ Rs $amount/-\n';
        } else if (formula == 'num_x_sellqnty_unit') {
          // 
          invoiceItems = '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} $itemName ($unitName) @ Rs $amount/-\n';
        } else {
          // num  name (sellqnty sellunit)
          invoiceItems = '$invoiceItems${items['number_of_items']} $itemName (${items['sell_quantity']} $unitName) @ Rs $amount/-\n';
        }
      }
      else {
        if (formula == 'num_x_sellqnty') {
          // (number of items * sell qnty) name
          invoiceItems = '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} $itemName\n';
        } else if (formula == 'num_x_sellqnty_unit') {
          // 
          invoiceItems = '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} $itemName ($unitName)\n';
        } else {
          // num  name (sellqnty sellunit)
          invoiceItems = '$invoiceItems${items['number_of_items']} $itemName (${items['sell_quantity']} $unitName)\n';
        }
      }
    }

    num delv = header[0]['delivery_charges'];
    num total = (header[0]['total_amount'] + header[0]['delivery_charges']);
    num disc = header[0]['discount_amount'];
    num fin = (header[0]['total_amount'] + header[0]['delivery_charges'] - header[0]['discount_amount']);
    num adv = header[0]['advance_paid'];
    num bal = (header[0]['total_amount'] + header[0]['delivery_charges'] - header[0]['discount_amount'] - header[0]['advance_paid']);

    dynamic delivery_charges = (delv % 1 == 0) ? delv.toInt() : delv;
    dynamic total_amount = (total % 1 == 0) ? total.toInt() : total;
    dynamic discount_amount = (disc % 1 == 0) ? disc.toInt() : disc;
    dynamic final_payment = (fin % 1 == 0) ? fin.toInt() : fin;
    dynamic advance_paid = (adv % 1 == 0) ? adv.toInt() : adv;
    dynamic balance_amount = (bal % 1 == 0) ? bal.toInt() : bal;

    String invoiceDeliveryCharges =
        'Delivery Charges @ Rs $delivery_charges/-';

    String invoiceTotalOrderAmount =
        'Total Order Amount = *Rs ${total_amount.toString()}/-*';

    String invoiceDiscountAmount = '';
    if (header[0]['discount_amount'] != 0) {
      invoiceDiscountAmount =
          'Discount Amount @ Rs $discount_amount/-\nFinal Order Amount = *Rs ${final_payment.toString()}/-*\n\n';
    }

    String invoiceAdvanceAmount = '';
    if (header[0]['advance_paid'] != 0) {
      invoiceAdvanceAmount =
          'Advance Paid @ Rs $advance_paid\nBalance Amount = *Rs ${balance_amount.toString()}/-*\n\n';
    }

    String invoiceFooter =
        'Payments by Cash / Cheque / GPay @$upiNo / UPI: $upi upon delivery\n\n*Please share your feedback using the link $link*\n\n      Reach Us @ *$mobileNo* or *$email*\n\n       _Thank you for your order_';

    String msg =
        '$invoiceHeader\n\n$invoiceDetails\n\n$invoiceItems\n$invoiceDeliveryCharges\n\n$invoiceTotalOrderAmount\n\n$invoiceDiscountAmount$invoiceAdvanceAmount$invoiceFooter';

    return msg;
}
    //return '';

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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No items found'));
                  }

                  final items = snapshot.data!;
                  final Map<String, List<Map<String, dynamic>>> allOrderDetails = {};

                  // Organize items into the allOrderDetails map grouped by date
                  for (var item in items) {
                    allOrderDetails.update(
                      item['date'],
                      (existing) => existing..add(item),
                      ifAbsent: () => [item],
                    );
                  }

                  // Sort the map entries by key
                  final sortedEntries = allOrderDetails.entries.toList()
                    ..sort((e1, e2) => e1.key.compareTo(e2.key));

                  return ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Display the date as a header
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              convertDate(entry.key),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _orange
                              ),
                            ),
                          ),

                          // ListView for the items under each date
                          ListView.builder(
                            shrinkWrap: true, // Fix for unbounded height
                            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                            itemCount: entry.value.length,
                            itemBuilder: (context, itemIndex) {
                              final item = entry.value[itemIndex];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.only(right: 10),
                                          //color: Colors.amber,
                                          width: MediaQuery.of(context).size.width / 2 - 220,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Customer: ${item['customer']}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Time: ${formatTime(item['time'])}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item['items'].map((i) => i[0]).join(', '),
                                                        style: const TextStyle(fontSize: 20),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Right-hand side buttons
                                        Container(
                                          //color: Colors.blue,
                                          width: MediaQuery.of(context).size.width / 2 + 130,
                                          alignment: Alignment.topRight,
                                          child: Column(
                                            children: [
                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Bill Sent', style: TextStyle(fontSize: 18)),
                                                  Text('Produced', style: TextStyle(fontSize: 18)),
                                                  Text('Sticker Print', style: TextStyle(fontSize: 18)),
                                                  Text('Paid', style: TextStyle(fontSize: 18)),
                                                  Text('Delivered', style: TextStyle(fontSize: 18)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const SizedBox(width: 6),
                                                  SizedBox(
                                                    /* onPressed: () {
                                                      updateItem('bill_sent', item['bill'], item);
                                                    }, */
                                                    // once bill is sent then dont allow to uncheck that button
                                                    child: item['bill'] == 0 ?
                                                      TextButton(
                                                        onPressed: ()  {
                                                          if (item['customer_phone'] != '') {
                                                            mobileNumberFieldController.text = item['customer_phone'];
                                                          }
                                                          else{
                                                            mobileNumberFieldController.text = mobileNo!;
                                                          }
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                backgroundColor: Colors.white,
                                                                title: const Text(
                                                                  'Save and Send Invoice',
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                                content: TextField(
                                                                  controller: mobileNumberFieldController,
                                                                  keyboardType: TextInputType.number,
                                                                  inputFormatters: <TextInputFormatter>[
                                                                    FilteringTextInputFormatter.digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border: OutlineInputBorder(
                                                                      borderRadius: BorderRadius.circular(10), 
                                                                      borderSide: const BorderSide(
                                                                        color: Colors.grey, 
                                                                        width: 1.0, // Border width
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  minLines: 1,
                                                                  maxLines: null,
                                                                  onSubmitted: (value) {
                                                                    mobileNumberFieldController.text = value;
                                                                  },
                                                                ),
                                                                actions: [
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      foregroundColor:
                                                                          const Color.fromARGB(255, 0, 0, 0),
                                                                      backgroundColor: _lightOrange,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                      ),
                                                                      elevation: 0,
                                                                    ),
                                                                    onPressed: () {
                                                                      Navigator.pop(context);
                                                                    },
                                                                    child: const Text('No'),
                                                                  ),
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      foregroundColor: Colors.black,
                                                                      backgroundColor: _lightOrange,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                      ),
                                                                      elevation: 0,
                                                                    ),
                                                                    onPressed: () async {
                                                                      String msg = await getWhatsAppMessage(item);
                                                                      sendWhatsAppMessage(mobileNumberFieldController.text, msg);
                                                                      updateItem('bill_sent', item['bill'], item);
                                                                      Navigator.pop(context);
                                                                      Fluttertoast.showToast(
                                                                        msg: 'Bill Sent !!',
                                                                        toastLength: Toast.LENGTH_SHORT,
                                                                        gravity: ToastGravity.BOTTOM,
                                                                        backgroundColor: Colors.green,
                                                                        textColor: Colors.white,
                                                                        fontSize: 20,
                                                                      );
                                                                    },
                                                                    child: const Text('Yes'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        style: TextButton.styleFrom(
                                                          padding: EdgeInsets.zero,
                                                          minimumSize: const Size(30, 30),
                                                        ),
                                                        child: Opacity(
                                                          opacity: 0.7,
                                                          child: Image.asset(
                                                            'assets/send.png',
                                                            width: 30,
                                                            height: 30,
                                                          ),
                                                        ),
                                                      )
                                                    :
                                                      Row(
                                                        children: [
                                                          const SizedBox(width: 8,),
                                                          Icon(Icons.check_box, color: _orange, size: 40,),
                                                          const SizedBox(width: 2,),
                                                        ],
                                                      )
                                                    //iconSize: 40,
                                                  ),
                                                  const SizedBox(width: 126),
                                                  IconButton(
                                                    onPressed: () {
                                                      updateItem('produced', item['produced'], item);
                                                    },
                                                    icon: item['produced'] == 0
                                                        ? const Icon(Icons.check_box_outline_blank)
                                                        : Icon(Icons.check_box, color: _orange),
                                                    iconSize: 40,
                                                  ),
                                                  const SizedBox(width: 135),
                                                  IconButton(
                                                    onPressed: () {
                                                      updateItem('sticker_print', item['sticker'], item);
                                                    },
                                                    icon: item['sticker'] == 0
                                                        ? const Icon(Icons.check_box_outline_blank)
                                                        : Icon(Icons.check_box, color: _orange),
                                                    iconSize: 40,
                                                  ),
                                                  const SizedBox(width: 117),
                                                  IconButton(
                                                    onPressed: () {
                                                      updateItem('payment_done', item['paid'], item);
                                                    },
                                                    icon: item['paid'] == 0
                                                        ? const Icon(Icons.check_box_outline_blank)
                                                        : Icon(Icons.check_box, color: _orange),
                                                    iconSize: 40,
                                                  ),
                                                  const SizedBox(width: 100),
                                                  IconButton(
                                                    onPressed: () {
                                                      updateItem('delivered', item['delivered'], item);
                                                    },
                                                    icon: item['delivered'] == 0
                                                        ? const Icon(Icons.check_box_outline_blank)
                                                        : Icon(Icons.check_box, color: _orange),
                                                    iconSize: 40,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(thickness: 1, color: _grey, height: 15),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            /* Expanded(
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
                                          SizedBox(
                                            /* onPressed: () {
                                              updateItem('bill_sent', item['bill'], item);
                                            }, */
                                            // once bill is sent then dont allow to uncheck that button
                                            child: item['bill'] == 0 ?
                                              TextButton(
                                                onPressed: ()  {
                                                  if (item['customer_phone'] != '') {
                                                    mobileNumberFieldController.text = item['customer_phone'];
                                                  }
                                                  else{
                                                    mobileNumberFieldController.text = mobileNo!;
                                                  }
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        backgroundColor: Colors.white,
                                                        title: const Text(
                                                          'Save and Send Invoice',
                                                          textAlign: TextAlign.center,
                                                        ),
                                                        content: TextField(
                                                          controller: mobileNumberFieldController,
                                                          keyboardType: TextInputType.number,
                                                          inputFormatters: <TextInputFormatter>[
                                                            FilteringTextInputFormatter.digitsOnly,
                                                          ],
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(10), 
                                                              borderSide: const BorderSide(
                                                                color: Colors.grey, 
                                                                width: 1.0, // Border width
                                                              ),
                                                            ),
                                                          ),
                                                          minLines: 1,
                                                          maxLines: null,
                                                          onSubmitted: (value) {
                                                            mobileNumberFieldController.text = value;
                                                          },
                                                        ),
                                                        actions: [
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              foregroundColor:
                                                                  const Color.fromARGB(255, 0, 0, 0),
                                                              backgroundColor: _lightOrange,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              elevation: 0,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                            child: const Text('No'),
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              foregroundColor: Colors.black,
                                                              backgroundColor: _lightOrange,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              elevation: 0,
                                                            ),
                                                            onPressed: () async {
                                                              /* orderHeader = getOrderHeader(item);
                                                              for (int i = 0; i < currentOrder.length; i++) {
                                                                Map<String, dynamic> itemDetails = getItemDetails(i, currentOrder[i]);
                                                                orderDetails.add(itemDetails);
                                                              }

                                                              billSaved();
                                                              currentBill.clear();
                                                              currentOrder.clear();
                                                              widget.onSaveBill(currentBill);
                                                              widget.onSaveOrder(currentOrder); */

                                                              String msg = await getWhatsAppMessage(item);
                                                              sendWhatsAppMessage(mobileNumberFieldController.text, msg);
                                                              updateItem('bill_sent', item['bill'], item);
                                                              Navigator.pop(context);
                                                              Fluttertoast.showToast(
                                                                msg: 'Bill Sent !!',
                                                                toastLength: Toast.LENGTH_SHORT,
                                                                gravity: ToastGravity.BOTTOM,
                                                                backgroundColor: Colors.green,
                                                                textColor: Colors.white,
                                                                fontSize: 20,
                                                              );
                                                            },
                                                            child: const Text('Yes'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(30, 30),
                                                ),
                                                child: Opacity(
                                                  opacity: 0.7,
                                                  child: Image.asset(
                                                    'assets/send.png',
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                ),
                                              )
                                            :
                                              Icon(Icons.check_box, color: _orange, size: 40,),
                                            //iconSize: 40,
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
            ), */
          ],
        ),
      ),
    );
  }
}
