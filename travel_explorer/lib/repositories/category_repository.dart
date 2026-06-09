import 'package:flutter/material.dart';
import '../config/data_source.dart';
import '../data/categories_data.dart' as static_data;
import '../models/category.dart';
import '../models/product_category.dart';
import '../services/woocommerce_service.dart';

/// Repository for category data.
///
/// Abstracts the data source — returns static dummy data when
/// [RuntimeConfig.useApi] is false, and calls WooCommerce API otherwise.
class CategoryRepository {
  final WooCommerceService? _api;

  CategoryRepository({WooCommerceService? api}) : _api = api;

  static final _categoryColors = [
    const Color(0xFF4FC3F7),
    const Color(0xFF81C784),
    const Color(0xFFBA68C8),
    const Color(0xFF4CAF50),
    const Color(0xFFFF8A65),
    const Color(0xFFE57373),
    const Color(0xFF64B5F6),
    const Color(0xFF9575CD),
  ];

  static final _categoryIcons = [
    Icons.set_meal,
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.local_grocery_store,
    Icons.kitchen,
    Icons.egg,
    Icons.water_drop,
    Icons.forest,
  ];

  /// Map a WooCommerce [ProductCategory] to a [Category] for the current UI.
  static Category productCategoryToCategory(ProductCategory pc) {
    final idx = pc.id % _categoryColors.length;
    return Category(
      id: pc.id.toString(),
      name: pc.name,
      icon: _categoryIcons[idx],
      color: _categoryColors[idx],
    );
  }

  /// Fetch all categories.
  Future<List<Category>> getCategories() async {
    if (!RuntimeConfig.useApi) {
      return static_data.categories;
    }

    try {
      final categories = await _api!.getCategories();
      return categories.map(productCategoryToCategory).toList();
    } catch (e) {
      return static_data.categories;
    }
  }
}
