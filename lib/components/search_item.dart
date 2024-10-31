import 'package:flutter/material.dart';
import 'package:nissy_bakes_app/database/dbhelper.dart';

class SearchItem extends StatefulWidget {
  final List<Map<String, dynamic>> getOrder;
  final Function(List<Map<String, dynamic>>) onSave;

  const SearchItem({super.key, required this.getOrder, required this.onSave});

  @override
  State<SearchItem> createState() => _SearchItemState();
}

class _SearchItemState extends State<SearchItem> {
  final DbHelper _dbHelper = DbHelper();

  List<Map<String, dynamic>> menuItems = [];

  List<Map<String, dynamic>> searchedItems = [];

  List<Map<String, dynamic>> currentOrder = [];

  List<Map<String, dynamic>> units = [];

  final Color _orange = const Color.fromARGB(255, 207, 73, 0);

  final FocusNode _focusNode = FocusNode();

  final _defaultNo = 1;

  Future<void> getMenuItems() async {
    menuItems = await _dbHelper.getMenu('item_master');
    List<Map<String, dynamic>> getUnits =
        await _dbHelper.getUnits('unit_master');
    setState(() {
      searchedItems = menuItems;
      units = getUnits;
    });
  }

  String _getUnitId(int index) {
    for (int i = 0; i < units.length; i++) {
      if (units[i]['unit_id'] == index) {
        return units[i]['unit_name'];
      }
    }
    return '.';
  }

  void searchFilter(String keyword) {
    List<Map<String, dynamic>> result = [];
    if (keyword.isEmpty) {
      result = menuItems;
    } else {
      result = menuItems
          .where((user) =>
              user['item_name'].toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      searchedItems = result;
    });
  }

  bool checkCurrentOrder(Map item) {
    if (currentOrder.any((index) => index['item'] == item['item_name'])) {
      return false;
    } else {
      return true;
    }
  }

  void updateCurrentOrderNo(Map item) {
    for (int i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i]['item'] == item['item_name']) {
        currentOrder[i]['no']++;
      }
    }
  }

  void addtoCurrentOrder(Map item) {
    if (checkCurrentOrder(item)) {
      setState(() {
        currentOrder.add({
          'id': item['item_id'],
          'item': item['item_name'],
          'no': _defaultNo,
          'price': item['menu_price'],
          'weight': item['base_quantity'],
          'unit': _getUnitId(item['base_unit_id']),
          'sell_unit': _getUnitId(item['sell_unit_id']),
          'unit_id': item['base_unit_id'],
          'sell_qnty': item['sell_quantity'],
          'sell_unit_id': item['sell_unit_id'],
          'conversion': item['base_quantity'],
          'sell_rate': item['menu_price'],
        });
      });
    } else {
      setState(() {
        updateCurrentOrderNo(item);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    getMenuItems();
    currentOrder = widget.getOrder;

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
                        borderSide: BorderSide(color: _orange)),
                    hintText: 'Search the Menu...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: menuItems.isEmpty
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
                        final item = searchedItems[index];
                        return MaterialButton(
                          onPressed: () {
                            addtoCurrentOrder(item);
                            widget.onSave(currentOrder);
                            Navigator.pop(context);
                          },
                          child: ListTile(
                              title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['item_name'],
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                '${item['base_quantity']} ${_getUnitId(item['base_unit_id'])}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
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
