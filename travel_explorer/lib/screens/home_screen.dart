import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';
import '../widgets/hero_banner.dart';
import '../widgets/trust_badges.dart';
import '../data/seafood_data.dart';
import '../data/sea_categories.dart';
import '../widgets/product_card.dart';
import 'shop_tab.dart';
import 'about_tab.dart';
import 'contact_tab_v2.dart';
import 'profile_tab.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone, size: 16),
              label: Text(
                'Call us',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _navIndex == 0 ? _buildHomeContent(context) : _getScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavTap,
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Colors.white,
        elevation: 8,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: const Color(0xFFF55D2C).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFF55D2C)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info_rounded, color: Color(0xFFF55D2C)),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded, color: Color(0xFFF55D2C)),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail_rounded, color: Color(0xFFF55D2C)),
            label: 'Contact',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFF55D2C)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getScreen() {
    switch (_navIndex) {
      case 1:
        return const AboutTab();
      case 2:
        return const ShopTab();
      case 3:
        return const ContactTab();
      case 4:
        return ProfileTab(onToggleTheme: widget.onToggleTheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    final featuredProducts =
        seafoodProducts.where((p) => p.isFeatured).toList();

    return SingleChildScrollView(
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
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
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
              onPressed: () => _onNavTap(2),
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
              const Icon(Icons.set_meal, color: Color(0xFFF55D2C), size: 28),
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
              _footerLink('Home', () => _onNavTap(0)),
              _footerLink('About Us', () => _onNavTap(1)),
              _footerLink('Contact', () => _onNavTap(3)),
              _footerLink('Shop', () => _onNavTap(2)),
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

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFFF55D2C),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
