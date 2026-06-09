import 'package:flutter/material.dart';
import '../models/category.dart';

final List<Category> categories = [
  Category(
    id: '1',
    name: 'Beaches',
    icon: Icons.beach_access,
    color: const Color(0xFF4FC3F7),
  ),
  Category(
    id: '2',
    name: 'Mountains',
    icon: Icons.terrain,
    color: const Color(0xFF81C784),
  ),
  Category(
    id: '3',
    name: 'Cities',
    icon: Icons.location_city,
    color: const Color(0xFFBA68C8),
  ),
  Category(
    id: '4',
    name: 'Forests',
    icon: Icons.forest,
    color: const Color(0xFF4CAF50),
  ),
  Category(
    id: '5',
    name: 'Historical',
    icon: Icons.account_balance,
    color: const Color(0xFFFF8A65),
  ),
  Category(
    id: '6',
    name: 'Adventure',
    icon: Icons.directions_bike,
    color: const Color(0xFFE57373),
  ),
];
