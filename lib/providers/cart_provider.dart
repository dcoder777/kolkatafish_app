import 'package:flutter/material.dart';
import '../models/sea_product.dart';

class CartProvider extends ChangeNotifier {
  final List<SeaProduct> _cartItems = [];
  final List<SeaProduct> _wishlistItems = [];

  List<SeaProduct> get cartItems => List.unmodifiable(_cartItems);
  List<SeaProduct> get wishlistItems => List.unmodifiable(_wishlistItems);
  int get cartCount => _cartItems.length;
  int get wishlistCount => _wishlistItems.length;
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price);

  bool isInCart(SeaProduct product) =>
      _cartItems.any((p) => p.id == product.id);
  bool isInWishlist(SeaProduct product) =>
      _wishlistItems.any((p) => p.id == product.id);

  void addToCart(SeaProduct product) {
    if (!isInCart(product)) {
      _cartItems.add(product);
      notifyListeners();
    }
  }

  void removeFromCart(SeaProduct product) {
    _cartItems.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }

  void toggleWishlist(SeaProduct product) {
    if (isInWishlist(product)) {
      _wishlistItems.removeWhere((p) => p.id == product.id);
    } else {
      _wishlistItems.add(product);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
