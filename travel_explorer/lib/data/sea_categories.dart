import 'package:flutter/material.dart';

class SeaCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const SeaCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

final List<SeaCategory> seaCategories = [
  const SeaCategory(
    id: '1',
    name: 'Fresh Water Fish',
    icon: Icons.water,
    color: Color(0xFF2196F3),
  ),
  const SeaCategory(
    id: '2',
    name: 'Prawns & Seafood',
    icon: Icons.set_meal,
    color: Color(0xFFFF9800),
  ),
  const SeaCategory(
    id: '3',
    name: 'Meat Mania',
    icon: Icons.restaurant,
    color: Color(0xFFE91E63),
  ),
  const SeaCategory(
    id: '4',
    name: 'Fresh & Frozen',
    icon: Icons.ac_unit,
    color: Color(0xFF00BCD4),
  ),
];
