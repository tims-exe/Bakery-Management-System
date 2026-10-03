// The single place where item prices are calculated from ingredient costs.
// Every caller (item screen preview, saving an item, raw material changes)
// uses this, so the numbers can never disagree.

class PriceBreakdown {
  final num edible; // total cost of edible raw materials
  final num packing; // total cost of packing raw materials
  final num work; // edible x work %
  final num profit; // edible x profit %
  final num total; // edible + packing + work + profit
  final num wholesale; // total, rounded to a whole rupee
  final num retail; // rounded wholesale + retail % of it, rounded

  const PriceBreakdown({
    required this.edible,
    required this.packing,
    required this.work,
    required this.profit,
    required this.total,
    required this.wholesale,
    required this.retail,
  });
}

class PriceCalculator {
  // cost of using [quantity] of a raw material that is bought as
  // [rmWeight] for [rmCost] (quantity is in the raw material's own unit)
  static num ingredientCost({
    required num quantity,
    required num rmWeight,
    required num rmCost,
  }) {
    if (rmWeight <= 0) return 0;
    return quantity / rmWeight * rmCost;
  }

  static PriceBreakdown calculate({
    required num edibleCost,
    required num packingCost,
    required num workPct,
    required num profitPct,
    required num retailPct,
  }) {
    final work = edibleCost * workPct / 100;
    final profit = edibleCost * profitPct / 100;
    final total = edibleCost + packingCost + work + profit;
    final wholesale = total.round();
    final retail = (wholesale + wholesale * retailPct / 100).round();
    return PriceBreakdown(
      edible: edibleCost,
      packing: packingCost,
      work: work,
      profit: profit,
      total: total,
      wholesale: wholesale,
      retail: retail,
    );
  }
}
