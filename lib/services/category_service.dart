import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Category>> fetchCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs
        .map((doc) => Category.fromFirestore(doc, null))
        .toList();
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    final doc = await _firestore.collection('categories').doc(categoryId).get();
    if (!doc.exists) return null;
    return Category.fromFirestore(doc, null);
  }

  Future<List<Category>> getCategoriesByIds(List<String> categoryIds) async {
    final querySnapshot = await _firestore
        .collection('categories')
        .where(FieldPath.documentId, whereIn: categoryIds)
        .get();

    return querySnapshot.docs
        .map((doc) => Category.fromFirestore(doc, null))
        .toList();
  }

  Future<List<Category>> fetchCategoriesForEvent(String eventId) async {
    try {
      // Fetch the event document
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception("Event not found");
      }

      // Extract the list of category IDs from the event document
      final List<String> categoryIds =
      List<String>.from(eventDoc.data()!['categories'] ?? []);

      if (categoryIds.isEmpty) {
        return [
        ]; // Return an empty list if no categories are associated with the event
      }

      // Fetch categories from the 'category' collection where the ID is in categoryIds
      final querySnapshot = await _firestore
          .collection('category')
          .where(FieldPath.documentId, whereIn: categoryIds)
          .get();

      // Map the query results to a list of Category objects
      final List<Category> categories = querySnapshot.docs.map((doc) {
        return Category.fromFirestore(doc,null);
      }).toList();

      return categories;
    } catch (e) {
      print('Error fetching categories for event: $e');
      throw Exception('Failed to fetch categories');
    }
  }
}
