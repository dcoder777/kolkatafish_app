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
                  Text(
                    product.netWeight.isNotEmpty
                        ? 'Net: ${product.netWeight} | Gross: ${product.grossWeight.isNotEmpty ? product.grossWeight : product.weight}'
                        : (product.grossWeight.isNotEmpty
                            ? 'Gross: ${product.grossWeight}'
                            : (product.weight.isNotEmpty ? product.weight : '500 gm')),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    height: 32,
                    child: isInCart
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF55D2C).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF55D2C)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    cart.decrementQuantity(product);
                                    if (cart.getQuantity(product) == 0) {
                                      showCartToast(context, product, added: false);
                                    }
                                  },
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      cart.getQuantity(product) == 1
                                          ? Icons.delete_outline
                                          : Icons.remove,
                                      size: 15,
                                      color: cart.getQuantity(product) == 1
                                          ? Colors.red
                                          : const Color(0xFFF55D2C),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${cart.getQuantity(product)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF55D2C),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cart.incrementQuantity(product),
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(5),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                      color: Color(0xFFF55D2C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: product.inStock
                                ? () {
                                    cart.addToCart(product);
                                    showCartToast(context, product, added: true);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: product.inStock
                                  ? const Color(0xFFF55D2C)
                                  : Colors.grey.shade300,
                              foregroundColor: product.inStock
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: Text(
                              product.inStock ? 'Add to cart' : 'Out of stock',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
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
