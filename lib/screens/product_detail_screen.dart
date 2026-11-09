import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sea_product.dart';
import '../providers/cart_provider.dart';
import '../widgets/app_network_image.dart';

class ProductDetailScreen extends StatelessWidget {
  final SeaProduct product;

  const ProductDetailScreen({super.key, required this.product});

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
    ];
    final placeholderColor = colors[product.id.hashCode.abs() % colors.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null),
            onPressed: () => cart.toggleWishlist(product),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              imageUrl: product.imageUrl,
              height: 260,
              width: double.infinity,
              placeholderColor: placeholderColor,
              fallbackIcon: product.category == 'Meat Mania'
                  ? Icons.restaurant
                  : Icons.set_meal,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(product.name,
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.bold))),
                    if (product.isSale)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('SALE',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  if (product.rating > 0)
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(product.rating.toString(),
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ])
                  else
                    Text('No ratings yet',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(product.formattedPrice,
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.circle,
                        size: 12,
                        color: product.inStock ? Colors.green : Colors.red),
                    const SizedBox(width: 6),
                    Text(product.inStock ? 'In Stock' : 'Out of Stock',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: product.inStock ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 18),

                  // Product Details (Net Wt, Gross Wt, Pieces, etc.)
                  Text('Product Details',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _specItem(
                                icon: Icons.scale_outlined,
                                label: 'Gross Weight',
                                value: product.grossWeight.isNotEmpty
                                    ? product.grossWeight
                                    : (product.weight.isNotEmpty ? product.weight : 'Standard'),
                                color: const Color(0xFFF55D2C),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _specItem(
                                icon: Icons.content_cut,
                                label: 'Net Weight (After Cut)',
                                value: product.netWeight.isNotEmpty
                                    ? product.netWeight
                                    : (product.weight.isNotEmpty ? product.weight : 'Cleaned'),
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        if (product.pieces.isNotEmpty || product.size.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (product.pieces.isNotEmpty)
                                Expanded(
                                  child: _specItem(
                                    icon: Icons.set_meal,
                                    label: 'No. of Pieces',
                                    value: product.pieces,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              if (product.pieces.isNotEmpty && product.size.isNotEmpty)
                                const SizedBox(width: 10),
                              if (product.size.isNotEmpty)
                                Expanded(
                                  child: _specItem(
                                    icon: Icons.straighten,
                                    label: 'Fish Size',
                                    value: product.size,
                                    color: const Color(0xFF7B1FA2),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text('Description',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      product.description.isNotEmpty
                          ? product.description
                          : 'No description provided by the store for this product.',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.6)),
                  if (product.category.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Category',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(product.category,
                          style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(children: [
          IconButton.outlined(
            onPressed: () => cart.toggleWishlist(product),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : const Color(0xFFF55D2C),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isFav ? Colors.red : const Color(0xFFF55D2C),
              ),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isInCart
                ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF55D2C)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => cart.decrementQuantity(product),
                          icon: Icon(
                            cart.getQuantity(product) == 1
                                ? Icons.delete_outline
                                : Icons.remove,
                            color: cart.getQuantity(product) == 1
                                ? Colors.red
                                : const Color(0xFFF55D2C),
                          ),
                        ),
                        Text(
                          '${cart.getQuantity(product)} in Cart (₹${(product.price * cart.getQuantity(product)).toStringAsFixed(0)})',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF55D2C),
                          ),
                        ),
                        IconButton(
                          onPressed: () => cart.incrementQuantity(product),
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFFF55D2C),
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: product.inStock ? () => cart.addToCart(product) : null,
                    icon: Icon(
                      product.inStock
                          ? Icons.add_shopping_cart
                          : Icons.remove_shopping_cart_outlined,
                      size: 18,
                    ),
                    label: Text(
                      product.inStock ? 'Add to Cart' : 'Out of Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.inStock
                          ? const Color(0xFFF55D2C)
                          : Colors.grey.shade300,
                      foregroundColor: product.inStock
                          ? Colors.white
                          : Colors.grey.shade600,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _specItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
