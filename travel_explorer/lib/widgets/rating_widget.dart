import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int reviews;
  final double size;

  const RatingWidget({
    super.key,
    required this.rating,
    this.reviews = 0,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ...List.generate(5, (index) {
          final starFill = rating - index;
          IconData icon;
          if (starFill >= 1) {
            icon = Icons.star;
          } else if (starFill >= 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, color: Colors.amber, size: size);
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviews reviews)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
