import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/seafood_data.dart';
import '../data/sea_categories.dart';
import '../widgets/product_card.dart';
import '../widgets/hero_banner.dart';
import '../widgets/trust_badges.dart';
import 'product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredProducts = seafoodProducts.where((p) => p.isFeatured).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroBanner(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OUR FAVOURITES',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Best Fresh Fish & Meat in Kolkata, Howrah',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'We ONLY sell 100% Fresh Water Products with 0% Chemicals.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: seaCategories.length,
                  itemBuilder: (context, index) {
                    final cat = seaCategories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: GoogleFonts.poppins(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Best Sea Fish, Fresh Fish & Meat Items',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.58,
                ),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
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
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    side: const BorderSide(color: Color(0xFFF55D2C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'LOAD MORE PRODUCTS',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF55D2C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const TrustBadges(),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.set_meal, color: const Color(0xFFF55D2C), size: 28),
              const SizedBox(width: 8),
              Text(
                'KolkataFish',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Disclaimer: KolkataFish is a B2C venture of Kolkata and Howrah for Online Fresh Water Fish, Sea Food Fish, Prawns, Chicken and muttons.',
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _footerLink('Home'),
              _footerLink('About Us'),
              _footerLink('Contact'),
              _footerLink('Shop'),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© Copyright 2025 KolkataFish',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        color: const Color(0xFFF55D2C),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
