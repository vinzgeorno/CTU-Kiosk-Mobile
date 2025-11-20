import 'package:hive/hive.dart';

part 'ticket_cache.g.dart';

@HiveType(typeId: 0)
class TicketCache extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String referenceNumber;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String facility;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime visitDate;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isValid;

  @HiveField(8)
  final String? imageUrl;

  @HiveField(9)
  final String? email;

  @HiveField(10)
  final String? phone;

  TicketCache({
    required this.id,
    required this.referenceNumber,
    required this.name,
    required this.facility,
    required this.amount,
    required this.visitDate,
    required this.createdAt,
    required this.isValid,
    this.imageUrl,
    this.email,
    this.phone,
  });

  factory TicketCache.fromJson(Map<String, dynamic> json) {
    return TicketCache(
      id: json['id'].toString(),
      referenceNumber: json['reference_number'] ?? '',
      name: json['name'] ?? 'Unknown',
      facility: json['facility'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      visitDate: json['visit_date'] != null
          ? DateTime.parse(json['visit_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isValid: json['is_valid'] ?? false,
      imageUrl: json['image_url'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'name': name,
      'facility': facility,
      'amount': amount,
      'visit_date': visitDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_valid': isValid,
      'image_url': imageUrl,
      'email': email,
      'phone': phone,
    };
  }
}
