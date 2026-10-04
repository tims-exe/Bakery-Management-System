import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nissy_bakes_original/database/dbhelper.dart';
import 'package:nissy_bakes_original/services/price_calculator.dart';

const Color _orange = Color.fromRGBO(230, 84, 0, 1);
const Color _lightOrange = Color.fromRGBO(255, 168, 120, 1);
const Color _grey = Color.fromARGB(255, 212, 212, 212);
const Color _totalBg = Color.fromRGBO(255, 236, 214, 1);

// compiled once and shared by every quantity field instead of per rebuild
final RegExp _qtyRegExp = RegExp(r'^\d*\.?\d*');

String _fmt(num n) =>
    n == n.truncate() ? n.truncate().toString() : n.toString();

String _money(num n) => '₹${n.round()}';

// colours for menu - retail: green when positive, red when negative
Color differenceColor(num diff) {
  if (diff > 0) return Colors.green;
  if (diff < 0) return Colors.red;
  return Colors.black54;
}

// one ingredient line of an item
class IngredientRow {
  final int rmId;
  final String name;
  final num rmWeight;
  final num rmCost;
  final String type; // 'edible' or 'packing'
  final int unitId; // locked to the raw material's unit
  final String unitName;
  final TextEditingController qty;

  IngredientRow({
    required this.rmId,
    required this.name,
    required this.rmWeight,
    required this.rmCost,
    required this.type,
    required this.unitId,
    required this.unitName,
    num quantity = 0,
  }) : qty = TextEditingController(text: quantity == 0 ? '' : _fmt(quantity));

  num get quantity => num.tryParse(qty.text) ?? 0;

  num get lineCost => PriceCalculator.ingredientCost(
        quantity: quantity,
        rmWeight: rmWeight,
        rmCost: rmCost,
      );
}

// holds the ingredient rows of the item on screen
class IngredientsController extends ChangeNotifier {
  final _db = DbHelper();

  List<Map<String, dynamic>> rawMaterials = [];
  final List<IngredientRow> edible = [];
  final List<IngredientRow> packing = [];

  bool get hasIngredients => edible.isNotEmpty || packing.isNotEmpty;

  bool get hasEmptyQuantity =>
      [...edible, ...packing].any((r) => r.quantity <= 0);

  Future<void> loadRawMaterials() async {
    rawMaterials = await _db.getRawMaterials();
    notifyListeners();
  }

  // loads an existing item's ingredients from the database
  Future<void> loadForItem(int itemId) async {
    final rows = await _db.getItemIngredients(itemId);
    _disposeRows();
    for (final r in rows) {
      final row = IngredientRow(
        rmId: r['rm_id'],
        name: r['rm_name'],
        rmWeight: r['weight'],
        rmCost: r['cost'],
        type: r['rm_type'],
        unitId: r['unit_id'],
        unitName: r['unit_name'] ?? '',
        quantity: r['quantity'],
      );
      (row.type == 'packing' ? packing : edible).add(row);
    }
    notifyListeners();
  }

  // a new / cleared item starts with nothing
  void clear() {
    _disposeRows();
    notifyListeners();
  }

  void add(Map<String, dynamic> rm) {
    final row = IngredientRow(
      rmId: rm['rm_id'],
      name: rm['rm_name'],
      rmWeight: rm['weight'],
      rmCost: rm['cost'],
      type: rm['rm_type'],
      unitId: rm['base_unit_id'],
      unitName: rm['base_unit_name'] ?? '',
    );
    (row.type == 'packing' ? packing : edible).add(row);
    notifyListeners();
  }

  void remove(IngredientRow row) {
    edible.remove(row);
    packing.remove(row);
    row.qty.dispose();
    notifyListeners();
  }

  void changed() => notifyListeners();

  // rows ready for the database
  List<Map<String, dynamic>> toDbRows() => [
        for (final r in [...edible, ...packing])
          {'rm_id': r.rmId, 'quantity': r.quantity, 'unit_id': r.unitId},
      ];

  PriceBreakdown breakdown({
    required num workPct,
    required num profitPct,
    required num retailPct,
  }) {
    return PriceCalculator.calculate(
      edibleCost: edible.fold<num>(0, (s, r) => s + r.lineCost),
      packingCost: packing.fold<num>(0, (s, r) => s + r.lineCost),
      workPct: workPct,
      profitPct: profitPct,
      retailPct: retailPct,
    );
  }

  void _disposeRows() {
    for (final r in [...edible, ...packing]) {
      r.qty.dispose();
    }
    edible.clear();
    packing.clear();
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }
}

// the right-hand Ingredients section
class IngredientsPanel extends StatelessWidget {
  final IngredientsController controller;
  final PriceBreakdown prices;
  final String baseLabel; // e.g. "10 nos"
  final bool showBreakdown; // work cost and profit rows

  const IngredientsPanel({
    super.key,
    required this.controller,
    required this.prices,
    required this.baseLabel,
    required this.showBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            baseLabel.isEmpty ? 'Ingredients' : 'Ingredients for $baseLabel',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _section(
          context,
          'Edible Ingredients',
          'edible',
          controller.edible,
          'Total Edible',
          prices.edible,
        ),
        const SizedBox(height: 10),
        _section(
          context,
          'Packing',
          'packing',
          controller.packing,
          'Total Packing',
          prices.packing,
        ),
        if (controller.hasIngredients) ...[
          const SizedBox(height: 10),
          if (showBreakdown) ...[
            _summaryRow('Work Cost', _money(prices.work)),
            _summaryRow('Profit Value', _money(prices.profit)),
          ],
          _summaryRow('Total Cost', _money(prices.total), highlight: true),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: highlight
          ? BoxDecoration(
              color: _totalBg,
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _orange),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String type,
    List<IngredientRow> rows,
    String totalLabel,
    num total,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _grey, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                type == 'packing'
                    ? Icons.inventory_2_outlined
                    : Icons.eco_outlined,
                size: 18,
                color: type == 'packing' ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: type == 'packing' ? 'Add packing' : 'Add ingredient',
                onPressed: () => _pickRawMaterial(context, type),
                icon: const Icon(Icons.add_circle, color: _lightOrange),
                iconSize: 30,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
              ),
            ],
          ),
          if (rows.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 2, right: 6),
              child: Row(
                children: [
                  Expanded(flex: 5, child: _HeaderText('Raw Material')),
                  Expanded(flex: 3, child: _HeaderText('Qty')),
                  Expanded(flex: 1, child: _HeaderText('Unit')),
                  Expanded(
                    flex: 2,
                    child: _HeaderText('Cost', align: TextAlign.right),
                  ),
                  SizedBox(width: 32),
                ],
              ),
            ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      row.name,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: row.qty,
                        style: const TextStyle(fontSize: 17),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(_qtyRegExp),
                        ],
                        onChanged: (_) => controller.changed(),
                        decoration: _decoration(),
                      ),
                    ),
                  ),
                  // unit is locked to the raw material's unit
                  Expanded(
                    flex: 1,
                    child: Text(
                      row.unitName,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _money(row.lineCost),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.remove(row),
                    ),
                  ),
                ],
              ),
            ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _totalBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _money(total),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // raw material picker with search, one line per raw material;
  // one raw material per item, so used ones are hidden
  void _pickRawMaterial(BuildContext context, String type) {
    final used = {
      for (final r in [...controller.edible, ...controller.packing]) r.rmId,
    };
    final options = controller.rawMaterials
        .where((r) => r['rm_type'] == type && !used.contains(r['rm_id']))
        .toList();
    String keyword = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final shown = options
                .where(
                  (r) => r['rm_name']
                      .toString()
                      .toLowerCase()
                      .contains(keyword.toLowerCase()),
                )
                .toList();
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                type == 'packing' ? 'Select Packing' : 'Select Raw Material',
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 420,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => keyword = v),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: shown.isEmpty
                          ? const Center(child: Text('Nothing to add'))
                          : ListView.builder(
                              itemCount: shown.length,
                              itemBuilder: (context, i) {
                                final rm = shown[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    rm['rm_name'],
                                    style: const TextStyle(fontSize: 17),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    '${_money(rm['cost'])} · '
                                    '${_fmt(rm['weight'])} '
                                    '${rm['base_unit_name'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  onTap: () {
                                    controller.add(rm);
                                    Navigator.of(dialogContext).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderText(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
}
