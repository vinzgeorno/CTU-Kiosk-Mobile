class TransactionBreakdownItem {
  const TransactionBreakdownItem({
    required this.id,
    required this.localTransactionId,
    required this.categoryCode,
    required this.categoryLabel,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final int id;
  final int localTransactionId;
  final String categoryCode;
  final String categoryLabel;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  factory TransactionBreakdownItem.fromJson(Map<String, dynamic> json) {
    return TransactionBreakdownItem(
      id: _asInt(json['id']) ?? 0,
      localTransactionId: _asInt(json['local_transaction_id']) ?? 0,
      categoryCode: (json['category_code'] ?? '').toString(),
      categoryLabel:
          (json['category_label'] ?? json['category_code'] ?? 'Unknown')
              .toString(),
      quantity: _asInt(json['quantity']) ?? 0,
      unitPrice: _asDouble(json['unit_price']),
      subtotal: _asDouble(json['subtotal']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
