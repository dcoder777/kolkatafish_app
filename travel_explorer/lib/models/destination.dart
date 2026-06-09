class Destination {
  final String id;
  final String name;
  final String location;
  final String description;
  final double rating;
  final int reviews;
  final String imageUrl;
  final double price;
  final String category;
  final bool isFeatured;
  final bool isPopular;
  final List<String> galleryImages;
  final List<String> highlights;

  const Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.isFeatured = false,
    this.isPopular = false,
    required this.galleryImages,
    required this.highlights,
  });
}
