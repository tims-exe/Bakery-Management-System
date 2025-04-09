import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';

class UnitConversion extends StatefulWidget {
  final Map<String, dynamic> getItem;
  final Function(Map<String, dynamic>) onSave;

  const UnitConversion({super.key, required this.getItem, required this.onSave});

  @override
  State<UnitConversion> createState() => _UnitConversionState();
}

class _UnitConversionState extends State<UnitConversion> {
  final DbHelper _dbHelper = DbHelper();

  final Color _orange = const Color.fromRGBO(255, 168, 120, 1);
  Map<String, dynamic> currentItem = {};

  TextEditingController conversionQntyFieldController = TextEditingController();
  TextEditingController sellQntyFieldController = TextEditingController();
  TextEditingController sellRateFieldController = TextEditingController();

  String currentSellUnit = '';
  int currentSellUnitID = 0;

  List<Map<String, dynamic>> units = [];

  List<String> unitList = [];

  Future getUnitList() async {
    units = await _dbHelper.getUnits('unit_master');

    for (int i = 0; i < units.length; i++) {
      unitList.add(units[i]['unit_name']);
    }
  }

  // search units based on unit id
  int getUnitId(int id) {
    return units[id]['unit_id'];
  }

  void updateConversionRates() {
    if (mounted) {
      setState(() {
        conversionQntyFieldController.text =
            currentItem['conversion'].toString();
        currentItem['sell_rate'] = num.parse(
            ((currentItem['price'] / currentItem['weight']) *
                    currentItem['conversion'])
                .toStringAsFixed(2));
        if (currentItem['unit'] == currentSellUnit) {
          currentItem['sell_qnty'] = currentItem['conversion'];
          sellQntyFieldController.text = currentItem['sell_qnty'].toString();
        }
        sellRateFieldController.text = currentItem['sell_rate'].toString();
        currentSellUnit = currentItem['sell_unit'];
        currentSellUnitID = currentItem['sell_unit_id'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    currentItem = widget.getItem;
    conversionQntyFieldController.text = currentItem['conversion'].toString();
    sellQntyFieldController.text = currentItem['sell_qnty'].toString();
    sellRateFieldController.text = currentItem['sell_rate'].toString();
    currentSellUnit = currentItem['sell_unit'];
    currentSellUnitID = currentItem['sell_unit_id'];
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        getUnitList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Unit Conversion',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          width: 400,
          height: 310,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // item name
                  Text(
                    '${currentItem['item']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Base Qnty',
                    style: TextStyle(fontSize: 18),
                  ),
                  // base quantity
                  Text(
                    '${currentItem['weight']} ${currentItem['unit']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Base Rate',
                    style: TextStyle(fontSize: 18),
                  ),
                  // base rate
                  Text(
                    '${currentItem['price']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Qnty (${currentItem['unit']})',
                    style: const TextStyle(fontSize: 18),
                  ),
                  // coneversion quantity
                  SizedBox(
                    width: 80,
                    height: 30,
                    child: TextField(
                      controller: conversionQntyFieldController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          value == '0'
                              ? currentItem['conversion'] = 1
                              : currentItem['conversion'] = num.parse(value);
                        }
                        updateConversionRates();
                      },
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      onTap: () {
                        conversionQntyFieldController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset:
                              conversionQntyFieldController.text.length,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sell Qnty',
                    style: TextStyle(fontSize: 18),
                  ),
                  // sell quantity
                  SizedBox(
                    width: 80,
                    height: 30,
                    child: TextField(
                      controller: sellQntyFieldController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && value != '0') {
                          currentItem['sell_qnty'] = num.parse(value);
                        }
                        if (mounted) {
                          setState(() {
                            sellQntyFieldController.text =
                                currentItem['sell_qnty'].toString();
                          });
                        }
                      },
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      onTap: () {
                        sellQntyFieldController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: sellQntyFieldController.text.length,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sell Unit',
                    style: TextStyle(fontSize: 18),
                  ),
                  // sell unit
                  Container(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: currentSellUnit,
                      icon: const SizedBox.shrink(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      onChanged: (String? newValue) {
                        if (mounted) {
                          setState(() {
                            currentSellUnit = newValue!;
                            currentSellUnitID =
                                getUnitId(unitList.indexOf(currentSellUnit));
                          });
                        }
                      },
                      items: unitList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                          ),
                        );
                      }).toList(),
                      underline: const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sell Rate',
                    style: TextStyle(fontSize: 18),
                  ),
                  // sell rate
                  SizedBox(
                    width: 80,
                    height: 30,
                    child: TextField(
                      controller: sellRateFieldController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && value != '0') {
                          currentItem['sell_rate'] = num.parse(value);
                        }
                        if (mounted) {
                          setState(() {
                            sellRateFieldController.text =
                                currentItem['sell_rate'].toString();
                          });
                        }
                      },
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      onTap: () {
                        sellRateFieldController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: sellRateFieldController.text.length,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            currentItem['conversion'] =
                num.parse(conversionQntyFieldController.text);
            currentItem['sell_qnty'] = num.parse(sellQntyFieldController.text);
            currentItem['sell_rate'] = num.parse(sellRateFieldController.text);
            currentItem['sell_unit'] = currentSellUnit;
            currentItem['sell_unit_id'] = currentSellUnitID;
            widget.onSave(currentItem); // Save changes
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
