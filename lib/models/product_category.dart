/// WooCommerce Product Category model matching the REST API response.
class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String imageUrl;
  final int parentId;
  final int count;

  const ProductCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.imageUrl = '',
    this.parentId = 0,
    this.count = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    return ProductCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: image?['src'] as String? ?? '',
      parentId: json['parent'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'image': imageUrl.isNotEmpty ? {'src': imageUrl} : null,
        'parent': parentId,
        'count': count,
      };
}
