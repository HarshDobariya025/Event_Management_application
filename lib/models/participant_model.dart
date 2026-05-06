class ParticipantModel {
  final String id;
  final String participantId;
  final String name;
  final String email;
  final String department;
  bool isCheckedIn;
  DateTime? checkInTime;
  String? eventId;

  ParticipantModel({
    required this.id,
    required this.participantId,
    required this.name,
    required this.email,
    required this.department,
    this.isCheckedIn = false,
    this.checkInTime,
    this.eventId,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  ParticipantModel copyWith({
    String? id,
    String? participantId,
    String? name,
    String? email,
    String? department,
    bool? isCheckedIn,
    DateTime? checkInTime,
    String? eventId,
    bool clearCheckInTime = false,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: clearCheckInTime ? null : (checkInTime ?? this.checkInTime),
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'name': name,
      'email': email,
      'department': department,
      'isCheckedIn': isCheckedIn,
      'checkInTime': checkInTime?.toIso8601String(),
      'eventId': eventId,
    };
  }

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      eventId: json['eventId'] as String?,
    );
  }

  @override
  String toString() =>
      'ParticipantModel(participantId: $participantId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
