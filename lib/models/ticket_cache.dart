import 'package:hive/hive.dart';

part 'ticket_cache.g.dart';

@HiveType(typeId: 0)
class TicketCache extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String referenceNumber;

  @HiveField(2)
  final int? age;

  @HiveField(3)
  final String facility;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime visitDate;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String transactionStatus;

  @HiveField(8)
  final String? ageCategory;

  @HiveField(9)
  final double? amountDue;

  @HiveField(10)
  final double? changeAmount;

  @HiveField(11)
  final String? ticketType;

  @HiveField(12)
  final int? totalPeople;

  @HiveField(13)
  final int? peopleBelow12;

  @HiveField(14)
  final int? people12Above;

  @HiveField(15)
  final bool? isClubMember;

  @HiveField(16)
  final bool? isResident;

  TicketCache({
    required this.id,
    required this.referenceNumber,
    this.age,
    required this.facility,
    required this.amount,
    required this.visitDate,
    required this.createdAt,
    required this.transactionStatus,
    this.ageCategory,
    this.amountDue,
    this.changeAmount,
    this.ticketType,
    this.totalPeople,
    this.peopleBelow12,
    this.people12Above,
    this.isClubMember,
    this.isResident,
  });

  factory TicketCache.fromJson(Map<String, dynamic> json) {
    return TicketCache(
      id: json['id'].toString(),
      referenceNumber: json['reference_number'] ?? '',
      age: json['age'] as int?,
      ageCategory: json['age_category'] as String?,
      facility: json['facility'] ?? 'Unknown',
      amount: json['amount_paid'] != null
          ? (json['amount_paid'] as num).toDouble()
          : (json['amount'] ?? 0).toDouble(),
      amountDue: json['amount_due'] != null
          ? (json['amount_due'] as num).toDouble()
          : null,
      changeAmount: json['change_amount'] != null
          ? (json['change_amount'] as num).toDouble()
          : null,
      ticketType: json['ticket_type'] as String?,
      visitDate: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      transactionStatus: json['transaction_status'] ?? 'completed',
      totalPeople: json['total_people'] as int?,
      peopleBelow12: json['people_below_12'] as int?,
      people12Above: json['people_12_above'] as int?,
      isClubMember: json['is_club_member'] as bool?,
      isResident: json['is_resident'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'age': age,
      'age_category': ageCategory,
      'facility': facility,
      'amount_paid': amount,
      'amount_due': amountDue,
      'change_amount': changeAmount,
      'ticket_type': ticketType,
      'created_at': createdAt.toIso8601String(),
      'transaction_status': transactionStatus,
      'total_people': totalPeople,
      'people_below_12': peopleBelow12,
      'people_12_above': people12Above,
      'is_club_member': isClubMember,
      'is_resident': isResident,
    };
  }
}
