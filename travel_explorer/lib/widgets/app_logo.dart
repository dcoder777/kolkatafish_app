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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.set_meal,
            color: Colors.white,
            size: iconSize - 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KolkataFish',
              style: GoogleFonts.playfairDisplay(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (showSubtitle)
              Text(
                'Fresh seafood, delivered',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
