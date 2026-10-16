import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sea_product.dart';
import '../providers/cart_provider.dart';
import '../utils/toast_helper.dart';
import 'app_network_image.dart';

class ProductCard extends StatelessWidget {
  final SeaProduct product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final isFav = cart.isInWishlist(product);
    final isInCart = cart.isInCart(product);

    final colors = [
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.green.shade100,
      Colors.pink.shade100,
      Colors.teal.shade100,
      Colors.purple.shade100,
    ];
    final placeholderColor = colors[product.id.hashCode.abs() % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: product.imageUrl,
                    placeholderColor: placeholderColor,
                    fallbackIcon: product.category == 'Meat Mania'
                        ? Icons.restaurant
                        : Icons.set_meal,
                  ),
                  if (product.isSale)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('Sale',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (product.isNew)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('New',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.weight,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey)),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(product.rating.toString(),
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w500)),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  Text(product.formattedPrice,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.circle,
                        size: 8,
                        color: product.inStock ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    Text(product.inStock ? 'In stock' : 'Out of stock',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color:
                                product.inStock ? Colors.green : Colors.red)),
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isInCart
                          ? () {
                              cart.removeFromCart(product);
                              showCartToast(context, product, added: false);
                            }
                          : () {
                              cart.addToCart(product);
                              showCartToast(context, product, added: true);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isInCart ? Colors.grey : const Color(0xFFF55D2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(isInCart ? 'Remove' : 'Add to cart',
                          style: GoogleFonts.poppins(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => cart.toggleWishlist(product),
                    child: Row(children: [
                      Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          size: 14, color: isFav ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(isFav ? 'In wishlist' : 'Add to wishlist',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isFav ? Colors.red : Colors.grey)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
