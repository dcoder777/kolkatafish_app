import 'package:flutter/material.dart';
import '../config/data_source.dart';
import '../models/destination.dart';
import '../models/category.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';

/// Application-wide state provider.
///
/// Exposes data and loading state to the widget tree via [ChangeNotifier].
/// Switch [RuntimeConfig.current] to [DataSource.api] to enable WooCommerce.
class AppProvider extends ChangeNotifier {
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;

  AppProvider({
    ProductRepository? productRepo,
    CategoryRepository? categoryRepo,
  })  : _productRepo = productRepo ?? ProductRepository(),
        _categoryRepo = categoryRepo ?? CategoryRepository();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<Destination> _featured = [];
  List<Destination> _popular = [];
  List<Destination> _all = [];
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;

  List<Destination> get featured => _featured;
  List<Destination> get popular => _popular;
  List<Destination> get all => _all;
  List<Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  bool get isUsingApi => RuntimeConfig.useApi;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Initialise and load data.
  Future<void> init() async {
    await loadAll();
  }

  /// Load all data from the active data source.
  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _productRepo.getProducts(featured: true),
        _productRepo.getProducts(popular: true),
        _productRepo.getProducts(),
        _categoryRepo.getCategories(),
      ]);

      _featured = results[0] as List<Destination>;
      _popular = results[1] as List<Destination>;
      _all = results[2] as List<Destination>;
      _categories = results[3] as List<Category>;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  /// Toggle between static and API data sources.
  Future<void> toggleDataSource() async {
    RuntimeConfig.current = isUsingApi ? DataSource.static : DataSource.api;
    await loadAll();
  }
}
