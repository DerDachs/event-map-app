import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../services/category_service.dart';

// Service Provider
final categoryServiceProvider = Provider((ref) => CategoryService());

// Fetch all categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.fetchCategories();
});

// Fetch category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.fetchCategoryById(categoryId);
});