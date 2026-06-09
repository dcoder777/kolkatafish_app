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

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 2;
    final itemCount = widget.images.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
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
        final color = colors[index % colors.length];

        return AnimatedOpacity(
          opacity: _opacities[index],
          duration: Duration(milliseconds: 500),
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
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.white54,
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
                child: Container(
                  decoration: BoxDecoration(color: color),
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
