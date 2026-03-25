class Ticket {
  final int id;
  final String referenceNumber;
  final int? age;
  final String? ageCategory;
  final String facility;
  final double amountPaid;
  final double? amountDue;
  final double? changeAmount;
  final String? ticketType; // 'solo' or 'bulk'
  final String transactionStatus;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int? totalPeople;
  final int? peopleBelow12;
  final int? people12Above;
  final bool? isClubMember;
  final bool? isResident;
  final double? transactionTimeSec;
  final double? printTimeSec;

  Ticket({
    required this.id,
    required this.referenceNumber,
    this.age,
    this.ageCategory,
    required this.facility,
    required this.amountPaid,
    this.amountDue,
    this.changeAmount,
    this.ticketType,
    required this.transactionStatus,
    required this.createdAt,
    this.syncedAt,
    this.totalPeople,
    this.peopleBelow12,
    this.people12Above,
    this.isClubMember,
    this.isResident,
    this.transactionTimeSec,
    this.printTimeSec,
  });

  // Helper getters for backward compatibility
  double get amount => amountPaid;
  DateTime get visitDate => createdAt;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      referenceNumber: json['reference_number'] as String,
      age: json['age'] as int?,
      ageCategory: json['age_category'] as String?,
      facility: json['facility'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      amountDue: json['amount_due'] != null
          ? (json['amount_due'] as num).toDouble()
          : null,
      changeAmount: json['change_amount'] != null
          ? (json['change_amount'] as num).toDouble()
          : null,
      ticketType: json['ticket_type'] as String?,
      transactionStatus: json['transaction_status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      totalPeople: json['total_people'] as int?,
      peopleBelow12: json['people_below_12'] as int?,
      people12Above: json['people_12_above'] as int?,
      isClubMember: json['is_club_member'] as bool?,
      isResident: json['is_resident'] as bool?,
      transactionTimeSec: json['transaction_time_sec'] != null
          ? (json['transaction_time_sec'] as num).toDouble()
          : null,
      printTimeSec: json['print_time_sec'] != null
          ? (json['print_time_sec'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'age': age,
      'age_category': ageCategory,
      'facility': facility,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'change_amount': changeAmount,
      'ticket_type': ticketType,
      'transaction_status': transactionStatus,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'total_people': totalPeople,
      'people_below_12': peopleBelow12,
      'people_12_above': people12Above,
      'is_club_member': isClubMember,
      'is_resident': isResident,
      'transaction_time_sec': transactionTimeSec,
      'print_time_sec': printTimeSec,
    };
  }
}
