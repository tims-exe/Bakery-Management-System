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

  List<Map<String, dynamic>> customers = [];

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
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoon();
  }
}
