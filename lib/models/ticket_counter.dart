class TicketCounter {
  const TicketCounter({
    required this.facilityCode,
    required this.facilityName,
    required this.lastSequence,
    this.updatedAt,
    this.isDerived = false,
  });

  final String facilityCode;
  final String facilityName;
  final int lastSequence;
  final DateTime? updatedAt;
  final bool isDerived;

  bool get canEdit => !isDerived;

  TicketCounter copyWith({
    String? facilityCode,
    String? facilityName,
    int? lastSequence,
    DateTime? updatedAt,
    bool? isDerived,
  }) {
    return TicketCounter(
      facilityCode: facilityCode ?? this.facilityCode,
      facilityName: facilityName ?? this.facilityName,
      lastSequence: lastSequence ?? this.lastSequence,
      updatedAt: updatedAt ?? this.updatedAt,
      isDerived: isDerived ?? this.isDerived,
    );
  }

  factory TicketCounter.fromJson(
    Map<String, dynamic> json, {
    String? fallbackFacilityName,
  }) {
    return TicketCounter(
      facilityCode: (json['facility_code'] ?? '').toString(),
      facilityName:
          (json['facility_name'] ??
                  fallbackFacilityName ??
                  json['facility_code'] ??
                  'Unknown')
              .toString(),
      lastSequence: _asInt(json['last_sequence']) ?? 0,
      updatedAt: _asDateTime(json['updated_at']),
      isDerived: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility_code': facilityCode,
      'last_sequence': lastSequence,
      'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
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

  static DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
