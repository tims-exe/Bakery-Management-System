import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nissy_bakes_app/database/dbhelper.dart';

class MenuitemsPage extends StatefulWidget {
  const MenuitemsPage({super.key});

  @override
  State<MenuitemsPage> createState() => _MenuitemsPageState();
}

class _MenuitemsPageState extends State<MenuitemsPage> {
  final _dbhelper = DbHelper();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _settings = [];
  final List<String> _duration = [
    'hours',
    'days',
    'weeks',
    'years',
  ];

  Map<String, dynamic> selectedCategory = {};
  Map<String, dynamic> selectedBaseUnit = {};
  Map<String, dynamic> selectedSellUnit = {};
  String? selectedDuration;

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  TextEditingController name = TextEditingController();
  TextEditingController baseQnty = TextEditingController();
  TextEditingController sellQnty = TextEditingController();
  TextEditingController wPrice = TextEditingController();
  TextEditingController rPrice = TextEditingController();
  TextEditingController mPrice = TextEditingController();
  TextEditingController retailPercent = TextEditingController();
  TextEditingController workPercent = TextEditingController();
  TextEditingController profitPercent = TextEditingController();
  TextEditingController bestBefore = TextEditingController();
  TextEditingController comments = TextEditingController();

  bool? refrigerate = false;

  void loadData() async {
    _categories = await _dbhelper.getCategory('item_category');
    _units = await _dbhelper.getUnits('unit_master');
    _settings = await _dbhelper.getSettings('settings');

    retailPercent.text = _settings[0]['retail_price_percentage'].toString();
    workPercent.text = _settings[0]['work_cost_percentage'].toString();
    profitPercent.text = _settings[0]['profit_percentage'].toString();

    print(_settings);
    print(profitPercent.text);
  }

  String getCurrentDateTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    return formattedDateTime;
  }

  void handleSave() async {
    if (name.text.isNotEmpty &&
        baseQnty.text.isNotEmpty &&
        sellQnty.text.isNotEmpty &&
        wPrice.text.isNotEmpty &&
        rPrice.text.isNotEmpty &&
        mPrice.text.isNotEmpty &&
        retailPercent.text.isNotEmpty &&
        workPercent.text.isNotEmpty &&
        profitPercent.text.isNotEmpty &&
        selectedCategory.isNotEmpty &&
        selectedBaseUnit.isNotEmpty &&
        selectedSellUnit.isNotEmpty) {
      Map<String, dynamic> newItem = {
        'item_name': name.text,
        'category_id': selectedCategory['category_id'],
        'base_quantity': baseQnty.text,
        'base_unit_id': selectedBaseUnit['unit_id'],
        'sell_quantity': sellQnty.text,
        'sell_unit_id': selectedSellUnit['unit_id'],
        'price_wholesale': wPrice.text,
        'price_retail': rPrice.text,
        'retail_price_percentage': retailPercent.text,
        'menu_price': mPrice.text,
        'work_cost_percentage': workPercent.text,
        'profit_percentage': profitPercent.text,
        'best_before': '${bestBefore.text} $selectedDuration',
        'refrigerate': refrigerate == true ? 1 : 0,
        'comments': comments.text,
        'modified_datetime': getCurrentDateTime(),
      };
      print(newItem);
      await _dbhelper.insertItem(newItem);
      print('item inserted');
      Fluttertoast.showToast(
        msg: "${name.text} Added to Menu",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {
        name.clear();
        baseQnty.clear();
        sellQnty.clear();
        wPrice.clear();
        rPrice.clear();
        mPrice.clear();
        retailPercent.clear();
        workPercent.clear();
        profitPercent.clear();
        bestBefore.clear();
        comments.clear();
        refrigerate = false;
        selectedCategory.clear();
        selectedBaseUnit.clear();
        selectedSellUnit.clear();
        selectedDuration = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // close button
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        //Navigator.pushNamed(context, '/homepage');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                  ),
                  // title
                  Text(
                    'Menu Item',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                  // search button
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.search,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              // heading line
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Divider(
                  thickness: 2.5,
                  color: _grey,
                  height: 35,
                ),
              ),
              // Two sections with vertical divider
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    150, // Adjust height as needed
                child: Row(
                  children: [
                    // Left section
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Item Details',
                            style: TextStyle(
                              color: _orange,
                              fontSize: 18,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  // Add this
                                  child: TextField(
                                    controller: name,
                                    decoration: InputDecoration(
                                      hoverColor: _orange,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      labelText: 'Name',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 10), // Add spacing between fields
                                SizedBox(
                                  width: 200,
                                  height: 55,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Text(
                                              'Select a Category',
                                              textAlign: TextAlign.center,
                                            ),
                                            content: SizedBox(
                                              width: 300,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: _categories.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    title: Text(
                                                      _categories[index]
                                                          ['category_name'],
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                      textAlign: TextAlign
                                                          .center, // Aligns the text to the center
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedCategory = {
                                                          'category_id':
                                                              _categories[index]
                                                                  [
                                                                  'category_id'],
                                                          'category_name':
                                                              _categories[index]
                                                                  [
                                                                  'category_name'],
                                                        };
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      selectedCategory['category_name'] ??
                                          'Category',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: baseQnty,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Base Qnty',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      setState(() {
                                        sellQnty.text = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  height: 55,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Text(
                                              'Select a Unit',
                                              textAlign: TextAlign.center,
                                            ),
                                            content: SizedBox(
                                              width: 200,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: _units.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    title: Text(
                                                      _units[index]
                                                          ['unit_name'],
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedBaseUnit = {
                                                          'unit_id':
                                                              _units[index]
                                                                  ['unit_id'],
                                                          'unit_name':
                                                              _units[index]
                                                                  ['unit_name'],
                                                        };
                                                        selectedSellUnit = {
                                                          'unit_id':
                                                              _units[index]
                                                                  ['unit_id'],
                                                          'unit_name':
                                                              _units[index]
                                                                  ['unit_name'],
                                                        };
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      selectedBaseUnit['unit_name'] ?? 'Unit',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: sellQnty,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Sell Qnty',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  height: 55,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Text(
                                              'Select a Unit',
                                              textAlign: TextAlign.center,
                                            ),
                                            content: SizedBox(
                                              width: 200,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: _units.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    title: Text(
                                                      _units[index]
                                                          ['unit_name'],
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedSellUnit = {
                                                          'unit_id':
                                                              _units[index]
                                                                  ['unit_id'],
                                                          'unit_name':
                                                              _units[index]
                                                                  ['unit_name'],
                                                        };
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      selectedSellUnit['unit_name'] ?? 'Unit',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Price Details',
                            style: TextStyle(
                              color: _orange,
                              fontSize: 18,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: wPrice,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Wholesale Price',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      num wholesale = num.parse(value);
                                      num retail = wholesale +
                                          (wholesale *
                                              num.parse(retailPercent.text));
                                      rPrice.text = retail.toString();
                                      mPrice.text = retail.toString();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: rPrice,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Retail Price',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: mPrice,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Menu Price',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: retailPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Retail Price Percentage',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: workPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Work Cost Percentage',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: profitPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Profit Percentage',
                                      labelStyle:
                                          const TextStyle(color: Colors.black),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Best Before',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: _orange,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              width: 150,
                                              // Add this
                                              child: TextField(
                                                controller: bestBefore,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(
                                                          r'^\d*\.?\d*$')),
                                                ],
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  labelText: 'Value',
                                                  labelStyle: const TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide: BorderSide(
                                                        color: _orange),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          SizedBox(
                                            width: 150,
                                            height: 55,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      title: const Text(
                                                        'Select Duration',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      content: SizedBox(
                                                        width: 300,
                                                        child: ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              _duration.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            return ListTile(
                                                              title: Text(
                                                                _duration[
                                                                    index],
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            18),
                                                              ),
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedDuration =
                                                                      _duration[
                                                                          index];
                                                                });
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                selectedDuration ??
                                                    'Duration', // Display selected duration or default text
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comments',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: _orange,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              width: 150,
                                              // Add this
                                              child: TextField(
                                                controller: comments,
                                                decoration: InputDecoration(
                                                  hoverColor: _orange,
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  labelText: '...',
                                                  labelStyle: const TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide: BorderSide(
                                                        color: _orange),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  //color: Colors.amber,
                                  width: 155,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Refrigerate : ',
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                      Transform.scale(
                                        scale:
                                            1.5, // Change this value to adjust the size
                                        child: Checkbox(
                                          value: refrigerate,
                                          activeColor: _lightOrange,
                                          onChanged: (value) {
                                            setState(() {
                                              refrigerate = value;
                                            });
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    handleSave();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: _lightOrange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(150, 55),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    // Vertical Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: VerticalDivider(
                        thickness: 2.5,
                        color: _grey,
                        width: 40,
                      ),
                    ),
                    // Right section
                    const SizedBox(
                      width: 550,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Ingredients',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Add your right section content here
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
