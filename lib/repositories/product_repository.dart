import '../config/data_source.dart';
import '../data/destinations_data.dart' as static_data;
import '../models/destination.dart';
import '../models/product.dart';
import '../services/woocommerce_service.dart';

/// Repository for product data.
///
/// Abstracts the data source — returns static dummy data when
/// [RuntimeConfig.useApi] is false, and calls WooCommerce API otherwise.
class ProductRepository {
  final WooCommerceService? _api;

  ProductRepository({WooCommerceService? api}) : _api = api;

  /// Map a WooCommerce [Product] to a [Destination] for the current UI.
  static Destination productToDestination(Product product) {
    return Destination(
      id: product.id.toString(),
      name: product.name,
      location: product.stockStatus == 'instock' ? 'In Stock' : 'Out of Stock',
      description: product.description.isNotEmpty
          ? product.description
          : product.shortDescription,
      rating: product.averageRating,
      reviews: product.ratingCount,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      price: double.tryParse(product.price) ?? 0,
      category: product.categoryIds.isNotEmpty
          ? 'Category ${product.categoryIds.first}'
          : 'General',
      isFeatured: product.featured,
      isPopular: product.averageRating >= 4.0,
      galleryImages: product.images,
      highlights: [
        if (product.onSale) 'On Sale: \$${product.salePrice}',
        'Regular Price: \$${product.regularPrice}',
        if (product.stockStatus == 'instock') 'In Stock',
        'Rating: ${product.averageRating}',
      ],
    );
  }

  /// Fetch all products.
  Future<List<Destination>> getProducts({
    bool? featured,
    bool? popular,
    int page = 1,
  }) async {
    if (!RuntimeConfig.useApi) {
      var items = static_data.destinations;
      if (featured == true) items = items.where((d) => d.isFeatured).toList();
      if (popular == true) items = items.where((d) => d.isPopular).toList();
      return items;
    }

    try {
      final products = await _api!.getProducts(page: page, featured: featured);
      var list = products.map(productToDestination).toList();
      if (popular == true) {
        list = list.where((d) => d.isPopular).toList();
      }
      return list;
    } catch (e) {
      // Fallback to static data on error
      var items = static_data.destinations;
      if (featured == true) items = items.where((d) => d.isFeatured).toList();
      if (popular == true) items = items.where((d) => d.isPopular).toList();
      return items;
    }
  }

  /// Fetch a single product by id.
  Future<Destination> getProductById(String id) async {
    if (!RuntimeConfig.useApi) {
      return static_data.destinations.firstWhere((d) => d.id == id);
    }

    try {
      final product = await _api!.getProduct(int.parse(id));
      return productToDestination(product);
    } catch (e) {
      return static_data.destinations.firstWhere((d) => d.id == id);
    }
  }
}
