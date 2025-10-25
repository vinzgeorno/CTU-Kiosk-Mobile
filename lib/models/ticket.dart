class Ticket {
  final int id;
  final String referenceNumber;
  final String name;
  final int? age;
  final String? capturedImageUrl;
  final String facility;
  final double paymentAmount;
  final double? originalPrice;
  final bool hasDiscount;
  final DateTime dateCreated;
  final DateTime dateExpiry;
  final String? qrCodeData;
  final String transactionStatus;
  final String? methodType;
  final double? amountInserted;
  final double? changeGiven;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Ticket({
    required this.id,
    required this.referenceNumber,
    required this.name,
    this.age,
    this.capturedImageUrl,
    required this.facility,
    required this.paymentAmount,
    this.originalPrice,
    required this.hasDiscount,
    required this.dateCreated,
    required this.dateExpiry,
    this.qrCodeData,
    required this.transactionStatus,
    this.methodType,
    this.amountInserted,
    this.changeGiven,
    this.syncedAt,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters for backward compatibility
  double get amount => paymentAmount;
  DateTime get visitDate => dateCreated;
  
  // Check if ticket is valid based on expiry date and transaction status
  bool get isValid {
    final now = DateTime.now();
    final isNotExpired = dateExpiry.isAfter(now);
    final isCompleted = transactionStatus == 'completed';
    return isNotExpired && isCompleted;
  }
  
  // Check if ticket has expired
  bool get isExpired => DateTime.now().isAfter(dateExpiry);
  
  // Get expiry status message
  String get expiryStatus {
    if (isExpired) {
      final difference = DateTime.now().difference(dateExpiry);
      if (difference.inDays > 0) {
        return 'Expired ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return 'Expired ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Expired ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    } else {
      final difference = dateExpiry.difference(DateTime.now());
      if (difference.inDays > 0) {
        return 'Valid for ${difference.inDays} more day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Valid for ${difference.inHours} more hour${difference.inHours > 1 ? 's' : ''}';
      } else {
        return 'Valid for ${difference.inMinutes} more minute${difference.inMinutes > 1 ? 's' : ''}';
      }
    }
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      referenceNumber: json['reference_number'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      capturedImageUrl: json['captured_image_url'] as String?,
      facility: json['facility'] as String,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      originalPrice: json['original_price'] != null 
          ? (json['original_price'] as num).toDouble() 
          : null,
      hasDiscount: json['has_discount'] as bool? ?? false,
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateExpiry: DateTime.parse(json['date_expiry'] as String),
      qrCodeData: json['qr_code_data'] as String?,
      transactionStatus: json['transaction_status'] as String? ?? 'completed',
      methodType: json['method_type'] as String?,
      amountInserted: json['amount_inserted'] != null 
          ? (json['amount_inserted'] as num).toDouble() 
          : null,
      changeGiven: json['change_given'] != null 
          ? (json['change_given'] as num).toDouble() 
          : null,
      syncedAt: json['synced_at'] != null 
          ? DateTime.parse(json['synced_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'name': name,
      'age': age,
      'captured_image_url': capturedImageUrl,
      'facility': facility,
      'payment_amount': paymentAmount,
      'original_price': originalPrice,
      'has_discount': hasDiscount,
      'date_created': dateCreated.toIso8601String(),
      'date_expiry': dateExpiry.toIso8601String(),
      'qr_code_data': qrCodeData,
      'transaction_status': transactionStatus,
      'method_type': methodType,
      'amount_inserted': amountInserted,
      'change_given': changeGiven,
      'synced_at': syncedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
