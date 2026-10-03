import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';
import 'package:nissy_bakes_original/components/search_menu_item.dart'; // Add this import
import 'package:nissy_bakes_original/components/ingredients_panel.dart';
import 'package:nissy_bakes_original/components/admin_password_dialog.dart';

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
  final List<String> _duration = ['hours', 'days', 'weeks', 'months', 'years'];

  Map<String, dynamic> selectedCategory = {};
  Map<String, dynamic> selectedBaseUnit = {};
  Map<String, dynamic> selectedSellUnit = {};
  String selectedDuration = "Duration";

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
  bool _isEditing = false;
  int? _editingItemId;
  int retailPercentValue = 0;
  int workPercentValue = 0;
  int profitPercentValue = 0;

  // ingredients of the item on screen (read from / saved to the database)
  final IngredientsController _ingredients = IngredientsController();
  // calculated wholesale / retail shown (locked) while ingredients exist
  final TextEditingController calcW = TextEditingController();
  final TextEditingController calcR = TextEditingController();
  bool _showPercents = false;
  // admin password entered once while on this page
  bool _percentUnlocked = false;

  // a price input used in the price row
  Widget _priceField({
    required TextEditingController controller,
    required String label,
    bool locked = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      readOnly: locked,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: locked,
        fillColor: Colors.grey.shade200,
        suffixIcon: locked
            ? const Icon(Icons.lock_outline, size: 16, color: Colors.black54)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 28),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _orange),
        ),
      ),
    );
  }

  // eye toggle: password is asked only the first time on this page
  Future<void> _togglePercents() async {
    if (_showPercents) {
      setState(() => _showPercents = false);
      return;
    }
    if (!_percentUnlocked) {
      if (!await askAdminPassword(context)) return;
      _percentUnlocked = true;
    }
    if (!mounted) return;
    setState(() => _showPercents = true);
  }

  void loadData() async {
    _categories = await _dbhelper.getCategory('item_category');
    _units = await _dbhelper.getUnits('unit_master');
    _settings = await _dbhelper.getSettings('settings');
    await _ingredients.loadRawMaterials();

    retailPercentValue = _settings[0]['retail_price_percentage'];
    workPercentValue = _settings[0]['work_cost_percentage'];
    profitPercentValue = _settings[0]['profit_percentage'];

    retailPercent.text = retailPercentValue.toString();
    workPercent.text = workPercentValue.toString();
    profitPercent.text = profitPercentValue.toString();

    print(_settings);
    print(profitPercent.text);
  }

  String getCurrentDateTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    return formattedDateTime;
  }

  void handleSave() async {
    final bool hasIng = _ingredients.hasIngredients;
    if (hasIng && _ingredients.hasEmptyQuantity) {
      Fluttertoast.showToast(
        msg: "Enter quantity for all ingredients",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
        fontSize: 16.0,
      );
      return;
    }
    num pct(TextEditingController c) => num.tryParse(c.text) ?? 0;
    final prices = _ingredients.breakdown(
      workPct: pct(workPercent),
      profitPct: pct(profitPercent),
      retailPct: pct(retailPercent),
    );

    if (name.text.isNotEmpty &&
        baseQnty.text.isNotEmpty &&
        sellQnty.text.isNotEmpty &&
        (hasIng || wPrice.text.isNotEmpty) &&
        (hasIng || rPrice.text.isNotEmpty) &&
        mPrice.text.isNotEmpty &&
        retailPercent.text.isNotEmpty &&
        workPercent.text.isNotEmpty &&
        profitPercent.text.isNotEmpty &&
        selectedCategory.isNotEmpty &&
        selectedBaseUnit.isNotEmpty &&
        selectedSellUnit.isNotEmpty &&
        bestBefore.text.isNotEmpty &&
        selectedDuration.isNotEmpty) {
      Map<String, dynamic> itemData = {
        'item_name': name.text,
        'category_id': selectedCategory['category_id'],
        'base_quantity': baseQnty.text,
        'base_unit_id': selectedBaseUnit['unit_id'],
        'sell_quantity': sellQnty.text,
        'sell_unit_id': selectedSellUnit['unit_id'],
        'price_wholesale': hasIng ? prices.wholesale : wPrice.text,
        'price_retail': hasIng ? prices.retail : rPrice.text,
        'retail_price_percentage': retailPercent.text,
        'menu_price': mPrice.text,
        'work_cost_percentage': workPercent.text,
        'profit_percentage': profitPercent.text,
        'best_before': '${bestBefore.text} $selectedDuration',
        'refrigerate': refrigerate == true ? 1 : 0,
        'comments': comments.text,
        'modified_datetime': getCurrentDateTime(),
      };

      if (_isEditing && _editingItemId != null) {
        await _dbhelper.updateItem(itemData, _editingItemId!);
        await _dbhelper.saveItemIngredients(
          _editingItemId!,
          _ingredients.toDbRows(),
        );
        print('item updated');
        Fluttertoast.showToast(
          msg: "${name.text} Updated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        final newItemId = await _dbhelper.insertItem(itemData);
        await _dbhelper.saveItemIngredients(
          newItemId,
          _ingredients.toDbRows(),
        );
        print('item inserted');
        Fluttertoast.showToast(
          msg: "${name.text} Added to Menu",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      setState(() {
        name.clear();
        baseQnty.clear();
        sellQnty.clear();
        wPrice.clear();
        rPrice.clear();
        mPrice.text = '0';
        bestBefore.clear();
        comments.clear();
        refrigerate = false;
        selectedCategory.clear();
        selectedBaseUnit.clear();
        selectedSellUnit.clear();
        selectedDuration = 'Duration';

        retailPercent.text = retailPercentValue.toString();
        workPercent.text = workPercentValue.toString();
        profitPercent.text = profitPercentValue.toString();

        _isEditing = false;
      });
      _ingredients.clear();
    } else {
      Fluttertoast.showToast(
        msg: "Please Fill all the necessary Columns",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  void populateFields(Map<String, dynamic> item) {
    setState(() {
      _isEditing = true;
      _editingItemId = item['item_id'];
      name.text = item['item_name'] ?? '';
      baseQnty.text = item['base_quantity']?.toString() ?? '';
      sellQnty.text = item['sell_quantity']?.toString() ?? '';
      wPrice.text = item['price_wholesale']?.toString() ?? '';
      rPrice.text = item['price_retail']?.toString() ?? '';
      mPrice.text = item['menu_price']?.toString() ?? '';
      retailPercent.text = item['retail_price_percentage']?.toString() ?? '';
      workPercent.text = item['work_cost_percentage']?.toString() ?? '';
      profitPercent.text = item['profit_percentage']?.toString() ?? '';
      comments.text = item['comments'] ?? '';
      refrigerate = item['refrigerate'] == 1;

      // Parse best_before (e.g., "5 days" -> "5" and "days")
      String bestBeforeStr = item['best_before'] ?? '';

      if (bestBeforeStr.isNotEmpty) {
        print("yes");
        List<String> parts = bestBeforeStr.split(' ');
        if (parts.length >= 2) {
          bestBefore.text = parts[0];
          selectedDuration = parts[1];
        }
      }

      // Set selected category
      selectedCategory = {
        'category_id': item['category_id'],
        'category_name': item['category_name'],
      };

      // Set selected units
      selectedBaseUnit = {
        'unit_id': item['base_unit_id'],
        'unit_name': item['base_unit_name'],
      };

      selectedSellUnit = {
        'unit_id': item['sell_unit_id'],
        'unit_name': item['sell_unit_name'],
      };
    });
    _ingredients.loadForItem(item['item_id']);
  }

  void clearFields() {
    setState(() {
      _isEditing = false;
      _editingItemId = null;
      name.clear();
      baseQnty.clear();
      sellQnty.clear();
      wPrice.clear();
      rPrice.clear();
      mPrice.text = '0';
      bestBefore.clear();
      comments.clear();
      refrigerate = false;
      selectedCategory.clear();
      selectedBaseUnit.clear();
      selectedSellUnit.clear();
      selectedDuration = "Duration";

      // Reset percentage fields to default values from settings
      retailPercent.text =
          _settings.isNotEmpty
              ? _settings[0]['retail_price_percentage'].toString()
              : retailPercentValue.toString();
      workPercent.text =
          _settings.isNotEmpty
              ? _settings[0]['work_cost_percentage'].toString()
              : workPercentValue.toString();
      profitPercent.text =
          _settings.isNotEmpty
              ? _settings[0]['profit_percentage'].toString()
              : profitPercentValue.toString();
    });
    _ingredients.clear();
  }

  void deleteModal(int itemId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 30,
                alignment: Alignment.bottomCenter,
                child: const Text(
                  'Delete Item ?',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                iconSize: 30,
                onPressed: () async {
                  bool res = await _dbhelper.getOrderItemById(itemId);
                  if (res == false) {
                    await _dbhelper.deleteItem('item_master', itemId);
                    setState(() {
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: "$name Deleted",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      clearFields();
                    });
                  } else {
                    setState(() {
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: "$name was Ordered. Cannot be Deleted",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.yellow,
                        textColor: Colors.black,
                        fontSize: 16.0,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
    mPrice.text = '0';
    _ingredients.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ingredients.dispose();
    calcW.dispose();
    calcR.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // prices calculated from the ingredients (same function the database uses)
    num n(String t) => num.tryParse(t) ?? 0;
    final prices = _ingredients.breakdown(
      workPct: n(workPercent.text),
      profitPct: n(profitPercent.text),
      retailPct: n(retailPercent.text),
    );
    final bool locked = _ingredients.hasIngredients;
    if (locked) {
      calcW.text = prices.wholesale.toString();
      calcR.text = prices.retail.toString();
    }
    final num mNow = n(mPrice.text);
    final num rNow = locked ? prices.retail : n(rPrice.text);
    final num diff = mNow - rNow;
    final bool showDiff =
        locked || (rPrice.text.isNotEmpty && mPrice.text.isNotEmpty);
    final String baseLabel = baseQnty.text.isEmpty
        ? ''
        : '${baseQnty.text} ${selectedBaseUnit['unit_name'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 20,
            left: 20,
            right: 20,
          ),
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
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                  ),
                  // title
                  Text(
                    'Menu Item',
                    style: TextStyle(fontSize: 30, color: _orange),
                  ),
                  // search button
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SearchMenuItem(
                                  onItemSelected: (selectedItem) {
                                    populateFields(selectedItem);
                                  },
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search, size: 30),
                    ),
                  ),
                ],
              ),
              // heading line
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Divider(thickness: 2.5, color: _grey, height: 35),
              ),
              // Two sections with vertical divider
              SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    150, // Adjust height as needed
                child: Row(
                  children: [
                    // Left section
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Item Details',
                            style: TextStyle(color: _orange, fontSize: 18),
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Name',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ), // Add spacing between fields
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
                                                      _categories[index]['category_name'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                      textAlign:
                                                          TextAlign
                                                              .center, // Aligns the text to the center
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedCategory = {
                                                          'category_id':
                                                              _categories[index]['category_id'],
                                                          'category_name':
                                                              _categories[index]['category_name'],
                                                        };
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
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
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*$'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Base Qnty',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
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
                                                      _units[index]['unit_name'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedBaseUnit = {
                                                          'unit_id':
                                                              _units[index]['unit_id'],
                                                          'unit_name':
                                                              _units[index]['unit_name'],
                                                        };
                                                        selectedSellUnit = {
                                                          'unit_id':
                                                              _units[index]['unit_id'],
                                                          'unit_name':
                                                              _units[index]['unit_name'],
                                                        };
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
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
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*$'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelText: 'Sell Qnty',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
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
                                                      _units[index]['unit_name'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedSellUnit = {
                                                          'unit_id':
                                                              _units[index]['unit_id'],
                                                          'unit_name':
                                                              _units[index]['unit_name'],
                                                        };
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
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
                            style: TextStyle(color: _orange, fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: locked
                                      ? _priceField(
                                          controller: calcW,
                                          label: 'Wholesale',
                                          locked: true,
                                        )
                                      : _priceField(
                                          controller: wPrice,
                                          label: 'Wholesale',
                                          onChanged: (_) => setState(() {}),
                                          onSubmitted: (value) {
                                            num wholesale =
                                                num.tryParse(value) ?? 0;
                                            num retail =
                                                (wholesale +
                                                        (wholesale *
                                                            (num.tryParse(
                                                                  retailPercent
                                                                      .text,
                                                                ) ??
                                                                0) /
                                                            100))
                                                    .round();

                                            setState(() {
                                              rPrice.text = retail.toString();
                                            });
                                          },
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: locked
                                      ? _priceField(
                                          controller: calcR,
                                          label: 'Retail',
                                          locked: true,
                                        )
                                      : _priceField(
                                          controller: rPrice,
                                          label: 'Retail',
                                          onChanged: (_) => setState(() {}),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _priceField(
                                    controller: mPrice,
                                    label: 'Menu',
                                    onChanged: (_) => setState(() {}),
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
                                    obscureText: !_showPercents,
                                    readOnly: !_showPercents,
                                    controller: retailPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*$'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: !_showPercents,
                                      fillColor: Colors.grey.shade200,
                                      labelText: 'Retail %',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
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
                                    obscureText: !_showPercents,
                                    readOnly: !_showPercents,
                                    controller: workPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*$'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: !_showPercents,
                                      fillColor: Colors.grey.shade200,
                                      labelText: 'Work Cost %',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
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
                                    obscureText: !_showPercents,
                                    readOnly: !_showPercents,
                                    controller: profitPercent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*$'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: !_showPercents,
                                      fillColor: Colors.grey.shade200,
                                      labelText: 'Profit %',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: _orange),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 18,
                                          ),
                                      labelText: 'Difference',
                                      labelStyle: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      filled: true,
                                      fillColor: showDiff && diff != 0
                                          ? differenceColor(
                                              diff,
                                            ).withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      showDiff
                                          ? '${diff > 0 ? '+' : ''}${diff.round()}'
                                          : '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: differenceColor(diff),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // show / hide the three percentage fields
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _togglePercents,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _showPercents
                                            ? 'Hide percentages'
                                            : 'Show percentages',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _showPercents
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              width: 150,
                                              // Add this
                                              child: TextField(
                                                controller: bestBefore,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\d*\.?\d*$'),
                                                  ),
                                                ],
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  labelText: 'Value',
                                                  labelStyle: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: _orange,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 150,
                                            height: 55,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
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
                                                          itemBuilder: (
                                                            context,
                                                            index,
                                                          ) {
                                                            return ListTile(
                                                              title: Text(
                                                                _duration[index],
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                    ),
                                                              ),
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedDuration =
                                                                      _duration[index];
                                                                });
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
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
                                                selectedDuration, //??
                                                //'Duration', // Display selected duration or default text
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                      const SizedBox(height: 10),
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
                                                          12,
                                                        ),
                                                  ),
                                                  labelText: '...',
                                                  labelStyle: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: _orange,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Transform.scale(
                                        scale: 1.5,
                                        child: Checkbox(
                                          value: refrigerate,
                                          activeColor: _lightOrange,
                                          onChanged: (value) {
                                            setState(() {
                                              refrigerate = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_isEditing) ...[
                                      IconButton(
                                        onPressed: () {
                                          deleteModal(
                                            _editingItemId!,
                                            name.text,
                                          );
                                        },
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        iconSize: 30,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red
                                              .withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          minimumSize: const Size(55, 55),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    TextButton(
                                      onPressed: () async {
                                        clearFields();
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: _grey,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        minimumSize: const Size(150, 55),
                                      ),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed: () {
                                        handleSave();
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: _lightOrange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        minimumSize: const Size(150, 55),
                                      ),
                                      child: Text(
                                        _isEditing ? 'Update' : 'Save',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 550,
                        child: SingleChildScrollView(
                          child: IngredientsPanel(
                            controller: _ingredients,
                            prices: prices,
                            baseLabel: baseLabel,
                            showBreakdown: _showPercents,
                          ),
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
    );
  }
}
