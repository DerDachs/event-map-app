import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore;

  FavoriteService(this._firestore);

  // Add an item (event or stand) to favorites
  Future<void> addFavorite(String userId, String category, String itemId) async {
    await _firestore.collection('profiles').doc(userId).update({
      'favorites.$category': FieldValue.arrayUnion([itemId]),
    });
  }

  // Remove an item (event or stand) from favorites
  Future<void> removeFavorite(String userId, String category, String itemId) async {
    await _firestore.collection('profiles').doc(userId).update({
      'favorites.$category': FieldValue.arrayRemove([itemId]),
    });
  }

  // Fetch all favorites for a user
  Future<Map<String, List<String>>> getFavorites(String userId) async {
    final userDoc = await _firestore.collection('profiles').doc(userId).get();
    final data = userDoc.data()?['favorites'] as Map<String, dynamic>? ?? {};
    return data.map((key, value) => MapEntry(key, List<String>.from(value ?? [])));
  }
}