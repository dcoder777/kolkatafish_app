import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About KolkataFish',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.set_meal,
                size: 64,
                color: Color(0xFFF55D2C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'KolkataFish',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Us',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'KolkataFish is a B2C venture of Kolkata and Howrah for Online Fresh Water Fish, Sea Food Fish, Prawns, Chicken and Muttons. We are committed to delivering the freshest catch directly to your doorstep.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Promise',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _featureItem(Icons.verified, '100% Fresh Water Products'),
                  _featureItem(Icons.science, '0% Chemicals'),
                  _featureItem(Icons.local_shipping, 'Home Delivery'),
                  _featureItem(Icons.support_agent, '24/7 Customer Support'),
                  _featureItem(Icons.lock, 'Secure Payments'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tech Stack',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _techItem('Flutter', 'UI Framework'),
                  _techItem('Material 3', 'Design System'),
                  _techItem('WooCommerce', 'Backend API'),
                  _techItem('Google Fonts', 'Typography'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made with ❤️ for Kolkata',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF55D2C)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _techItem(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
