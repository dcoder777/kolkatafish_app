import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sea_product.dart';

class PlacedOrderLine {
  final String name;
  final double price;
  final String weight;

  const PlacedOrderLine({
    required this.name,
    required this.price,
    required this.weight,
  });
}

class PlacedOrder {
  final String id;
  final int? serverId;
  final String orderKey;
  final String status;
  final bool synced;
  final double total;
  final String payment;
  final DateTime placedAt;
  final String customerName;
  final String phone;
  final String address;
  final List<PlacedOrderLine> items;

  PlacedOrder({
    required this.id,
    this.serverId,
    this.orderKey = '',
    this.status = 'processing',
    this.synced = false,
    required this.total,
    required this.payment,
    required this.placedAt,
    this.customerName = '',
    this.phone = '',
    this.address = '',
    this.items = const [],
  });

  String get displayId => serverId != null ? '#$serverId' : id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'orderKey': orderKey,
        'status': status,
        'synced': synced,
        'total': total,
        'payment': payment,
        'placedAt': placedAt.toIso8601String(),
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'items': items
            .map((l) => {'name': l.name, 'price': l.price, 'weight': l.weight})
            .toList(),
      };

  factory PlacedOrder.fromJson(Map<String, dynamic> json) {
    return PlacedOrder(
      id: json['id']?.toString() ?? '',
      serverId: (json['serverId'] as num?)?.toInt(),
      orderKey: json['orderKey']?.toString() ?? '',
      status: json['status']?.toString() ?? 'processing',
      synced: json['synced'] == true,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      payment: json['payment']?.toString() ?? '',
      placedAt: DateTime.tryParse(json['placedAt']?.toString() ?? '') ??
          DateTime.now(),
      customerName: json['customerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      items: (json['items'] is List ? json['items'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map((l) => PlacedOrderLine(
                name: l['name']?.toString() ?? '',
                price: (l['price'] as num?)?.toDouble() ?? 0,
                weight: l['weight']?.toString() ?? '',
              ))
          .toList(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  CartProvider() {
    _loadOrders();
  }

  static const _ordersKey = 'kf_orders';

  final List<SeaProduct> _cartItems = [];
  final List<SeaProduct> _wishlistItems = [];
  final List<PlacedOrder> _orders = [];

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_ordersKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _orders
        ..clear()
        ..addAll(list.whereType<Map<String, dynamic>>().map(PlacedOrder.fromJson));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _ordersKey, jsonEncode(_orders.map((o) => o.toJson()).toList()));
    } catch (_) {}
  }

  List<SeaProduct> get cartItems => List.unmodifiable(_cartItems);
  List<SeaProduct> get wishlistItems => List.unmodifiable(_wishlistItems);
  List<PlacedOrder> get orders => List.unmodifiable(_orders);
  int get cartCount => _cartItems.length;
  int get wishlistCount => _wishlistItems.length;
  int get orderCount => _orders.length;

  PlacedOrder recordOrder({
    required double total,
    required String payment,
    int? serverId,
    String orderKey = '',
    String status = 'processing',
    bool synced = false,
    String customerName = '',
    String phone = '',
    String address = '',
    List<PlacedOrderLine> items = const [],
  }) {
    final order = PlacedOrder(
      id: 'KF${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      serverId: serverId,
      orderKey: orderKey,
      status: status,
      synced: synced,
      total: total,
      payment: payment,
      placedAt: DateTime.now(),
      customerName: customerName,
      phone: phone,
      address: address,
      items: items,
    );
    _orders.insert(0, order);
    _saveOrders();
    notifyListeners();
    return order;
  }

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
