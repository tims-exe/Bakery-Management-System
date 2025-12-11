import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  final DbHelper _db = DbHelper();

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  DateTime _date = DateTime.now();

  String _filter = 'Today';
  final List<String> _allFilters = ['All', 'Today', 'Tomorrow'];
  int _filterIndex = 1;

  // Filtered lists
  List<Map<String, dynamic>> morningItems = [];
  List<Map<String, dynamic>> afternoonItems = [];
  List<Map<String, dynamic>> eveningItems = [];

  // Grouped lists for ALL
  Map<String, List<Map<String, dynamic>>> groupedMorningAll = {};
  Map<String, List<Map<String, dynamic>>> groupedAfternoonAll = {};
  Map<String, List<Map<String, dynamic>>> groupedEveningAll = {};

  @override
  void initState() {
    super.initState();
    _loadProductionData();
  }

  String getSectionDate(String input) {
    DateTime parsedDate = DateTime.parse(input);
    return DateFormat('dd-MM-yyyy').format(parsedDate);
  }

  Widget dividerWithText(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        ],
      ),
    );
  }

  // fetch and filter logic
  Future<void> _loadProductionData() async {
    String? dateFilter;

    if (_filter == "Today") {
      dateFilter = DateFormat("yyyy-MM-dd").format(DateTime.now());
    } else if (_filter == "Tomorrow") {
      dateFilter = DateFormat(
        "yyyy-MM-dd",
      ).format(DateTime.now().add(const Duration(days: 1)));
    } else if (_filter.contains("-")) {
      dateFilter = DateFormat("yyyy-MM-dd").format(_date);
    } else {
      dateFilter = null;
    }

    List<Map<String, dynamic>> raw = await _db.getProductionData(dateFilter);

    morningItems.clear();
    afternoonItems.clear();
    eveningItems.clear();

    groupedMorningAll.clear();
    groupedAfternoonAll.clear();
    groupedEveningAll.clear();

    for (var item in raw) {
      final time = item["delivery_time"];
      final dateKey = item["delivery_date"];

      if (time.compareTo("11:00:00") <= 0) {
        if (dateFilter == null) {
          groupedMorningAll.putIfAbsent(dateKey, () => []);
          groupedMorningAll[dateKey]!.add(item);
        } else {
          morningItems.add(item);
        }
      } else if (time.compareTo("11:00:01") >= 0 &&
          time.compareTo("15:00:00") <= 0) {
        if (dateFilter == null) {
          groupedAfternoonAll.putIfAbsent(dateKey, () => []);
          groupedAfternoonAll[dateKey]!.add(item);
        } else {
          afternoonItems.add(item);
        }
      } else {
        if (dateFilter == null) {
          groupedEveningAll.putIfAbsent(dateKey, () => []);
          groupedEveningAll[dateKey]!.add(item);
        } else {
          eveningItems.add(item);
        }
      }
    }

    // Sort groups for ALL filter
    if (dateFilter == null) {
      groupedMorningAll = Map.fromEntries(
        groupedMorningAll.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      groupedAfternoonAll = Map.fromEntries(
        groupedAfternoonAll.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      groupedEveningAll = Map.fromEntries(
        groupedEveningAll.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
    }

    setState(() {});
  }

  // ui list helper widgets

  Widget buildItemList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // item name + qnty + unit
              Expanded(
                child: Text(
                  "${item['item_name']} (${item['sell_quantity']} ${item['unit_name']})",
                  style: const TextStyle(fontSize: 18),
                ),
              ),

              // total to produce
              Text(
                "${item['total_items']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildGroupedList(Map<String, List<Map<String, dynamic>>> groupedMap) {
    return ListView(
      children:
          groupedMap.entries.map((entry) {
            return Column(
              children: [
                dividerWithText(getSectionDate(entry.key)),
                ...entry.value.map(
                  (item) => ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item['item_name']} (${item['sell_quantity']} ${item['unit_name']})",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Text(
                          "${item['total_items']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  // main ui
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 20),
        child: Column(
          children: [
            // ------------------- TOP BAR -------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: Text(
                    'Production',
                    style: TextStyle(fontSize: 30, color: _orange),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_allFilters.contains(_filter)) {
                        _filterIndex = (_filterIndex + 1) % _allFilters.length;
                        _filterIndex == 1
                            ? _date = DateTime.now()
                            : _date = DateTime.now().add(
                              const Duration(days: 1),
                            );
                      } else {
                        _filterIndex = 1;
                        _date = DateTime.now();
                      }

                      setState(() => _filter = _allFilters[_filterIndex]);
                      _loadProductionData();
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
                          _filter = DateFormat("dd-MM-yyyy").format(pickedDate);
                        });
                        _loadProductionData();
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

            // ------------------- DIVIDER -------------------
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
              child: Divider(thickness: 2.5, color: _grey, height: 35),
            ),

            // ------------------- MAIN CONTENT -------------------
            SizedBox(
              height: 630,
              child: Row(
                children: [
                  // ------------------- MORNING -------------------
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Morning",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "(Till 11am)",
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 15),
                        Divider(
                          thickness: 1,
                          color: _grey,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child:
                                _filter == "All"
                                    ? buildGroupedList(groupedMorningAll)
                                    : buildItemList(morningItems),
                          ),
                        ),
                      ],
                    ),
                  ),

                  VerticalDivider(color: _grey, thickness: 2.5, width: 20),

                  // ------------------- AFTERNOON -------------------
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Afternoon",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "(11am to 3pm)",
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 15),
                        Divider(
                          thickness: 1,
                          color: _grey,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child:
                                _filter == "All"
                                    ? buildGroupedList(groupedAfternoonAll)
                                    : buildItemList(afternoonItems),
                          ),
                        ),
                      ],
                    ),
                  ),

                  VerticalDivider(color: _grey, thickness: 2.5, width: 20),

                  // ------------------- EVENING -------------------
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Evening",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "(After 3pm)",
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 15),
                        Divider(
                          thickness: 1,
                          color: _grey,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child:
                                _filter == "All"
                                    ? buildGroupedList(groupedEveningAll)
                                    : buildItemList(eveningItems),
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
      ),
    );
  }
}
