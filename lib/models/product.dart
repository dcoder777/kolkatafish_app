/// WooCommerce Product model matching the REST API response.
class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String salePrice;
  final List<String> images;
  final List<int> categoryIds;
  final String stockStatus;
  final bool featured;
  final double averageRating;
  final int ratingCount;
  final Map<String, String> metaData;

  const Product({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.shortDescription = '',
    this.price = '0',
    this.regularPrice = '0',
    this.salePrice = '',
    required this.images,
    this.categoryIds = const [],
    this.stockStatus = 'instock',
    this.featured = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.metaData = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesList = (json['images'] as List<dynamic>?)
            ?.map((img) => img['src'] as String? ?? '')
            .where((src) => src.isNotEmpty)
            .toList() ??
        [];

    final categories = (json['categories'] as List<dynamic>?)
            ?.map((cat) => cat['id'] as int)
            .toList() ??
        [];

    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      price: json['price'] as String? ?? '0',
      regularPrice: json['regular_price'] as String? ?? '0',
      salePrice: json['sale_price'] as String? ?? '',
      images: imagesList,
      categoryIds: categories,
      stockStatus: json['stock_status'] as String? ?? 'instock',
      featured: json['featured'] as bool? ?? false,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'short_description': shortDescription,
        'price': price,
        'regular_price': regularPrice,
        'sale_price': salePrice,
        'images': images.map((url) => {'src': url}).toList(),
        'categories': categoryIds.map((id) => {'id': id}).toList(),
        'stock_status': stockStatus,
        'featured': featured,
        'average_rating': averageRating,
        'rating_count': ratingCount,
      };

  /// Whether the product has a sale price.
  bool get onSale => salePrice.isNotEmpty;

  /// Formatted display price.
  String get displayPrice => onSale ? '\$$salePrice' : '\$$price';
}
