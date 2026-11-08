import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/seafood_data.dart';
import '../widgets/paged_product_grid.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryName;
  final IconData? icon;
  final Color? color;
  final String? imageAsset;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    this.icon,
    this.color,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = seafoodProducts
        .where((p) => p.category.toLowerCase() == categoryName.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (imageAsset != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imageAsset!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(16),
                child: Text(
                  categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Expanded(
            child: PagedProductGrid(
              categoryName: categoryName,
              fallbackItems: fallback,
              emptyMessage: 'No items in $categoryName yet',
            ),
          ),
        ],
      ),
    );
  }
}
