import 'package:flutter/material.dart';
import '../models/category.dart';

final List<Category> categories = [
  const Category(
    id: '1',
    name: 'Beaches',
    icon: Icons.beach_access,
    color: Color(0xFF4FC3F7),
  ),
  const Category(
    id: '2',
    name: 'Mountains',
    icon: Icons.terrain,
    color: Color(0xFF81C784),
  ),
  const Category(
    id: '3',
    name: 'Cities',
    icon: Icons.location_city,
    color: Color(0xFFBA68C8),
  ),
  const Category(
    id: '4',
    name: 'Forests',
    icon: Icons.forest,
    color: Color(0xFF4CAF50),
  ),
  const Category(
    id: '5',
    name: 'Historical',
    icon: Icons.account_balance,
    color: Color(0xFFFF8A65),
  ),
  const Category(
    id: '6',
    name: 'Adventure',
    icon: Icons.directions_bike,
    color: Color(0xFFE57373),
  ),
];
