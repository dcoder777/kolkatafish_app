import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/seafood_data.dart';
import '../widgets/paged_product_grid.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryName;
  final IconData? icon;
  final Color? color;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    this.icon,
    this.color,
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
      body: PagedProductGrid(
        categoryName: categoryName,
        fallbackItems: fallback,
        emptyMessage: 'No items in $categoryName yet',
      ),
    );
  }
}
