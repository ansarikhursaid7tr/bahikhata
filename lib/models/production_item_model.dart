/// ProductionItem — a single line item within a production entry.
/// Stores the rate snapshot so old records are never recalculated.
class ProductionItem {
  final String itemTypeId;
  final String itemTypeName;
  final int quantity;
  final double rateSnapshot;
  final double lineTotal;

  ProductionItem({
    required this.itemTypeId,
    required this.itemTypeName,
    required this.quantity,
    required this.rateSnapshot,
    double? lineTotal,
  }) : lineTotal = lineTotal ?? (quantity * rateSnapshot);

  factory ProductionItem.fromMap(Map<String, dynamic> data) {
    return ProductionItem(
      itemTypeId: data['itemTypeId'] ?? '',
      itemTypeName: data['itemTypeName'] ?? '',
      quantity: data['quantity'] ?? 0,
      rateSnapshot: (data['rateSnapshot'] ?? 0).toDouble(),
      lineTotal: (data['lineTotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemTypeId': itemTypeId,
      'itemTypeName': itemTypeName,
      'quantity': quantity,
      'rateSnapshot': rateSnapshot,
      'lineTotal': lineTotal,
    };
  }

  ProductionItem copyWith({
    int? quantity,
    double? rateSnapshot,
  }) {
    final newQty = quantity ?? this.quantity;
    final newRate = rateSnapshot ?? this.rateSnapshot;
    return ProductionItem(
      itemTypeId: itemTypeId,
      itemTypeName: itemTypeName,
      quantity: newQty,
      rateSnapshot: newRate,
      lineTotal: newQty * newRate,
    );
  }
}
