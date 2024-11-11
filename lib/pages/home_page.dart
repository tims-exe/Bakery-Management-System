import 'package:flutter/material.dart';
import 'package:nissy_bakes_app/components/search_item.dart';
import 'package:nissy_bakes_app/components/settings_drawer.dart';
import 'package:nissy_bakes_app/database/dbhelper.dart';
import 'package:nissy_bakes_app/pages/order_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // database helper to access database functions
  final DbHelper _dbhelper = DbHelper();

  // variables
  var _category = 1;

  final _defaultNo = 1;

  List<Map<String, dynamic>> _currentOrder = [];

  Map<String, dynamic> _currentBill = {};

  List<Map<String, dynamic>> category = [];

  final Color _orange = const Color.fromRGBO(255, 168, 120, 1);

  List<Map<String, dynamic>> _units = [];

  // fetch all units to store in a list
  void _loadUnits() async {
    List<Map<String, dynamic>> units = await _dbhelper.getUnits('unit_master');
    setState(() {
      _units = units;
    });
  }

  // search units based on unit id
  String _getUnitId(int index) {
    for (int i = 0; i < _units.length; i++) {
      if (_units[i]['unit_id'] == index) {
        return _units[i]['unit_name'];
      }
    }
    return '.';
  }

  bool checkCurrentOrder(Map item) {
    if (_currentOrder.any((index) => index['item'] == item['item_name'])) {
      return false;
    } else {
      return true;
    }
  }

  void updateCurrentOrderNo(Map item) {
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i]['item'] == item['item_name']) {
        _currentOrder[i]['no']++;
      }
    }
  }

  void addtoCurrentOrder(Map item) {
    if (checkCurrentOrder(item)) {
      setState(() {
        _currentOrder.add({
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

  // function to update current bill
  void updateCurrentBill() {
    _currentBill['bill_number_type'] = 'B';
    _currentBill['bill_number_financial_year'] = 2425;
    _currentBill['bill_number'] = 0;
    _currentBill['bill_date'] = '';
    _currentBill['customer_id'] = 1;
    _currentBill['delivery_date'] = '';
    _currentBill['delivery_time'] = '';
    _currentBill['total_amount'] = 0;
    _currentBill['delivery_charges'] = 0;
    _currentBill['comments'] = '';
    _currentBill['produced'] = false;
    _currentBill['sticker_print'] = false;
    _currentBill['bill_sent'] = false;
    _currentBill['delivered'] = false;
    _currentBill['payment_done'] = false;
    _currentBill['discount_amount'] = 0;
    _currentBill['advance_paid'] = 0;
    _currentBill['final_payment'] = 0;
    _currentBill['modified_datetime'] = '';
  }

  Future<void> getCategoryHomeScreen() async {
    category = await _dbhelper.getCategory('item_category');
    setState(() {});
  }

  // initial run function
  @override
  void initState() {
    super.initState();

    _loadUnits();
    updateCurrentBill();

    Future.delayed(const Duration(seconds: 1), () {
      getCategoryHomeScreen();
    });
  }

  // main component
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // change it to the actual colour
      //backgroundColor: Colors.grey,
      backgroundColor: const Color.fromRGBO(214, 214, 214, 1),
      body: Row(
        children: [
          // Left side NavBar
          Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height,
            width: 220,
            child: Column(
              children: [
                Center(
                  // logo
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Image.asset(
                      'assets/home_logo.png',
                      width: 120,
                    ),
                  ),
                ),
                // All Categories
                Expanded(
                  child: category.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ListView.builder(
                            itemCount: category.length,
                            itemBuilder: (context, index) {
                              final ctgy = category[index];
                              return SizedBox(
                                height: 60,
                                child: ListTile(
                                  title: TextButton(
                                    style: TextButton.styleFrom(
                                        // beware of index value. if category_id changes (if row gets deleted)
                                        backgroundColor: _category - 1 == index
                                            ? _orange
                                            : Colors.white,
                                        minimumSize: const Size(50, 50),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    child: Text(
                                      ctgy['category_name'],
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _category = ctgy['category_id'];
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                )
              ],
            ),
          ),
          // Menu Screen
          Container(
            margin: const EdgeInsets.only(left: 30, top: 30, bottom: 30),
            height: MediaQuery.of(context).size.height,
            width: 650,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            // displaying items
            child: Column(
              children: [
                // heading
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 10, left: 15, right: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 70,
                      ),
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      MaterialButton(
                        minWidth: 60,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchItem(
                                  getOrder: _currentOrder,
                                  onSave: (updatedOrder) {
                                    setState(() {
                                      _currentOrder = updatedOrder;
                                    });
                                  }),
                            ),
                          );
                        },
                        elevation: 0,
                        child: const Icon(
                          Icons.search,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey,
                    height: 20, // Space above and below the line
                  ),
                ),
                // menu items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _dbhelper.getItems(
                          'item_master', 'category_id = ?', [_category]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error : ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No items found'),
                          );
                        }
                        final items = snapshot.data!;
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: MaterialButton(
                                height: 65,
                                onPressed: () {
                                  addtoCurrentOrder(item);
                                },
                                // item name
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: Text(
                                        item['item_name'],
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.normal),
                                      ),
                                    ),
                                    // quantity
                                    Row(
                                      children: [
                                        Text(
                                          '${item['sell_quantity']} ${_getUnitId(item['sell_unit_id'])}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 50,
                                        ),
                                        const Text(
                                          ':',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        const SizedBox(
                                          width: 50,
                                        ),
                                        // price
                                        Text(
                                          '₹${item['menu_price']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side Nav Bar
          Container(
            margin: const EdgeInsets.only(left: 30, top: 30, bottom: 30),
            height: MediaQuery.of(context).size.height,
            width: 320,
            child: Column(
              children: [
                // Current Order Screen
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // title
                        const Padding(
                          padding: EdgeInsets.only(top: 20, bottom: 10),
                          child: Text(
                            'Current Order',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 20, right: 20, bottom: 20),
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey,
                            height: 20, // Space above and below the line
                          ),
                        ),
                        // current order items
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: StatefulBuilder(
                              builder: (context, setStateFunction) {
                                return ListView.builder(
                                  itemCount: _currentOrder.length,
                                  itemBuilder: (context, index) {
                                    final item = _currentOrder[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            //color: Colors.amber,
                                            width: 150,
                                            child: Text(
                                              item['item'],
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          // control number of items
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  setStateFunction(() {
                                                    item['no']--;
                                                    if (item['no'] == 0) {
                                                      _currentOrder
                                                          .removeAt(index);
                                                    }
                                                  });
                                                },
                                                icon: const Icon(Icons.remove),
                                                iconSize: 22,
                                              ),
                                              Text(
                                                item['no'].toString(),
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setStateFunction(() {
                                                    item['no']++;
                                                  });
                                                },
                                                icon: const Icon(Icons.add),
                                                iconSize: 22,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        // checkout button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 20),
                          child: TextButton(
                            style: TextButton.styleFrom(
                                // beware of index value. if category_id changes (if row gets deleted)
                                backgroundColor: _orange,
                                minimumSize: const Size(270, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderPage(
                                    getBill: _currentBill,
                                    getOrder: _currentOrder,
                                    onSaveBill: (updatedBill) {
                                      setState(() {
                                        _currentBill = updatedBill;
                                        if (_currentBill.isEmpty) {
                                          updateCurrentBill();
                                        }
                                      });
                                    },
                                    onSaveOrder: (updatedOrder) {
                                      setState(() {
                                        _currentOrder = updatedOrder;
                                      });
                                    },
                                    isEdit: false,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Nav Bar
                Container(
                  height: 75,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: MaterialButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/itemspage');
                          },
                          elevation: 0,
                          hoverElevation: 0,
                          hoverColor: const Color.fromRGBO(214, 214, 214, 1),
                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: MaterialButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/productionpage');
                          },
                          elevation: 0,
                          hoverElevation: 0,
                          hoverColor: const Color.fromRGBO(214, 214, 214, 1),
                          child: const Icon(
                            Icons.today,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Builder(
                          builder: (context) => MaterialButton(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            elevation: 0,
                            hoverElevation: 0,
                            hoverColor: const Color.fromRGBO(214, 214, 214, 1),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      endDrawer: const Drawer(child: SettingsDrawer()),
    );
  }
}
