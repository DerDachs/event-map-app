class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final int? age;
  final String? profilePicture;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.age,
    this.profilePicture,
    this.preferences,
  });

  // Factory method for creating a UserProfile from Firestore
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      age: data['age'],
      profilePicture: data['profilePicture'],
      preferences: data['preferences'],
    );
  }

  // Method for converting UserProfile to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'profilePicture': profilePicture,
      'preferences': preferences,
    };
  }
}