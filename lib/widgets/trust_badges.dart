import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrustBadges extends StatelessWidget {
  const TrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _badge(theme, Icons.local_shipping, 'Free Delivery', 'For orders above ₹1000'),
              _badge(theme, Icons.verified, 'Guarantee Fresh', '100% Fresh, No Chemicals'),
              _badge(theme, Icons.lock, 'Secure Payment', '100% Secure Checkout'),
              _badge(theme, Icons.headset_mic, '24/7 Support', 'Always there for you'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(ThemeData theme, IconData icon, String title, String subtitle) {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF55D2C), size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
