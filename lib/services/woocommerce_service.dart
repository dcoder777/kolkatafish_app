import 'dart:convert';
import '../models/product.dart';
import '../models/product_category.dart';
import 'api_client.dart';

/// WooCommerce REST API service layer.
///
/// Provides typed methods for every WooCommerce endpoint the app consumes.
class WooCommerceService {
  final ApiClient _api;

  WooCommerceService({ApiClient? api}) : _api = api ?? ApiClient();

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  /// Fetch a paginated list of products.
  Future<List<Product>> getProducts({
    int page = 1,
    int perPage = 20,
    String? category,
    String? search,
    bool? featured,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (featured != null) 'featured': featured.toString(),
    };

    final response = await _api.get('/products', params: params);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw WooCommerceException('Failed to fetch products', response.statusCode);
  }

  /// Fetch a single product by [id].
  Future<Product> getProduct(int id) async {
    final response = await _api.get('/products/$id');

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw WooCommerceException('Failed to fetch product $id', response.statusCode);
  }

  /// Fetch featured products.
  Future<List<Product>> getFeaturedProducts({int page = 1}) =>
      getProducts(page: page, featured: true);

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  /// Fetch all product categories.
  Future<List<ProductCategory>> getCategories({int perPage = 100}) async {
    final params = <String, String>{
      'per_page': perPage.toString(),
    };

    final response = await _api.get('/products/categories', params: params);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProductCategory.fromJson(json)).toList();
    }
    throw WooCommerceException('Failed to fetch categories', response.statusCode);
  }
}

/// Custom exception for WooCommerce API errors.
class WooCommerceException implements Exception {
  final String message;
  final int statusCode;

  const WooCommerceException(this.message, this.statusCode);

  @override
  String toString() => 'WooCommerceException($statusCode): $message';
}
