import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/destinations_data.dart';
import '../widgets/gallery_grid.dart';

class GalleryScreen extends StatelessWidget {
  final int? initialIndex;

  const GalleryScreen({super.key, this.initialIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allImages = <String>[];
    for (final dest in destinations) {
      allImages.addAll(dest.galleryImages);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gallery',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                '${allImages.length} Photos',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GalleryGrid(images: allImages, tag: 'gallery'),
          ],
        ),
      ),
    );
  }
}
