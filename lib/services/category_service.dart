import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/category.dart';


class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Category>> fetchCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc.data(), doc.id)).toList();
  }
  Future<Category?> fetchCategoryById(String categoryId) async {
    final doc = await _firestore.collection('categories').doc(categoryId).get();
    if (!doc.exists) return null;
    return Category.fromFirestore(doc.data()!, doc.id);
  }
}