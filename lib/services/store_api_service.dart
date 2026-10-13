import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/sea_product.dart';

/// One page of products returned by the WooCommerce Store API.
class StorePage {
  final List<SeaProduct> items;
  final int total;
  final int totalPages;

  const StorePage({
    required this.items,
    required this.total,
    required this.totalPages,
  });
}

/// Read-only WooCommerce Store API client (no consumer key required).
///
/// Used to load the full live catalogue from kolkatafish.com with
/// server-side pagination, falling back to bundled static data in the UI
/// when the network is unavailable.
class StoreApiService {
  static const String _base = 'https://kolkatafish.com/wp-json/wc/store/v1';

  /// Display name -> WooCommerce category slug.
  static const Map<String, String> categorySlugs = {
    'Fresh Water Fish': 'onlinefish',
    'Prawns & Seafood': 'seafood',
    'Meat Mania': 'onlinemeat',
    'Fresh & Frozen': 'frozen',
  };

  final http.Client _client;

  StoreApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch one page of the whole catalogue, optionally filtered by [search].
  Future<StorePage> fetchProducts({
    int page = 1,
    int perPage = 12,
    String? search,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.trim().isNotEmpty)
        'search': search.trim(),
    };

    return _fetchPage(query, categoryName: '');
  }

  /// Fetch one page of products belonging to [categoryName].
  Future<StorePage> fetchCategoryProducts({
    required String categoryName,
    int page = 1,
    int perPage = 12,
  }) async {
    final slug = categorySlugs[categoryName];
    if (slug == null) {
      return const StorePage(items: [], total: 0, totalPages: 0);
    }

    return _fetchPage(
      {
        'category': slug,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      categoryName: categoryName,
    );
  }

  Future<StorePage> _fetchPage(
    Map<String, String> query, {
    required String categoryName,
  }) async {
    final uri = Uri.parse('$_base/products').replace(queryParameters: query);

    final res = await _client
        .get(uri, headers: {'User-Agent': 'KolkataFish/1.0'})
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw StoreApiException('Failed to load products (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : const [];

    final items = list
        .whereType<Map<String, dynamic>>()
        .map((json) => _mapProduct(json, categoryName))
        .toList();

    final total = int.tryParse(res.headers['x-wp-total'] ?? '') ?? items.length;
    final totalPages =
        int.tryParse(res.headers['x-wp-totalpages'] ?? '') ?? 1;

    return StorePage(items: items, total: total, totalPages: totalPages);
  }

  SeaProduct _mapProduct(Map<String, dynamic> json, String category) {
    final prices = json['prices'] is Map<String, dynamic>
        ? json['prices'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final minorUnit = (prices['currency_minor_unit'] as num?)?.toInt() ?? 0;
    final price = _toRupees(prices['price'], minorUnit);
    final regular = _toRupees(prices['regular_price'], minorUnit);
    final sale = _toRupees(prices['sale_price'], minorUnit);

    final images = json['images'] is List ? json['images'] as List : const [];
    final imageUrl = images.isNotEmpty && images.first is Map
        ? (images.first['src'] as String? ?? '')
        : '';

    final htmlPrice = _stripHtml(json['price_html']?.toString() ?? '');

    return SeaProduct(
      id: json['id'].toString(),
      name: _decodeEntities(json['name']?.toString() ?? ''),
      description: _stripHtml(json['description']?.toString() ??
          json['short_description']?.toString() ??
          ''),
      category: category,
      price: price,
      priceUnit: _unitFrom(htmlPrice),
      weight: _weight(json),
      imageUrl: imageUrl,
      inStock: json['is_in_stock'] == true,
      isFeatured: json['featured'] == true,
      isNew: false,
      isSale: (json['on_sale'] == true) || (sale > 0 && sale < regular),
      rating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
    );
  }

  double _toRupees(dynamic value, int minorUnit) {
    final raw = double.tryParse(value?.toString() ?? '') ?? 0;
    if (minorUnit <= 0) return raw;
    return raw / math.pow(10, minorUnit).toDouble();
  }

  String _unitFrom(String plainPriceHtml) {
    final idx = plainPriceHtml.lastIndexOf('/');
    if (idx >= 0) {
      final unit = plainPriceHtml.substring(idx + 1).trim();
      if (unit.isNotEmpty && unit.length <= 20) return unit;
    }
    return 'kg';
  }

  String _weight(Map<String, dynamic> json) {
    final formatted = json['formatted_weight']?.toString() ?? '';
    if (formatted.isNotEmpty && formatted != 'N/A') return formatted;

    final weight = json['weight']?.toString() ?? '';
    if (weight.isNotEmpty) return weight;

    final match = RegExp(r'\(([^)]*kg[^)]*)\)', caseSensitive: false)
        .firstMatch(json['name']?.toString() ?? '');
    if (match != null) return match.group(1)!.trim();
    return '';
  }

  static final RegExp _tag = RegExp(r'<[^>]*>');
  static final RegExp _space = RegExp(r'\s+');

  String _stripHtml(String input) {
    final withoutTags = input.replaceAll(_tag, ' ');
    return _decodeEntities(withoutTags).replaceAll(_space, ' ').trim();
  }

  String _decodeEntities(String input) {
    var out = input;
    const named = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#039;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&rsquo;': '\u2019',
      '&lsquo;': '\u2018',
      '&rdquo;': '\u201d',
      '&ldquo;': '\u201c',
      '&ndash;': '\u2013',
      '&mdash;': '\u2014',
      '&hellip;': '\u2026',
      '&#8211;': '\u2013',
      '&#8212;': '\u2014',
      '&#8217;': '\u2019',
      '&#8220;': '\u201c',
      '&#8221;': '\u201d',
      '&#8230;': '\u2026',
      '&#8377;': '\u20b9',
    };
    named.forEach((key, value) => out = out.replaceAll(key, value));

    return out.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) {
        final code = int.tryParse(m.group(1) ?? '');
        return code != null && code > 0 && code < 0x10FFFF
            ? String.fromCharCode(code)
            : m.group(0)!;
      },
    );
  }

  void dispose() => _client.close();

  Map<String, String> get _headers => {'User-Agent': 'KolkataFish/1.0'};

  /// Start a Store API cart session (returns Cart-Token + Nonce headers).
  Future<StoreCartSession> createCart() async {
    final res = await _client
        .get(Uri.parse('$_base/cart'), headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw StoreApiException('Could not start cart session (${res.statusCode})');
    }

    final token = res.headers['cart-token'] ?? '';
    final nonce = res.headers['nonce'] ?? '';
    if (token.isEmpty || nonce.isEmpty) {
      throw StoreApiException('Store did not return a cart session');
    }
    return StoreCartSession(token: token, nonce: nonce);
  }

  /// Add a WooCommerce product (by numeric id) to the cart session.
  Future<void> addToCart(
    StoreCartSession session,
    int productId, {
    int quantity = 1,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$_base/cart/add-item'),
          headers: {
            ..._headers,
            'Nonce': session.nonce,
            'Cart-Token': session.token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id': productId, 'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw StoreApiException(
          'Could not add item to cart (${res.statusCode})');
    }
  }

  /// Place the order on the WooCommerce store (currently COD only).
  Future<StoreCheckoutResult> checkout({
    required StoreCartSession session,
    required String firstName,
    required String lastName,
    required String address1,
    required String city,
    required String state,
    required String postcode,
    required String country,
    required String email,
    required String phone,
    String paymentMethod = 'cod',
    String customerNote = '',
  }) async {
    final address = {
      'first_name': firstName,
      'last_name': lastName,
      'company': '',
      'address_1': address1,
      'address_2': '',
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'phone': phone,
      if (paymentMethod == 'cod') 'email': email,
    };

    final payload = {
      'billing_address': address,
      'shipping_address': {...address}..remove('email'),
      'payment_method': paymentMethod,
      if (customerNote.trim().isNotEmpty) 'customer_note': customerNote.trim(),
    };

    final res = await _client
        .post(
          Uri.parse('$_base/checkout'),
          headers: {
            ..._headers,
            'Nonce': session.nonce,
            'Cart-Token': session.token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode != 200) {
      String message = 'Checkout failed (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      throw StoreApiException(message);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final paymentResult =
        json['payment_result'] is Map<String, dynamic>
            ? json['payment_result'] as Map<String, dynamic>
            : const <String, dynamic>{};

    return StoreCheckoutResult(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderKey: json['order_key']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      redirectUrl: paymentResult['redirect_url']?.toString() ?? '',
    );
  }
}

/// Session credentials for the WooCommerce Store API cart.
class StoreCartSession {
  final String token;
  final String nonce;

  const StoreCartSession({required this.token, required this.nonce});
}

/// Result of a successful Store API checkout.
class StoreCheckoutResult {
  final int orderId;
  final String orderKey;
  final String status;
  final String redirectUrl;

  const StoreCheckoutResult({
    required this.orderId,
    required this.orderKey,
    required this.status,
    required this.redirectUrl,
  });
}

class StoreApiException implements Exception {
  final String message;
  const StoreApiException(this.message);

  @override
  String toString() => 'StoreApiException: $message';
}
