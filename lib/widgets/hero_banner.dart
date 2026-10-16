import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  static const String bannerImageUrl =
      'https://kolkatafish.com/wp-content/uploads/2025/10/monson_SALE.png';

  static const double _artAspectRatio = 970 / 250;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: _artAspectRatio,
            child: Image.network(
              bannerImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const ColoredBox(color: Color(0xFFDF8019));
              },
              errorBuilder: (context, error, stackTrace) => _fallbackArt(),
            ),
          ),
          Expanded(child: _caption()),
        ],
      ),
    );
  }

  Widget _caption() {
    return Container(
      color: const Color(0xFFDF8019),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'THE FINEST QUALITY',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Every Catch is a Promise of Freshness',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF55D2C),
            Color(0xFFFF8A65),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CAUGHT FRESH.\nCLEANED RIGHT.\nDELIVERED FAST.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
