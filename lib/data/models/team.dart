class Team {
  final String id;
  final String name;
  final String eventId;
  final List<String> members; // List of user IDs
  final String leaderId; // Team leader user ID
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.eventId,
    required this.members,
    required this.leaderId,
    required this.createdAt,
  });

  // Convert Team to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'eventId': eventId,
    'members': members,
    'leaderId': leaderId,
    'createdAt': createdAt.toIso8601String(),
  };

  // Create Team from JSON
  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    eventId: json['eventId'],
    members: List<String>.from(json['members']),
    leaderId: json['leaderId'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}