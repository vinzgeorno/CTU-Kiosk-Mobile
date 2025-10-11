class Ticket {
  final String id;
  final String referenceNumber;
  final String? facility;
  final double? amount;
  final DateTime? visitDate;
  final bool isValid;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.referenceNumber,
    this.facility,
    this.amount,
    this.visitDate,
    required this.isValid,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      referenceNumber: json['reference_number'] as String,
      facility: json['facility'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      visitDate: json['visit_date'] != null 
          ? DateTime.parse(json['visit_date'] as String) 
          : null,
      isValid: json['is_valid'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'facility': facility,
      'amount': amount,
      'visit_date': visitDate?.toIso8601String(),
      'is_valid': isValid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
