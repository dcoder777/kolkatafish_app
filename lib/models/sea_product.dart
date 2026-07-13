/// Seafood product model for KolkataFish app.
class SeaProduct {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final String weight;
  final String imageUrl;
  final bool inStock;
  final bool isFeatured;
  final bool isNew;
  final bool isSale;
  final double rating;

  const SeaProduct({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.price,
    required this.priceUnit,
    this.weight = '500 gm',
    this.imageUrl = '',
    this.inStock = true,
    this.isFeatured = false,
    this.isNew = false,
    this.isSale = false,
    this.rating = 4.5,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)} / $priceUnit';
}
