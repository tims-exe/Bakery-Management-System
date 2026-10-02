import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';
import '../components/search_raw_material.dart';

class RawMaterialsPage extends StatefulWidget {
  const RawMaterialsPage({super.key});

  @override
  State<RawMaterialsPage> createState() => _RawMaterialsPageState();
}

class _RawMaterialsPageState extends State<RawMaterialsPage> {
  final _dbhelper = DbHelper();

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  static const List<String> _rmTypes = ['edible', 'packing'];

  List<Map<String, dynamic>> _rawMaterials = [];
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;

  // null = show all, otherwise 'edible' or 'packing'
  String? _typeFilter;

  int currentRmID = 0;
  bool _isEdit = false;

  // cost of the raw material being edited, moves to prev_cost on save
  num _currentCost = 0;

  Map<String, dynamic> selectedUnit = {};
  String selectedType = 'edible';

  // all textfield variables
  TextEditingController name = TextEditingController();
  TextEditingController weight = TextEditingController();
  TextEditingController cost = TextEditingController();
  TextEditingController comments = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    name.dispose();
    weight.dispose();
    cost.dispose();
    comments.dispose();
    super.dispose();
  }

  // load units and raw materials
  Future<void> loadData() async {
    _units = await _dbhelper.getUnits('unit_master');
    _rawMaterials = await _dbhelper.getRawMaterials();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> loadRawMaterials() async {
    final data = await _dbhelper.getRawMaterials();
    if (!mounted) return;
    setState(() {
      _rawMaterials = data;
    });
  }

  // 500.0 -> 500, 2.5 -> 2.5
  String formatNum(dynamic value) {
    final n = value as num;
    return n == n.truncate() ? n.truncate().toString() : n.toString();
  }

  String nowString() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String typeLabel(String type) => type == 'packing' ? 'Packing' : 'Edible';

  // clear raw material details
  void clearAll() {
    setState(() {
      name.clear();
      weight.clear();
      cost.clear();
      comments.clear();
      selectedUnit = {};
      selectedType = 'edible';
      currentRmID = 0;
      _currentCost = 0;
      _isEdit = false;
    });
  }

  // load a raw material into the right panel
  void loadIntoForm(Map<String, dynamic> rm) {
    setState(() {
      _isEdit = true;
      currentRmID = rm['rm_id'];
      name.text = rm['rm_name'];
      weight.text = formatNum(rm['weight']);
      cost.text = formatNum(rm['cost']);
      comments.text = rm['rm_comments'] ?? '';
      selectedUnit = {
        'unit_id': rm['base_unit_id'],
        'unit_name': rm['base_unit_name'],
      };
      selectedType = rm['rm_type'];
      _currentCost = rm['cost'];
    });
  }

  // show toast
  void showToast(String m, Color color) {
    Fluttertoast.showToast(
      msg: m,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void showWarning(String m) => showToast(m, Colors.red);

  // validate and save
  Future<void> save() async {
    if (name.text.trim().isEmpty ||
        weight.text.isEmpty ||
        cost.text.isEmpty ||
        selectedUnit['unit_id'] == null) {
      showWarning('Enter Name, Weight, Unit and Cost');
      return;
    }

    final weightValue = num.tryParse(weight.text);
    final costValue = num.tryParse(cost.text);
    if (weightValue == null || costValue == null) {
      showWarning('Enter valid Weight and Cost');
      return;
    }
    if (weightValue <= 0) {
      showWarning('Weight should be greater than 0');
      return;
    }

    final now = nowString();
    final rm = <String, dynamic>{
      'rm_name': name.text.trim(),
      'weight': weightValue,
      'base_unit_id': selectedUnit['unit_id'],
      'cost': costValue,
      'rm_type': selectedType,
      'rm_comments': comments.text,
      'modified_datetime': now,
    };

    try {
      if (_isEdit) {
        // old cost always moves to prev_cost on save
        rm['prev_cost'] = _currentCost;
        await _dbhelper.updateRawMaterial(rm, currentRmID);
        showToast('${rm['rm_name']} Updated', Colors.green);
      } else {
        rm['created_datetime'] = now;
        await _dbhelper.insertRawMaterial(rm);
        showToast('${rm['rm_name']} Added', Colors.green);
      }
    } on DatabaseException catch (e) {
      // rm_name is UNIQUE (case-insensitive) in the db
      if (e.isUniqueConstraintError()) {
        showWarning('${rm['rm_name']} already exists');
        return;
      }
      rethrow;
    }

    clearAll();
    await loadRawMaterials();
  }

  // delete pop up
  void deleteModal(int rmID, String rmName) {
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
                  'Delete Raw Material ?',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                iconSize: 30,
                onPressed: () async {
                  await _dbhelper.deleteRawMaterial(rmID);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  showWarning('Deleted $rmName');
                  clearAll();
                  await loadRawMaterials();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // unit dropdown
  void showUnitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select a Unit', textAlign: TextAlign.center),
          content: SizedBox(
            width: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _units.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _units[index]['unit_name'],
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      selectedUnit = {
                        'unit_id': _units[index]['unit_id'],
                        'unit_name': _units[index]['unit_name'],
                      };
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // rm type dropdown
  void showTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select a Type', textAlign: TextAlign.center),
          content: SizedBox(
            width: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _rmTypes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    typeLabel(_rmTypes[index]),
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      selectedType = _rmTypes[index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // edible / packing tag
  Widget typeChip(String type) {
    final bool packing = type == 'packing';
    final Color color = packing ? Colors.blue : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            packing ? Icons.inventory_2_outlined : Icons.eco_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(typeLabel(type), style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  InputDecoration fieldDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _orange),
      ),
      hintText: '...',
    );
  }

  // label on the left, input on the right
  Widget formRow(String label, Widget input) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label : ', style: const TextStyle(fontSize: 18)),
          SizedBox(width: 250, child: input),
        ],
      ),
    );
  }

  // button that opens a dropdown dialog
  Widget dropdownButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget decimalField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: fieldDecoration(),
    );
  }

  // filter by type button
  Widget typeFilterButton() {
    return PopupMenuButton<String>(
      tooltip: 'Filter by type',
      color: Colors.white,
      icon: Icon(
        Icons.filter_list,
        size: 30,
        color: _typeFilter == null ? Colors.black : _orange,
      ),
      onSelected: (value) {
        setState(() {
          // 'all' is a real value because a null value is treated as dismissed
          _typeFilter = value == 'all' ? null : value;
        });
      },
      itemBuilder:
          (context) => [
            for (final option in <String>['all', ..._rmTypes])
              PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      (_typeFilter ?? 'all') == option ? Icons.check : null,
                      size: 20,
                      color: _orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option == 'all' ? 'All' : typeLabel(option),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
          ],
    );
  }

  Widget rawMaterialList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final shown =
        _typeFilter == null
            ? _rawMaterials
            : _rawMaterials
                .where((rm) => rm['rm_type'] == _typeFilter)
                .toList();
    if (shown.isEmpty) {
      return const Center(child: Text('No raw materials found'));
    }
    return ListView.builder(
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final rm = shown[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 25, top: 10),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${rm['rm_name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${formatNum(rm['weight'])} ${rm['base_unit_name'] ?? ''}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${formatNum(rm['cost'])}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    typeChip(rm['rm_type']),
                  ],
                ),
                onLongPress: () {
                  deleteModal(rm['rm_id'], rm['rm_name']);
                },
                onTap: () {
                  loadIntoForm(rm);
                },
              ),
            ),
            Divider(
              thickness: 0.5,
              color: _grey,
              height: 2,
              indent: 10,
              endIndent: 40,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // close button
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            // pop the page, then the settings drawer
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 30,
                        ),
                        // keeps the title centred
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // title
                  Text(
                    'Raw Materials',
                    style: TextStyle(fontSize: 30, color: _orange),
                  ),
                  // search button
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        typeFilterButton(),
                        IconButton(
                          onPressed: () {
                            clearAll();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SearchRawMaterial(
                                      onSelect: (rm) {
                                        loadIntoForm(rm);
                                      },
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, size: 30),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // heading line
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Divider(thickness: 2.5, color: _grey, height: 35),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // all raw materials
                  Expanded(
                    child: SizedBox(height: 620, child: rawMaterialList()),
                  ),
                  // raw material data
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Container(
                      width: 450,
                      height: 620,
                      decoration: BoxDecoration(
                        border: Border.all(color: _grey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isEdit
                                        ? "${name.text}'s Details"
                                        : 'Raw Material Details',
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (!_isEdit) {
                                      clearAll();
                                    } else if (name.text != '') {
                                      deleteModal(currentRmID, name.text);
                                    }
                                  },
                                  icon: const Icon(Icons.delete),
                                  iconSize: 30,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    formRow(
                                      'Name',
                                      TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: name,
                                        decoration: fieldDecoration(),
                                      ),
                                    ),
                                    formRow(
                                      'Weight',
                                      Row(
                                        children: [
                                          Expanded(child: decimalField(weight)),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 100,
                                            child: dropdownButton(
                                              selectedUnit['unit_name'] ??
                                                  'Unit',
                                              showUnitDialog,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    formRow('Cost (₹)', decimalField(cost)),
                                    formRow(
                                      'Type',
                                      dropdownButton(
                                        typeLabel(selectedType),
                                        showTypeDialog,
                                      ),
                                    ),
                                    formRow(
                                      'Comments',
                                      TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: comments,
                                        keyboardType: TextInputType.text,
                                        decoration: fieldDecoration(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // footer buttons
                            Row(
                              children: [
                                Expanded(
                                  child: MaterialButton(
                                    onPressed: clearAll,
                                    color: Colors.white,
                                    height: 70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: _grey, width: 2),
                                    ),
                                    elevation: 0,
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 25),
                                Expanded(
                                  child: MaterialButton(
                                    onPressed: save,
                                    color: _lightOrange,
                                    height: 70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
