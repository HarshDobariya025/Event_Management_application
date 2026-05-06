class CheckInRecord {
  final String id;
  final String participantId;
  final String participantName;
  final String eventId;
  final DateTime timestamp;
  final String method;
  bool isSynced;

  CheckInRecord({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.eventId,
    required this.timestamp,
    required this.method,
    this.isSynced = true,
  });

  CheckInRecord copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? eventId,
    DateTime? timestamp,
    String? method,
    bool? isSynced,
  }) {
    return CheckInRecord(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      eventId: eventId ?? this.eventId,
      timestamp: timestamp ?? this.timestamp,
      method: method ?? this.method,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'eventId': eventId,
      'timestamp': timestamp.toIso8601String(),
      'method': method,
      'isSynced': isSynced,
    };
  }

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String? ?? '',
      eventId: json['eventId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      method: json['method'] as String,
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'CheckInRecord(participantId: $participantId, timestamp: $timestamp)';
}

enum CheckInResult {
  success,
  alreadyCheckedIn,
  capacityFull,
  participantNotFound,
  noActiveEvent,
}
