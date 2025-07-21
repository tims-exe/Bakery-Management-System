import 'package:flutter/material.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';

class SearchMenuItem extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemSelected;

  const SearchMenuItem({super.key, required this.onItemSelected});

  @override
  State<SearchMenuItem> createState() => _SearchMenuItemState();
}

class _SearchMenuItemState extends State<SearchMenuItem> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> searchedItems = [];
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> categories = [];

  final Color _orange = const Color.fromARGB(255, 207, 73, 0);
  final FocusNode _focusNode = FocusNode();

  Future<void> getMenuItems() async {
    menuItems = await _dbHelper.getMenu('item_master');
    List<Map<String, dynamic>> getUnits = await _dbHelper.getUnits('unit_master');
    List<Map<String, dynamic>> getCategories = await _dbHelper.getCategory('item_category');
    setState(() {
      searchedItems = menuItems;
      units = getUnits;
      categories = getCategories;
    });
  }

  String _getUnitName(int unitId) {
    for (var unit in units) {
      if (unit['unit_id'] == unitId) {
        return unit['unit_name'];
      }
    }
    return '';
  }

  String _getCategoryName(int categoryId) {
    for (var category in categories) {
      if (category['category_id'] == categoryId) {
        return category['category_name'];
      }
    }
    return '';
  }

  void searchFilter(String keyword) {
    List<Map<String, dynamic>> result = [];
    if (keyword.isEmpty) {
      result = menuItems;
    } else {
      result = menuItems
          .where((item) =>
              item['item_name'].toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      searchedItems = result;
    });
  }

  @override
  void initState() {
    super.initState();
    getMenuItems();
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
                        borderSide: BorderSide(color: _orange)),
                    hintText: 'Search Menu Items...',
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
                            // Create a complete item object with unit and category names
                            Map<String, dynamic> selectedItem = Map.from(item);
                            selectedItem['base_unit_name'] = _getUnitName(item['base_unit_id']);
                            selectedItem['sell_unit_name'] = _getUnitName(item['sell_unit_id']);
                            selectedItem['category_name'] = _getCategoryName(item['category_id']);
                            
                            widget.onItemSelected(selectedItem);
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
                                  '${item['base_quantity']} ${_getUnitName(item['base_unit_id'])}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
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