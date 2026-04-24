class AdminTransaction {
  const AdminTransaction({
    required this.localTransactionId,
    required this.sessionId,
    required this.facilityCode,
    required this.facilityName,
    required this.ticketLabel,
    required this.totalUnits,
    required this.amountDue,
    required this.amountPaid,
    required this.createdAt,
    required this.startedAt,
    required this.durationMs,
    required this.paymentStatus,
    required this.printStatus,
    required this.syncStatus,
    this.remoteId,
    this.ticketStartNo,
    this.ticketEndNo,
    this.completedAt,
    this.syncedAt,
    this.isBulk = false,
    this.printAttempts = 0,
    this.sourceMode,
    this.errorMessage,
  });

  final String? remoteId;
  final int localTransactionId;
  final String sessionId;
  final String facilityCode;
  final String facilityName;
  final int? ticketStartNo;
  final int? ticketEndNo;
  final String ticketLabel;
  final bool isBulk;
  final int totalUnits;
  final double amountDue;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMs;
  final String paymentStatus;
  final String printStatus;
  final String syncStatus;
  final DateTime? syncedAt;
  final int printAttempts;
  final String? sourceMode;
  final String? errorMessage;

  DateTime get effectiveTimestamp => completedAt ?? createdAt;

  Duration get duration =>
      Duration(milliseconds: durationMs < 0 ? 0 : durationMs);

  String get displayLabel =>
      ticketLabel.isNotEmpty ? ticketLabel : 'TX-$localTransactionId';

  int get endingSequence =>
      ticketEndNo ??
      _extractTrailingSequence(ticketLabel) ??
      localTransactionId;

  bool matchesQuery(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return displayLabel.toLowerCase().contains(query) ||
        sessionId.toLowerCase().contains(query) ||
        facilityCode.toLowerCase().contains(query) ||
        facilityName.toLowerCase().contains(query) ||
        localTransactionId.toString().contains(query);
  }

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    final localTransactionId =
        _asInt(json['local_transaction_id']) ?? _asInt(json['id']) ?? 0;
    final syncedAt = _asDateTime(json['synced_at']);

    return AdminTransaction(
      remoteId: json['id']?.toString(),
      localTransactionId: localTransactionId,
      sessionId: (json['session_id'] ?? '').toString(),
      facilityCode: (json['facility_code'] ?? '').toString(),
      facilityName:
          (json['facility_name'] ?? json['facility_code'] ?? 'Unknown')
              .toString(),
      ticketStartNo: _asInt(json['ticket_start_no']),
      ticketEndNo: _asInt(json['ticket_end_no']),
      ticketLabel: (json['ticket_label'] ?? '').toString(),
      isBulk: json['is_bulk'] == true,
      totalUnits: _asInt(json['total_units']) ?? 0,
      amountDue: _asDouble(json['amount_due']),
      amountPaid: _asDouble(json['amount_paid']),
      createdAt: _asDateTime(json['created_at']) ?? DateTime.now().toUtc(),
      startedAt:
          _asDateTime(json['started_at']) ??
          _asDateTime(json['created_at']) ??
          DateTime.now().toUtc(),
      completedAt: _asDateTime(json['completed_at']),
      durationMs: _asInt(json['duration_ms']) ?? 0,
      paymentStatus: (json['payment_status'] ?? 'unknown').toString(),
      printStatus: (json['print_status'] ?? 'unknown').toString(),
      syncStatus:
          (json['sync_status'] ?? (syncedAt != null ? 'synced' : 'live'))
              .toString(),
      syncedAt: syncedAt,
      printAttempts: _asInt(json['print_attempts']) ?? 0,
      sourceMode: json['source_mode']?.toString(),
      errorMessage: json['error_message']?.toString(),
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

  static DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int? _extractTrailingSequence(String value) {
    final match = RegExp(r'(\d+)$').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}
