class TeamMember {
  final String userId;
  final bool isSharingLocation;
  final DateTime? locationShareExpiresAt;

  TeamMember({
    required this.userId,
    required this.isSharingLocation,
    this.locationShareExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'isSharingLocation': isSharingLocation,
    'locationShareExpiresAt': locationShareExpiresAt?.toIso8601String(),
  };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    userId: json['userId'],
    isSharingLocation: json['isSharingLocation'] ?? false,
    locationShareExpiresAt: json['locationShareExpiresAt'] != null
        ? DateTime.parse(json['locationShareExpiresAt'])
        : null,
  );
}