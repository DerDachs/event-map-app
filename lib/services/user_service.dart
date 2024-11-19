import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user profile from Firestore
  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('profiles').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, uid);
      }
      return null; // Return null if no profile exists
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Create or update a user profile in Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('profiles').doc(profile.uid).set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving user profile: $e');
    }
  }
}