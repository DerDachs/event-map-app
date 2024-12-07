import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String eventId;
  final List<String> members; // List of user IDs
  final String leaderId; // Team leader user ID
  final DateTime createdAt;
  final String teamCode; // New field for readable code


  Team({
    required this.id,
    required this.name,
    required this.eventId,
    required this.members,
    required this.leaderId,
    required this.createdAt,
    required this.teamCode,
  });

  // Convert Team to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'eventId': eventId,
    'memberIds': members,
    'leaderId': leaderId,
    'createdAt': createdAt.toIso8601String(),
    'teamCode': teamCode,
  };

  // Create Team from JSON
  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    eventId: json['eventId'],
    members: List<String>.from(json['memberIds']),
    leaderId: json['leaderId'],
    createdAt: DateTime.parse(json['createdAt']),
    teamCode: json['teamCode'],
  );

  // Create Team from Firestore DocumentSnapshot
  factory Team.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Team(
      id: doc.id, // Use the document ID from Firestore
      name: data['name'] ?? '',
      eventId: data['eventId'] ?? '',
      members: List<String>.from(data['memberIds'] ?? []),
      leaderId: data['leaderId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      teamCode: data['teamCode'] ?? '',
    );
  }
}