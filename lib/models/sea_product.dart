/// Seafood product model for KolkataFish app.
class SeaProduct {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final String weight;
  final String grossWeight;
  final String netWeight;
  final String pieces;
  final String size;
  final String shortDescription;
  final String imageUrl;
  final bool inStock;
  final bool isFeatured;
  final bool isNew;
  final bool isSale;
  final double rating;

  /// True for bundled/offline catalogue entries. These are display-only:
  /// their ids and prices are NOT real WooCommerce products and must never
  /// be sent to the live store checkout.
  final bool isFallback;

  const SeaProduct({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.price,
    required this.priceUnit,
    this.weight = '500 gm',
    this.grossWeight = '',
    this.netWeight = '',
    this.pieces = '',
    this.size = '',
    this.shortDescription = '',
    this.imageUrl = '',
    this.inStock = true,
    this.isFeatured = false,
    this.isNew = false,
    this.isSale = false,
    this.rating = 0,
    this.isFallback = false,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)} / $priceUnit';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'priceUnit': priceUnit,
        'weight': weight,
        'grossWeight': grossWeight,
        'netWeight': netWeight,
        'pieces': pieces,
        'size': size,
        'shortDescription': shortDescription,
        'imageUrl': imageUrl,
        'inStock': inStock,
        'isFeatured': isFeatured,
        'isNew': isNew,
        'isSale': isSale,
        'rating': rating,
        'isFallback': isFallback,
      };

  factory SeaProduct.fromJson(Map<String, dynamic> json) {
    return SeaProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      priceUnit: json['priceUnit']?.toString() ?? 'Kg',
      weight: json['weight']?.toString() ?? '500 gm',
      grossWeight: json['grossWeight']?.toString() ?? '',
      netWeight: json['netWeight']?.toString() ?? '',
      pieces: json['pieces']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      inStock: json['inStock'] != false,
      isFeatured: json['isFeatured'] == true,
      isNew: json['isNew'] == true,
      isSale: json['isSale'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isFallback: json['isFallback'] == true,
    );
  }
}
