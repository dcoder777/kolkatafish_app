import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final bool showSubtitle;
  final double iconSize;
  final double fontSize;

  const AppLogo({
    super.key,
    this.showSubtitle = false,
    this.iconSize = 32,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF55D2C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.set_meal,
            color: Colors.white,
            size: iconSize - 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'KolkataFish',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF55D2C),
          ),
        ),
      ],
    );
  }
}
