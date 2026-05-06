class EventModel {
  final String id;
  final String name;
  final DateTime dateTime;
  final int maxCapacity;
  final String venue;
  final String description;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.maxCapacity,
    required this.venue,
    required this.description,
    required this.createdAt,
  });

  EventModel copyWith({
    String? id,
    String? name,
    DateTime? dateTime,
    int? maxCapacity,
    String? venue,
    String? description,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'maxCapacity': maxCapacity,
      'venue': venue,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      maxCapacity: json['maxCapacity'] as int,
      venue: json['venue'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'EventModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EventModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
