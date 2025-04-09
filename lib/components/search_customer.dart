import 'package:flutter/material.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';

class SearchCustomer extends StatefulWidget {
  final Map<String, dynamic> getCustomer;
  final int getCustomerID;
  final Function(Map<String, dynamic>, int) onSave;

  const SearchCustomer(
      {super.key,
      required this.getCustomer,
      required this.getCustomerID,
      required this.onSave});

  @override
  State<SearchCustomer> createState() => _SearchCustomerState();
}

class _SearchCustomerState extends State<SearchCustomer> {
  List<Map<String, dynamic>> customerList = [];
  List<Map<String, dynamic>> searchedItems = [];
  Map<String, dynamic> currentCustomer = {};
  int currentCustomerID = 0;
  final FocusNode _focusNode = FocusNode();

  final _dbhelper = DbHelper();

  Future<void> getCustomerList() async {
    customerList = await _dbhelper.getCustomers('customer_master');

    setState(() {
      searchedItems = customerList;
    });
  }

  void searchFilter(String keyword) {
    List<Map<String, dynamic>> result = [];
    if (keyword.isEmpty) {
      result = customerList;
    } else {
      result = customerList
          .where((user) => user['customer_name']
              .toLowerCase()
              .contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      searchedItems = result;
    });
  }

  void addCustomer(person) {
    setState(() {
      currentCustomer['customer_name'] = person['customer_name'];
      currentCustomer['reference'] = person['reference'];
      currentCustomer['customer_address'] = person['customer_address'];
      currentCustomer['customer_phone'] = person['customer_phone'];
      currentCustomer['customer_balance'] = person['customer_balance'];

      currentCustomerID = person['customer_id'];
    });
  }

  @override
  void initState() {
    super.initState();

    currentCustomer = widget.getCustomer;
    currentCustomerID = widget.getCustomerID;

    getCustomerList();

    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15, top: 15),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 500,
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: (value) => searchFilter(value),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black)),
                    hintText: 'Search Customers...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: customerList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]),
                    padding: const EdgeInsets.only(top: 20),
                    width: 500,
                    child: ListView.builder(
                      itemCount: searchedItems.length,
                      itemBuilder: (context, index) {
                        final person = searchedItems[index];
                        return MaterialButton(
                          onPressed: () {
                            addCustomer(person);
                            widget.onSave(currentCustomer, currentCustomerID);
                            Navigator.pop(context);
                          },
                          child: ListTile(
                              title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                person['customer_name'],
                                style: const TextStyle(fontSize: 18),
                              ),
                              if (person['reference'] != '')
                                Text(
                                  ' (${person['reference']})',
                                  style: const TextStyle(fontSize: 18),
                                ),
                            ],
                          )),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
