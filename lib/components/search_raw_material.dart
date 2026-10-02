import 'package:flutter/material.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';

class SearchRawMaterial extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;

  const SearchRawMaterial({super.key, required this.onSelect});

  @override
  State<SearchRawMaterial> createState() => _SearchRawMaterialState();
}

class _SearchRawMaterialState extends State<SearchRawMaterial> {
  List<Map<String, dynamic>> rawMaterialList = [];
  List<Map<String, dynamic>> searchedItems = [];
  bool _loading = true;
  final FocusNode _focusNode = FocusNode();

  final _dbhelper = DbHelper();

  Future<void> getRawMaterialList() async {
    rawMaterialList = await _dbhelper.getRawMaterials();

    if (!mounted) return;
    setState(() {
      searchedItems = rawMaterialList;
      _loading = false;
    });
  }

  void searchFilter(String keyword) {
    List<Map<String, dynamic>> result = [];
    if (keyword.isEmpty) {
      result = rawMaterialList;
    } else {
      result = rawMaterialList
          .where((rm) => rm['rm_name']
              .toString()
              .toLowerCase()
              .contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      searchedItems = result;
    });
  }

  String formatNum(dynamic value) {
    final n = value as num;
    return n == n.truncate() ? n.truncate().toString() : n.toString();
  }

  @override
  void initState() {
    super.initState();

    getRawMaterialList();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
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
                    hintText: 'Search Raw Materials...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]),
                    padding: const EdgeInsets.only(top: 20),
                    width: 500,
                    child: searchedItems.isEmpty
                        ? const Center(child: Text('No raw materials found'))
                        : ListView.builder(
                            itemCount: searchedItems.length,
                            itemBuilder: (context, index) {
                              final rm = searchedItems[index];
                              final bool packing = rm['rm_type'] == 'packing';
                              final Color color =
                                  packing ? Colors.blue : Colors.green;
                              return MaterialButton(
                                onPressed: () {
                                  widget.onSelect(rm);
                                  Navigator.pop(context);
                                },
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${rm['rm_name']}  (${formatNum(rm['weight'])} ${rm['base_unit_name'] ?? ''})',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      Icon(
                                        packing
                                            ? Icons.inventory_2_outlined
                                            : Icons.eco_outlined,
                                        size: 20,
                                        color: color,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        packing ? 'Packing' : 'Edible',
                                        style: TextStyle(
                                            fontSize: 14, color: color),
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
