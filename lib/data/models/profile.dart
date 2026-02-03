class UserProfile {
  final String uid;
  final String email;
  final Map<String, dynamic>? favorites;
  final String? name;
  final int? age;
  final String? profilePicture;
  final Map<String, dynamic>? preferences;
  final String role;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.age,
    this.profilePicture,
    this.preferences,
    this.favorites,
    required this.role,
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
      favorites: data['favorites'],
      role: data['role'] ?? 'user',
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
      'favorites': favorites,
      'role': role,
    };
  }
}