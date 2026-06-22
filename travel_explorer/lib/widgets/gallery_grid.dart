import 'package:flutter/material.dart';

class GalleryGrid extends StatefulWidget {
  final List<String> images;
  final String tag;

  const GalleryGrid({
    super.key,
    required this.images,
    required this.tag,
  });

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  late List<double> _opacities;

  @override
  void initState() {
    super.initState();
    _opacities = List.filled(widget.images.length, 0.0);
    _animateItems();
  }

  void _animateItems() {
    for (int i = 0; i < widget.images.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) {
          setState(() {
            _opacities[i] = 1.0;
          });
        }
      });
    }
  }

  String _getImageUrl(String imageName) {
    // Use picsum.photos with a seed derived from the image name for consistent unique images
    return 'https://picsum.photos/seed/$imageName/400/400';
  }

  Color _getColorFromSeed(String seed) {
    final hash = seed.hashCode.abs();
    final colors = [
      Colors.blue.shade300,
      Colors.teal.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.green.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.cyan.shade300,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 2;
    final itemCount = widget.images.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final imageName = widget.images[index];
        final color = _getColorFromSeed(imageName);

        return AnimatedOpacity(
          opacity: _opacities[index],
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            _getImageUrl(imageName),
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 100,
                                  color: Colors.white54,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Hero(
                tag: '${widget.tag}_$index',
                child: Image.network(
                  _getImageUrl(imageName),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(color: color),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(color: color),
                      child: const Center(
                        child: Icon(
                          Icons.photo,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}