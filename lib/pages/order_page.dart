// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nissy_bakes_app/components/order_item_edit.dart';
import 'package:nissy_bakes_app/components/order_more_details.dart';
import 'package:nissy_bakes_app/components/search_item.dart';
import 'package:nissy_bakes_app/components/select_customer.dart';
//import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../database/dbhelper.dart';

class OrderPage extends StatefulWidget {
  final List<Map<String, dynamic>> getOrder;
  final Map<String, dynamic> getBill;
  final Function(Map<String, dynamic>) onSaveBill;
  final Function(List<Map<String, dynamic>>) onSaveOrder;
  final bool isEdit;

  const OrderPage(
      {super.key,
      required this.getBill,
      required this.getOrder,
      required this.onSaveBill,
      required this.onSaveOrder,
      required this.isEdit});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // colours
  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  // database helper
  final DbHelper _dbhelper = DbHelper();

  final mobileNo = dotenv.env['MOBILE_NO'];
  final fssai = dotenv.env['FSSAI'];
  final upi = dotenv.env['UPI_ID'];
  final upiNo = dotenv.env['UPI_NO'];
  final link = dotenv.env['LINK'];
  final email = dotenv.env['EMAIL'];
  final int billNumberFinancialYear =
      int.parse(dotenv.env['BILL_NUMBER_FINANCIAL_YEAR']!);

  // variables
  int billNumber = 0;

  bool _isEdit = false;
  //bool _isPaid = false;

  String defaultCustomer = 'Guest';
  int defaultCustomerID = 1;

  DateTime currentDateTime = DateTime.now();
  DateTime deliveryDate = DateTime.now();
  DateTime modifiedDateTime = DateTime.now();
  TimeOfDay deliveryTime = const TimeOfDay(hour: 18, minute: 0);

  List<Map<String, dynamic>> customers = [];

  List<String> customerList = [];

  late List<Map<String, dynamic>> currentOrder;
  late Map<String, dynamic> currentBill;
  Map<String, dynamic> orderHeader = {};
  List<Map<String, dynamic>> orderDetails = [];

  // textfield controllers
  final TextEditingController deliveryChargesFieldController =
      TextEditingController(text: '0');
  final TextEditingController advancePaidFieldController =
      TextEditingController(text: '0');
  final TextEditingController finalPaymentFieldController =
      TextEditingController(text: '0');
  final TextEditingController discountFieldController =
      TextEditingController(text: '0');
  final TextEditingController quantityFieldController = TextEditingController();
  final TextEditingController itemPriceFieldController =
      TextEditingController();
  final TextEditingController mobileNumberFieldController =
      TextEditingController();

  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _allItems = [];

  void _loadData() async {
    List<Map<String, dynamic>> units = await _dbhelper.getUnits('unit_master');
    List<Map<String, dynamic>> items = await _dbhelper
        .getUnits('item_master'); // reuse same method for similar db request
    _units = units;
    _allItems = items;
    getCustomerList();
  }

  // function to get current date from datetime
  String getDate(DateTime datetime, String param) {
    return '${datetime.day.toString().padLeft(2, '0')}-${datetime.month.toString().padLeft(2, '0')}-${datetime.year.toString().padLeft(2, '0')}';
  }

  // function to display time as 12hr
  String formatTimeOfDay(TimeOfDay time) {
    final hours = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hours:$minutes $period';
  }

  DateTime getFormatedDate(String str) {
    DateFormat format = DateFormat('dd-MM-yyy');
    return format.parse(str);
  }

  // function to get next bill number
  Future<void> getNextBillNumber() async {
    var gotBillNumber = await _dbhelper.getBillNumber('order_header');

    if (!_isEdit) {
      if (gotBillNumber != null) {
        billNumber = gotBillNumber + 1;
      }
      if (currentBill['bill_number'] == 0 ||
          currentBill['bill_number'] > billNumber) {
        currentBill['bill_number'] = billNumber;
      }
    } else {
      deliveryDate = getFormatedDate(currentBill['delivery_date']);
      currentDateTime = getFormatedDate(currentBill['bill_date']);

      String time = currentBill['delivery_time'];
      List<String> parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      deliveryTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  // function to get customers list
  void getCustomerList() async {
    customers = await _dbhelper.getCustomers('customer_master');

    for (int i = 0; i < customers.length; i++) {
      String display_text = customers[i]['customer_name'];
      if (customers[i]['reference'].isNotEmpty) {
        display_text = '${display_text} (${customers[i]['reference']})';
      }
      customerList.add(display_text);
    }

    defaultCustomer = getCustomer(currentBill['customer_id']);
    defaultCustomerID = currentBill['customer_id'];
  }

  String getMobileNumber(int index) {
    for (Map<String, dynamic> c in customers) {
      if (c['customer_id'] == index) {
        return c['customer_phone'];
      }
    }
    return '';
  }

  // function to get customer balance
  int getCustomerBalance(String customer) {
    if (customer != 'Guest') {
      return 0;
    }
    return 0;
  }

  // function to calculate total amount
  num getTotalAmount(List<Map<String, dynamic>> order) {
    num total = 0;
    for (int i = 0; i < order.length; i++) {
      total += (order[i]['sell_rate'] * order[i]['no']);
    }
    currentBill['total_amount'] = total;

    return total;
  }

  int getIntofBoolean(bool? value) {
    if (value == true) {
      return 1;
    } else {
      return 0;
    }
  }

  int getCustomerID(int id) {
    return customers[id]['customer_id'];
  }

  String getCustomer(int id) {
    for (int i = 0; i < customers.length; i++) {
      if (customers[i]['customer_id'] == id) {
        String display_text = customers[i]['customer_name'];
        if (customers[i]['reference'].isNotEmpty) {
          display_text = '$display_text (${customers[i]['reference']})';
        }
        return display_text;
      }
    }
    return '';
  }

  Map<String, dynamic> getOrderHeader() {
    Map<String, dynamic> header = {};

    // get bill number type and financial year from settings table
    header['bill_number_type'] = 'B';
    header['bill_number_financial_year'] = billNumberFinancialYear;

    header['bill_number'] = billNumber;
    header['bill_date'] =
        '${currentDateTime.year.toString().padLeft(2, '0')}-${currentDateTime.month.toString().padLeft(2, '0')}-${currentDateTime.day.toString().padLeft(2, '0')}';

    // get customer id from customer table based on name (for now default = 1 for guest)
    header['customer_id'] = defaultCustomerID;

    header['delivery_date'] =
        '${deliveryDate.year.toString().padLeft(2, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
    header['delivery_time'] =
        '${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}:00';

    header['total_amount'] = getTotalAmount(currentOrder);
    header['delivery_charges'] = num.parse(deliveryChargesFieldController.text);
    header['comments'] = currentBill['comments'];
    header['produced'] = getIntofBoolean(currentBill['produced']);
    header['sticker_print'] = getIntofBoolean(currentBill['sticker_print']);
    header['bill_sent'] = getIntofBoolean(currentBill['bill_sent']);
    header['delivered'] = getIntofBoolean(currentBill['delivered']);
    header['payment_done'] = getIntofBoolean(currentBill['payment_done']);
    header['discount_amount'] = num.parse(discountFieldController.text);
    header['advance_paid'] = num.parse(advancePaidFieldController.text);
    header['final_payment'] = num.parse(finalPaymentFieldController.text);
    header['modified_datetime'] =
        '${modifiedDateTime.year.toString().padLeft(2, '0')}-${modifiedDateTime.month.toString().padLeft(2, '0')}-${modifiedDateTime.day.toString().padLeft(2, '0')} ${modifiedDateTime.hour.toString().padLeft(2, '0')}:${modifiedDateTime.minute.toString().padLeft(2, '0')}:${modifiedDateTime.second.toString().padLeft(2, '0')}';

    //print('######${num.parse(finalPaymentFieldController.text)}');

    return header;
  }

  Map<String, dynamic> getItemDetails(int index, Map<String, dynamic> item) {
    Map<String, dynamic> details = {};

    // get bill number type and financial year from settings table
    details['bill_number_type'] = 'B';
    details['bill_number_financial_year'] = billNumberFinancialYear;
    details['bill_number'] = billNumber;
    details['sl_number'] = index + 1;
    details['item_id'] = item['id'];
    details['number_of_items'] = item['no'];
    details['base_quantity'] = item['weight'];
    details['base_unit_id'] = item['unit_id'];
    details['base_rate'] = item['price'];
    // update convertion quantity and sell stuff once that feature is added
    details['conversion_qty'] = item['conversion'];
    details['sell_quantity'] = item['sell_qnty'];
    details['sell_unit_id'] = item['sell_unit_id'];
    details['sell_rate'] = item['sell_rate'];
    if (currentBill['produced']){
      details['produced'] = 1;
    }
    else{
      details['produced'] = 0;
    }
    print(details['produced']);
    details['modified_datetime'] =
        '${modifiedDateTime.year}-${modifiedDateTime.month}-${modifiedDateTime.day} ${modifiedDateTime.hour}:${modifiedDateTime.minute}:${modifiedDateTime.second}';

    return details;
  }

  void saveOrder(
      Map<String, dynamic> header, List<Map<String, dynamic>> items) async {
    await _dbhelper.insertHeader(header);
    if (items != []) {
      await _dbhelper.inserOrder(items);
    }
  }

  void updateOrder(
      Map<String, dynamic> header, List<Map<String, dynamic>> items) async {
    String whereClause =
        'bill_number_type = ? AND bill_number_financial_year = ? AND bill_number = ?';
    List<dynamic> whereArgs = [
      header['bill_number_type'],
      header['bill_number_financial_year'],
      header['bill_number']
    ];
    await _dbhelper.updateHeader(header, whereClause, whereArgs);

    await _dbhelper.deleteOrder('order_details', header['bill_number_type'],
        header['bill_number_financial_year'], header['bill_number']);
    await _dbhelper.inserOrder(items);
  }

  String formatDate(String date) {
    List<String> parts = date.split('-');

    List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    String month = monthNames[int.parse(parts[1]) - 1];

    String formattedDate = '${parts[2]} $month ${parts[0]}';

    return formattedDate;
  }

  String _getItemName(int index) {
    for (int i = 0; i < _allItems.length; i++) {
      if (_allItems[i]['item_id'] == index) {
        return _allItems[i]['item_name'];
      }
    }
    return '.';
  }

  String _getPrintFormula(int index) {
    for (int i = 0; i < _units.length; i++) {
      print(_units[i]);
      if (_units[i]['unit_id'] == index) {
        return _units[i]['print_formula'];
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

  String getWhatsAppMessage(
      Map<String, dynamic> header, List<Map<String, dynamic>> details) {
    String invoiceHeader = '*Nissy Bakes*\nIrumpanam, Kochi\n_fssai_: $fssai';
    String invoiceDetails =
        '*Invoice*\nBill# : ${header['bill_number_type']}${header['bill_number_financial_year']}-${header['bill_number']}\nDate : ${formatDate(header['delivery_date'])}';

    String invoiceItems = '';

    for (Map<String, dynamic> items in details) {
      String formula = _getPrintFormula(items['sell_unit_id']);
      print(formula);
      if (formula == 'num_x_sellqnty') {
        // (number of items * sell qnty) name
        invoiceItems =
            '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} ${_getItemName(items['item_id'])} @ Rs ${(items['sell_rate'] * items['number_of_items'])}/-\n';
      } else if (formula == 'num_x_sellqnty_unit') {
        // 
        invoiceItems =
            '$invoiceItems${(items['number_of_items'] * items['sell_quantity'])} ${_getItemName(items['item_id'])} (${_getUnitId(items['sell_unit_id'])}) @ Rs ${(items['sell_rate'] * items['number_of_items'])}/-\n';
      } else {
        // num  name (sellqnty sellunit)
        invoiceItems =
            '$invoiceItems${items['number_of_items']} ${_getItemName(items['item_id'])} (${items['sell_quantity']} ${_getUnitId(items['sell_unit_id'])}) @ Rs ${(items['sell_rate'] * items['number_of_items'])}/-\n';
      }
    }

    String invoiceDeliveryCharges =
        'Delivery Charges @ Rs ${header['delivery_charges']}/-';

    String invoiceTotalOrderAmount =
        'Total Order Amount = *Rs ${(header['total_amount'] + header['delivery_charges']).toString()}/-*';

    String invoiceDiscountAmount = '';
    if (header['discount_amount'] != 0) {
      invoiceDiscountAmount =
          'Discount Amount @ Rs ${header['discount_amount']}/-\nFinal Order Amount = *Rs ${(header['total_amount'] + header['delivery_charges'] - header['discount_amount']).toString()}/-*\n\n';
    }

    String invoiceAdvanceAmount = '';
    if (header['advance_paid'] != 0) {
      invoiceAdvanceAmount =
          'Advance Paid @ Rs ${header['advance_paid']}\nBalance Amount = *Rs ${(header['total_amount'] + header['delivery_charges'] - header['discount_amount'] - header['advance_paid']).toString()}/-*\n\n';
    }

    String invoiceFooter =
        'Payments by Cash / Cheque / GPay @$upiNo / UPI: $upi upon delivery\n\n*Please share your feedback using the link $link*\n\n      Reach Us @ *$mobileNo* or *$email*\n\n       _Thank you for your order_';

    String msg =
        '$invoiceHeader\n\n$invoiceDetails\n\n$invoiceItems\n$invoiceDeliveryCharges\n\n$invoiceTotalOrderAmount\n\n$invoiceDiscountAmount$invoiceAdvanceAmount$invoiceFooter';

    return msg;
  }

  void billSaved() {
    if (_isEdit) {
      print('Editing Order...');

      updateOrder(orderHeader, orderDetails);
    } else {
      print('Saving Order...');

      saveOrder(orderHeader, orderDetails);
      print('SUCESSSS');
    }
  }

  /* void updateFinalPayment(bool paid) {
    if (paid == true) {
      var total = getTotalAmount(currentOrder);
      currentBill['final_payment'] = total +
          currentBill['delivery_charges'] -
          currentBill['advance_paid'] -
          currentBill['discount_amount'];
      finalPaymentFieldController.text =
          currentBill['final_payment'].toString();
    } else if (paid == false) {
      currentBill['final_payment'] = 0;
      finalPaymentFieldController.text = '0';
    }
  } */

  void checkFinalPayment() {
    var total = getTotalAmount(currentOrder);
    if (total + currentBill['delivery_charges'] - currentBill['discount_amount'] - currentBill['advance_paid'] - currentBill['final_payment'] == 0){
      currentBill['payment_done'] = true;
    }
    else{
      currentBill['payment_done'] = false;
    }
  }

  String adjustCustomerName(String name) {
    return name.length > 30 ? '${name.substring(0, 25)}...' : name;
  }

  void checkProduced(){
    if (_isEdit){
      bool p = true;
      for (int i = 0; i < currentOrder.length; i++){
        print(currentOrder[i]['produced']);
        if (currentOrder[i]['produced'] == 0){
          p = false;
        }
      }
      currentBill['produced'] = p;
    }
  }

  // initial state
  @override
  void initState() {
    super.initState();
    _isEdit = widget.isEdit;
    _loadData();

    currentBill = Map.from(widget.getBill);
    currentOrder = widget.getOrder;

    var total = getTotalAmount(currentOrder);
    currentBill['total_amount'] = total;

    checkProduced();
    //currentBill['advance_paid'] = num.parse(currentBill['advance_paid']);

    /* if (currentBill['payment_done'] == true) {
      _isPaid = true;
    } */

    billNumber = currentBill['bill_number'];
    deliveryChargesFieldController.text =
        currentBill['delivery_charges'].toString();
    advancePaidFieldController.text = currentBill['advance_paid'].toString();
    finalPaymentFieldController.text = currentBill['final_payment'].toString();
    discountFieldController.text = currentBill['discount_amount'].toString();
    mobileNumberFieldController.text = mobileNo!;

    getNextBillNumber();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        //getCustomer(currentBill['customer_id']);
        print(currentBill['total_amount']);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //updateFinalPayment(_isPaid);
    checkFinalPayment();
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
                  Container(
                    width: 120,
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        widget.onSaveBill(currentBill);
                        widget.onSaveOrder(currentOrder);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                  ),
                  // title
                  _isEdit
                      ? Text(
                          'Edit Order',
                          style: TextStyle(
                            fontSize: 30,
                            color: _orange,
                          ),
                        )
                      : Text(
                          'New Order',
                          style: TextStyle(
                            fontSize: 30,
                            color: _orange,
                          ),
                        ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          if (getMobileNumber(currentBill['customer_id']) != '') {
                            mobileNumberFieldController.text = getMobileNumber(currentBill['customer_id']);
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
                                      borderRadius: BorderRadius.circular(
                                          10), // Optional: Rounded corners
                                      borderSide: const BorderSide(
                                        color: Colors.grey, // Border color
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
                                    onPressed: () {
                                      orderHeader = getOrderHeader();
                                      for (int i = 0;
                                          i < currentOrder.length;
                                          i++) {
                                        Map<String, dynamic> itemDetails =
                                            getItemDetails(i, currentOrder[i]);
                                        orderDetails.add(itemDetails);
                                      }

                                      billSaved();
                                      currentBill.clear();
                                      currentOrder.clear();
                                      widget.onSaveBill(currentBill);
                                      widget.onSaveOrder(currentOrder);
                                      Fluttertoast.showToast(
                                        msg: 'Bill Saved !!',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        backgroundColor: Colors.green,
                                        textColor: Colors.white,
                                        fontSize: 20,
                                      );
                                      sendWhatsAppMessage(mobileNumberFieldController.text,getWhatsAppMessage(orderHeader, orderDetails));
                                      Navigator.pushNamed(context, '/homepage');
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
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchItem(
                                  getOrder: currentOrder,
                                  onSave: (updatedOrder) {
                                    setState(() {
                                      currentOrder = updatedOrder;
                                    });
                                  }),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        iconSize: 30,
                      )
                    ],
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
                      padding: const EdgeInsets.only(right: 80, left: 30),
                      child: SizedBox(
                        height: 620,
                        child: Column(
                          children: [
                            // current order
                            const Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      'Item',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          'Unit',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 47,
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 55,
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Amount',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Divider(
                                thickness: 1.5,
                                color: _grey,
                                height: 10, // Space above and below the line
                              ),
                            ),
                            // items
                            Expanded(
                              child: ListView.builder(
                                itemCount: currentOrder.length,
                                itemBuilder: (context, index) {
                                  var item = currentOrder[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // item name
                                        SizedBox(
                                          width: 180,
                                          child: Text(
                                            item['item'],
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        // item weight and unit
                                        Container(
                                          alignment: Alignment.centerRight,
                                          width: 120,
                                          child: ListTile(
                                            title: Text(
                                              '${item['sell_qnty']} ${item['sell_unit']}',
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                            onLongPress: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return UnitConversion(
                                                    getItem: item,
                                                    onSave: (updatedItem) {
                                                      item = updatedItem;
                                                      print(item);
                                                      setState(() {});
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        // item price
                                        Container(
                                          //color: Colors.amber,
                                          alignment: Alignment.centerRight,
                                          width: 100,
                                          child: TextButton(
                                            onPressed: () {},
                                            onLongPress: () {
                                              itemPriceFieldController.text =
                                                  item['sell_rate'].toString();
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: const Text(
                                                      'Price',
                                                    ),
                                                    content: TextField(
                                                      controller:
                                                          itemPriceFieldController,
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                              decimal: true),
                                                      inputFormatters: <TextInputFormatter>[
                                                        FilteringTextInputFormatter
                                                            .allow(RegExp(
                                                                r'^\d*\.?\d{0,2}')),
                                                      ],
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  10), // Optional: Rounded corners
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Colors
                                                                .grey, // Border color
                                                            width:
                                                                1.0, // Border width
                                                          ),
                                                        ),
                                                      ),
                                                      minLines: 1,
                                                      maxLines: null,
                                                      onSubmitted: (value) {
                                                        setState(() {
                                                          // Check if the text is empty and revert to the original price
                                                          if (value.isEmpty) {
                                                            itemPriceFieldController
                                                                .text = item[
                                                                    'sell_rate']
                                                                .toString();
                                                          } else {
                                                            item['sell_rate'] =
                                                                num.parse(
                                                                    value);
                                                          }
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Text(
                                              '₹${item['sell_rate'].toString()}',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        // item quantity
                                        Container(
                                          //color: Colors.amber,
                                          alignment: Alignment.centerRight,
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 30,
                                                //color: Colors.red,
                                                child: IconButton(
                                                  onPressed: () {
                                                    setState(
                                                      () {
                                                        item['no']--;
                                                        if (item['no'] == 0) {
                                                          currentOrder
                                                              .removeAt(index);
                                                        }
                                                      },
                                                    );
                                                  },
                                                  icon:
                                                      const Icon(Icons.remove),
                                                  iconSize: 20,
                                                ),
                                              ),
                                              Container(
                                                //color: Colors.amber,
                                                alignment: Alignment.center,
                                                width: 60,
                                                child: TextButton(
                                                  onPressed: () {},
                                                  onLongPress: () {
                                                    quantityFieldController
                                                            .text =
                                                        item['no'].toString();
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              Colors.white,
                                                          title: const Text(
                                                            'Quantity',
                                                          ),
                                                          content: TextField(
                                                            controller:
                                                                quantityFieldController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <TextInputFormatter>[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            decoration:
                                                                InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10), // Optional: Rounded corners
                                                                borderSide:
                                                                    const BorderSide(
                                                                  color: Colors
                                                                      .grey, // Border color
                                                                  width:
                                                                      1.0, // Border width
                                                                ),
                                                              ),
                                                            ),
                                                            minLines: 1,
                                                            maxLines: null,
                                                            onSubmitted:
                                                                (value) {
                                                              setState(() {
                                                                // Check if the text is empty and revert to the original price
                                                                if (value
                                                                    .isEmpty) {
                                                                  quantityFieldController
                                                                      .text = item[
                                                                          'no']
                                                                      .toString();
                                                                } else {
                                                                  item['no'] =
                                                                      num.parse(
                                                                          value);
                                                                }
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Text(
                                                    item['no'].toString(),
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.black),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 30,
                                                //color: Colors.amber,
                                                child: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      item['no']++;
                                                    });
                                                  },
                                                  icon: const Icon(Icons.add),
                                                  iconSize: 20,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        // item total amount
                                        Container(
                                          alignment: Alignment.centerRight,
                                          width: 90,
                                          child: Text(
                                            '₹${(item['no'] * item['sell_rate']).toString()}',
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // bill
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Container(
                      width: 450,
                      height: 620,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(left: 30, right: 20, top: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                // heading
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // create settings table and fetch bill header from it
                                    Row(
                                      children: [
                                        // bill info
                                        Text(
                                          'Bill : B$billNumberFinancialYear-$billNumber',
                                          style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // more details
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return MoreDetails(
                                                  currentBill: currentBill,
                                                  onSave: (updatedBill) {
                                                    setState(() {
                                                      currentBill = updatedBill;
                                                      if (currentBill['payment_done'] == true) {
                                                        currentBill['final_payment'] = getTotalAmount(currentOrder) + currentBill['delivery_charges'] - currentBill['discount_amount'] - currentBill['advance_paid'];
                                                        finalPaymentFieldController.text = currentBill['final_payment'].toString();
                                                      } 
                                                    });
                                                  },
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.info_outline_rounded),
                                          iconSize: 30,
                                        ),
                                      ],
                                    ),
                                    // order date
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final DateTime? dateTime =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: currentDateTime,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(3000),
                                        );
                                        if (dateTime != null) {
                                          setState(() {
                                            currentDateTime = dateTime;
                                            currentBill['bill_date'] =
                                                '${currentDateTime.day.toString().padLeft(2, '0')}-${currentDateTime.month.toString().padLeft(2, '0')}-${currentDateTime.year.toString().padLeft(2, '0')}';

                                            if (!_isEdit) {
                                              deliveryDate = dateTime;
                                              currentBill['delivery_date'] =
                                                  '${deliveryDate.day.toString().padLeft(2, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.year.toString().padLeft(2, '0')}';
                                            }
                                          });
                                        }
                                      },
                                      child: Text(
                                        getDate(currentDateTime, 'order'),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // bill details
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10, top: 0),
                                  child: Column(
                                    children: [
                                      // customer details
                                      Container(
                                        //color: Colors.amber,
                                        margin:
                                            EdgeInsets.only(bottom: 5, top: 2),
                                        //color: Colors.amber,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              //color: Colors.amber,
                                              width: 100,
                                              child: const Text(
                                                'Customer :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              //color: Colors.cyan,
                                              //width: 250,
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return SelectCustomer(
                                                          customers:
                                                              customerList,
                                                          currentCustomer:
                                                              defaultCustomer,
                                                          currentCustomerID:
                                                              defaultCustomerID,
                                                          onCustomerSelected:
                                                              (selectedCustomer,
                                                                  selectedCustomerIndex) {
                                                            setState(() {
                                                              //print(selectedCustomer);
                                                              //print(selectedCustomerIndex);
                                                              defaultCustomer =
                                                                  selectedCustomer;
                                                              defaultCustomerID =
                                                                  getCustomerID(
                                                                      selectedCustomerIndex);
                                                              currentBill['customer_id'] = defaultCustomerID;
                                                              //print(defaultCustomerID);
                                                            });
                                                          },
                                                        );
                                                      });
                                                },
                                                child: Text(
                                                  adjustCustomerName(
                                                      defaultCustomer),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // customer balance
                                      Padding(
                                        padding:
                                            EdgeInsets.only(top: 5, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Customer Balance :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 100,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                getCustomerBalance(
                                                        defaultCustomer)
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // grand total amount
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 20, bottom: 0, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Grand Total :',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 100,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${getTotalAmount(currentOrder)}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // delivery charges
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Delivery Charges :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              height: 50,
                                              child: TextField(
                                                controller:
                                                    deliveryChargesFieldController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^\d*\.?\d{0,2}')),
                                                ],
                                                textAlign: TextAlign.right,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0',
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.isNotEmpty){
                                                      currentBill[
                                                            'delivery_charges'] =
                                                        num.parse(value);
                                                    }
                                                    else{
                                                      currentBill['delivery_charges'] = 0;
                                                      deliveryChargesFieldController.text = '0';
                                                    }
                                                  });
                                                },
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                onTap: () {
                                                  deliveryChargesFieldController
                                                          .selection =
                                                      TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        deliveryChargesFieldController
                                                            .text.length,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // discount
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Discount :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              height: 50,
                                              child: TextField(
                                                controller:
                                                    discountFieldController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^\d*\.?\d{0,2}')),
                                                ],
                                                textAlign: TextAlign.right,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0',
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.isNotEmpty){
                                                      currentBill[
                                                            'discount_amount'] =
                                                        num.parse(value);
                                                    }
                                                    else{
                                                      currentBill['discount_amount'] = 0;
                                                      discountFieldController.text = '0';
                                                    }
                                                  });
                                                },
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                onTap: () {
                                                  discountFieldController
                                                          .selection =
                                                      TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        discountFieldController
                                                            .text.length,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // total amount
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, bottom: 5, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Net Total :',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 100,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${getTotalAmount(currentOrder) + num.parse(deliveryChargesFieldController.text) - num.parse(discountFieldController.text)}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // advance paid
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Advance Paid :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              height: 50,
                                              child: TextField(
                                                controller:
                                                    advancePaidFieldController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^\d*\.?\d{0,2}')),
                                                ],
                                                textAlign: TextAlign.right,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0',
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.isNotEmpty){
                                                      currentBill[
                                                            'advance_paid'] =
                                                        num.parse(value);
                                                    }
                                                    else{
                                                      currentBill['advance_paid'] = 0;
                                                      advancePaidFieldController.text = '0';
                                                    }
                                                  });
                                                },
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                onTap: () {
                                                  advancePaidFieldController
                                                          .selection =
                                                      TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        advancePaidFieldController
                                                            .text.length,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // final payment
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Final Payment :',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              height: 50,
                                              child: TextField(
                                                controller:
                                                    finalPaymentFieldController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^\d*\.?\d{0,2}')),
                                                ],
                                                textAlign: TextAlign.right,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0',
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.isNotEmpty){
                                                      currentBill['final_payment'] = num.parse(value);
                                                    }
                                                    else{
                                                      currentBill['final_payment'] = 0;
                                                      finalPaymentFieldController.text = '0';
                                                    }
                                                  });
                                                },
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                onTap: () {
                                                  finalPaymentFieldController
                                                          .selection =
                                                      TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        finalPaymentFieldController
                                                            .text.length,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // balance amount to be paid
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0, right: 20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(
                                              width: 180,
                                              child: Text(
                                                'Balance :',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 110,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                // CONSIDER EXTRA FINAL PAYMENT AND ADVANCE PAYMENT DONE AND ADD IT TO CUSTOMER BALANCE (MAKE FUNCTION)
                                                '₹${getTotalAmount(currentOrder) + num.parse(deliveryChargesFieldController.text) - num.parse(discountFieldController.text) - num.parse(advancePaidFieldController.text) - num.parse(finalPaymentFieldController.text)}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
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
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 30, top: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      width: 230,
                                      height: 75,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // delivery date
                                          SizedBox(
                                            height: 35,
                                            width: 185,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Delivery : ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final DateTime? dateTime =
                                                        await showDatePicker(
                                                      context: context,
                                                      initialDate: deliveryDate,
                                                      firstDate: DateTime(2000),
                                                      lastDate: DateTime(3000),
                                                    );
                                                    if (dateTime != null) {
                                                      setState(() {
                                                        deliveryDate = dateTime;
                                                        currentBill[
                                                                'delivery_date'] =
                                                            '${deliveryDate.year.toString().padLeft(2, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    getDate(deliveryDate,
                                                        'delivery'),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // delivery time
                                          SizedBox(
                                            height: 35,
                                            width: 155,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Time : ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final TimeOfDay? timeOfDay =
                                                        await showTimePicker(
                                                      context: context,
                                                      initialTime: deliveryTime,
                                                      initialEntryMode:
                                                          TimePickerEntryMode
                                                              .dial,
                                                    );
                                                    if (timeOfDay != null) {
                                                      setState(() {
                                                        deliveryTime =
                                                            timeOfDay;
                                                        currentBill[
                                                                'delivery_time'] =
                                                            '${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}:00';
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    //'${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}',
                                                    formatTimeOfDay(
                                                        deliveryTime),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Container(
                                      width: 120,
                                      height: 75,
                                      decoration: BoxDecoration(
                                          color: _lightOrange,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: IconButton(
                                        onPressed: () {
                                          orderHeader = getOrderHeader();
                                          for (int i = 0;
                                              i < currentOrder.length;
                                              i++) {
                                            Map<String, dynamic> itemDetails =
                                                getItemDetails(
                                                    i, currentOrder[i]);
                                            orderDetails.add(itemDetails);
                                          }
                                          billSaved();
                                          Fluttertoast.showToast(
                                            msg: 'Bill Saved',
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.green,
                                            textColor: Colors.white,
                                            fontSize: 20,
                                          );
                                          currentBill.clear();
                                          currentOrder.clear();
                                          widget.onSaveBill(currentBill);
                                          widget.onSaveOrder(currentOrder);
                                          Navigator.of(context)
                                              .pop(); // Close the dialog without saving
                                          //Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.check),
                                        iconSize: 35,
                                      ),
                                    ),
                                  ),
                                ],
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
