import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/seafood_data.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade50,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: GoogleFonts.poppins(fontSize: 14),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.58,
            ),
            itemCount: seafoodProducts.length,
            itemBuilder: (context, index) {
              final product = seafoodProducts[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
