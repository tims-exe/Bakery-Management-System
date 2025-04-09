import 'package:flutter/material.dart';

class SelectCustomer extends StatefulWidget {
  final List<String> customers;
  final String currentCustomer;
  final int currentCustomerID;
  final Function(String, int) onCustomerSelected;

  const SelectCustomer({
    super.key,
    required this.customers,
    required this.currentCustomer,
    required this.currentCustomerID,
    required this.onCustomerSelected,
  });

  @override
  State<SelectCustomer> createState() => _SelectCustomerState();
}

class _SelectCustomerState extends State<SelectCustomer> {
  late List<String> _filteredCustomers;
  late List<String> _customerList;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _customerList = widget.customers;
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = widget.customers
          .where((customer) =>
              customer.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  int _getIndex(String name) {
    for (int i = 0; i < _customerList.length; i++){
      if (_customerList[i] == name){
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search customers...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: _filterCustomers,
      ),
      content: SizedBox(
        width: 500,
        height: 500,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _filteredCustomers.length,
          itemBuilder: (context, index) {
            return ListTile(
              minTileHeight: 40,
              title: Text(_filteredCustomers[index]),
              onTap: () {
                Navigator.of(context).pop();
                int actualIndex = _getIndex(_filteredCustomers[index]);
                widget.onCustomerSelected(_filteredCustomers[index], actualIndex);
              },
            );
          },
        ),
      ),
    );
  }
}
