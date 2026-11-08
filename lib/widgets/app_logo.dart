import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.height = 34,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF55D2C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.set_meal,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'KolkataFish',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF55D2C),
            ),
          ),
        ],
      ),
    );
  }
}
