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
    final rawDesc = json['description']?.toString() ?? '';
    final rawShortDesc = json['short_description']?.toString() ?? '';
    final fullHtmlText = '$rawShortDesc $rawDesc';
    final name = _decodeEntities(json['name']?.toString() ?? '');
    final fallbackWeight = _weight(json);

    final grossWeight = _extractGrossWeight(fullHtmlText, name, fallbackWeight);
    final netWeight = _extractNetWeight(fullHtmlText);
    final pieces = _extractPieces(fullHtmlText);
    final size = _extractSize(fullHtmlText);

    return SeaProduct(
      id: json['id'].toString(),
      name: name,
      description: _stripHtml(rawDesc.isNotEmpty ? rawDesc : rawShortDesc),
      shortDescription: _stripHtml(rawShortDesc),
      category: category,
      price: price,
      priceUnit: _unitFrom(htmlPrice),
      weight: fallbackWeight.isNotEmpty ? fallbackWeight : (grossWeight.isNotEmpty ? grossWeight : '500 gm'),
      grossWeight: grossWeight,
      netWeight: netWeight,
      pieces: pieces,
      size: size,
      imageUrl: imageUrl,
      inStock: json['is_in_stock'] == true,
      isFeatured: json['featured'] == true,
      isNew: false,
      isSale: (json['on_sale'] == true) || (sale > 0 && sale < regular),
      rating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
    );
  }

  String _extractGrossWeight(String text, String name, String fallbackWeight) {
    final m1 = RegExp(r'(?:Gross\s*Weight|Gross\s*Wt|Size\s*of\s*the\s*fish)\s*[:\u2013-]\s*([^<\n\r]+)', caseSensitive: false).firstMatch(text);
    if (m1 != null) {
      final val = _stripHtml(m1.group(1)!).trim();
      if (val.isNotEmpty && val.length < 40) return val;
    }
    final m2 = RegExp(r'\(([^)]*(?:kg|gm|gms|g)[^)]*)\)', caseSensitive: false).firstMatch(name);
    if (m2 != null) {
      final val = m2.group(1)!.trim();
      if (val.isNotEmpty && val.length < 40) return val;
    }
    return fallbackWeight;
  }

  String _extractNetWeight(String text) {
    final m = RegExp(r'(?:After\s*Cut|Net\s*Weight|Net\s*Wt)\s*[:\u2013-]\s*([^<\n\r]+)', caseSensitive: false).firstMatch(text);
    if (m != null) {
      final val = _stripHtml(m.group(1)!).trim();
      if (val.isNotEmpty && val.length < 40) return val;
    }
    return '';
  }

  String _extractPieces(String text) {
    final m = RegExp(r'(?:No\.?\s*of\s*(?:Pieces|Fish|Pcs))\s*[:\u2013-]\s*([^<\n\r]+)', caseSensitive: false).firstMatch(text);
    if (m != null) {
      final val = _stripHtml(m.group(1)!).trim();
      if (val.isNotEmpty && val.length < 50) return val;
    }
    return '';
  }

  String _extractSize(String text) {
    final m = RegExp(r'(?:Size\s*of\s*the\s*Fish)\s*[:\u2013-]\s*([^<\n\r]+)', caseSensitive: false).firstMatch(text);
    if (m != null) {
      final val = _stripHtml(m.group(1)!).trim();
      if (val.isNotEmpty && val.length < 40) return val;
    }
    return '';
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
      throw const StoreApiException('Store did not return a cart session');
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

  /// Place the order on the WooCommerce store.
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
    String deliveryDate = '',
    String deliverySlot = '',
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
      'email': email,
    };

    final payload = <String, dynamic>{
      'billing_address': address,
      'shipping_address': {...address}..remove('email'),
      'payment_method': paymentMethod,
      if (customerNote.trim().isNotEmpty) 'customer_note': customerNote.trim(),
      if (deliveryDate.isNotEmpty) ...{
        'add_delivery_date': deliveryDate,
        'delivery_date': deliveryDate,
      },
      if (deliverySlot.isNotEmpty) ...{
        'add_delivery_time': deliverySlot,
        'delivery_time': deliverySlot,
        'delivery_slot': deliverySlot,
      },
      if (deliveryDate.isNotEmpty || deliverySlot.isNotEmpty)
        'additional_fields': {
          if (deliveryDate.isNotEmpty) 'add_delivery_date': deliveryDate,
          if (deliverySlot.isNotEmpty) 'add_delivery_time': deliverySlot,
        },
      if (deliveryDate.isNotEmpty || deliverySlot.isNotEmpty)
        'extensions': {
          'kolkatafish_shop_customizer': {
            if (deliveryDate.isNotEmpty) 'add_delivery_date': deliveryDate,
            if (deliverySlot.isNotEmpty) 'add_delivery_time': deliverySlot,
          },
          'kolkatafish-sc': {
            if (deliveryDate.isNotEmpty) 'add_delivery_date': deliveryDate,
            if (deliverySlot.isNotEmpty) 'add_delivery_time': deliverySlot,
          },
        },
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

  /// Update the cart's customer address and return the server-computed
  /// totals for that destination (items + fees + shipping).
  ///
  /// This is the source of truth for what the customer will actually be
  /// charged — the app never invents its own delivery fee.
  Future<StoreCartTotals> updateCustomer(
    StoreCartSession session, {
    required String firstName,
    required String lastName,
    required String address1,
    required String city,
    required String state,
    required String postcode,
    required String country,
    required String email,
    required String phone,
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
      'email': email,
    };

    final res = await _client
        .post(
          Uri.parse('$_base/cart/update-customer'),
          headers: {
            ..._headers,
            'Nonce': session.nonce,
            'Cart-Token': session.token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'billing_address': address,
            'shipping_address': {...address}..remove('email'),
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw StoreApiException(
          'Could not calculate delivery for this address (${res.statusCode})');
    }

    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) {
      throw const StoreApiException('Unexpected response while calculating delivery');
    }

    return _parseCartTotals(json);
  }

  /// Apply a coupon code to the current cart session.
  Future<StoreCartTotals> applyCoupon(
    StoreCartSession session,
    String code,
  ) async {
    final clean = code.trim().toLowerCase();
    if (clean.isEmpty) {
      throw const StoreApiException('Please enter a coupon code.');
    }

    final res = await _client
        .post(
          Uri.parse('$_base/cart/apply-coupon'),
          headers: {
            ..._headers,
            'Nonce': session.nonce,
            'Cart-Token': session.token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'code': clean}),
        )
        .timeout(const Duration(seconds: 25));

    final json = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Failed to apply coupon.';
      if (json is Map && json['message'] != null) {
        msg = _stripHtml(json['message'].toString());
      }
      throw StoreApiException(msg);
    }

    if (json is! Map<String, dynamic>) {
      throw const StoreApiException('Unexpected response from coupon endpoint');
    }

    return _parseCartTotals(json);
  }

  /// Remove an applied coupon from the cart session.
  Future<StoreCartTotals> removeCoupon(
    StoreCartSession session,
    String code,
  ) async {
    final clean = code.trim().toLowerCase();
    final res = await _client
        .post(
          Uri.parse('$_base/cart/remove-coupon'),
          headers: {
            ..._headers,
            'Nonce': session.nonce,
            'Cart-Token': session.token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'code': clean}),
        )
        .timeout(const Duration(seconds: 25));

    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      String msg = 'Failed to remove coupon.';
      if (json is Map && json['message'] != null) {
        msg = _stripHtml(json['message'].toString());
      }
      throw StoreApiException(msg);
    }

    if (json is! Map<String, dynamic>) {
      throw const StoreApiException('Unexpected response from coupon endpoint');
    }

    return _parseCartTotals(json);
  }

  /// Fetch available coupons from the store (Smart Coupons & public codes).
  Future<List<StoreCoupon>> fetchAvailableCoupons([StoreCartSession? session]) async {
    final Map<String, StoreCoupon> couponMap = {};

    // Standard known active promotions on KolkataFish
    final defaultCoupons = [
      const StoreCoupon(
        code: 'special10',
        description: 'Get Flat 2% off on orders of ₹999 & above',
        discountAmount: 2.0,
      ),
      const StoreCoupon(
        code: 'fbkfcs05',
        description: 'Get Flat 5% off on orders of ₹1499 & above',
        discountAmount: 5.0,
      ),
      const StoreCoupon(
        code: 'fbkfcs10',
        description: 'Get Flat 10% off on orders of ₹2199 & above',
        discountAmount: 10.0,
      ),
    ];
    for (final c in defaultCoupons) {
      couponMap[c.code.toLowerCase()] = c;
    }

    // Attempt to read live coupons published in wt_sc_blocks extension
    try {
      final res = await _client
          .get(
            Uri.parse('$_base/cart'),
            headers: {
              ..._headers,
              if (session != null) ...{
                'Nonce': session.nonce,
                'Cart-Token': session.token,
              },
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final extensions = data['extensions'];
          if (extensions is Map) {
            final wt = extensions['wt_sc_blocks'];
            if (wt is Map) {
              final html = wt['coupon_blocks_checkout']?.toString() ?? '';
              final codeMatches = RegExp(r'''data-code=["']([^"']+)["']''').allMatches(html);
              for (final m in codeMatches) {
                final code = m.group(1)?.trim();
                if (code != null && code.isNotEmpty) {
                  final descPattern = 'data-code=["\']$code["\'].*?<div[^>]*style=["\'][^"\']*color:#005345[^"\']*["\'][^>]*>(.*?)</div>';
                  final descMatch = RegExp(descPattern, dotAll: true).firstMatch(html);
                  final desc = descMatch != null ? _stripHtml(descMatch.group(1)!) : 'Special store coupon';
                  couponMap[code.toLowerCase()] = StoreCoupon(
                    code: code,
                    description: desc,
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return couponMap.values.toList();
  }

  /// Fetch live available delivery slots for [date] (DD/MM/YYYY) and [pincode]
  /// directly from WooCommerce `kolkatafish_get_delivery_slots` Ajax handler.
  Future<List<String>> fetchDeliverySlots({
    required String date,
    String pincode = '700063',
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('https://kolkatafish.com/wp-admin/admin-ajax.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) KolkataFish/1.0',
        },
        body: {
          'action': 'kolkatafish_get_delivery_slots',
          'date': date,
          'pincode': pincode.trim().isEmpty ? '700063' : pincode.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == true && data['data'] is Map) {
          final slots = data['data']['slots'];
          if (slots is List) {
            final activeSlots = <String>[];
            for (final s in slots) {
              if (s is Map && s['disabled'] != true) {
                final val = s['value']?.toString() ?? s['label']?.toString() ?? '';
                if (val.isNotEmpty) activeSlots.add(val);
              }
            }
            if (activeSlots.isNotEmpty) return activeSlots;
          }
        }
      }
    } catch (_) {}

    return const [];
  }

  StoreCartTotals _parseCartTotals(Map<String, dynamic> json) {
    final totalsMap = json['totals'] is Map<String, dynamic>
        ? json['totals'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final minorUnit =
        (totalsMap['currency_minor_unit'] as num?)?.toInt() ?? 0;

    final fees = <StoreFee>[
      for (final f in (json['fees'] is List ? json['fees'] as List : const []))
        if (f is Map<String, dynamic>)
          StoreFee(
            name: f['name']?.toString() ?? 'Fee',
            amount: _toRupees(
                (f['totals'] is Map ? f['totals']['total'] : null), minorUnit),
          ),
    ];

    var shipping = _toRupees(totalsMap['total_shipping'], minorUnit);
    if (shipping <= 0) {
      final rates = json['shipping_rates'] is List
          ? json['shipping_rates'] as List
          : const [];
      for (final pkg in rates.whereType<Map<String, dynamic>>()) {
        final list = pkg['shipping_rates'] is List
            ? pkg['shipping_rates'] as List
            : const [];
        for (final r in list.whereType<Map<String, dynamic>>()) {
          if (r['selected'] == true) {
            shipping = _toRupees(r['price'], minorUnit);
          }
        }
      }
    }

    final discount = _toRupees(totalsMap['total_discount'], minorUnit);

    final appliedCoupons = <String>[
      for (final c in (json['coupons'] is List ? json['coupons'] as List : const []))
        if (c is Map && c['code'] != null) c['code'].toString(),
    ];

    return StoreCartTotals(
      totalItems: _toRupees(totalsMap['total_items'], minorUnit),
      fees: fees,
      shipping: shipping,
      discount: discount,
      totalPrice: _toRupees(totalsMap['total_price'], minorUnit),
      appliedCoupons: appliedCoupons,
    );
  }

  /// Fetch the live status of an order previously placed through the Store API.
  Future<StoreOrderStatus> fetchOrderStatus({
    required int orderId,
    required String orderKey,
    required String billingEmail,
  }) async {
    final uri = Uri.parse('$_base/order/$orderId').replace(
      queryParameters: {
        'key': orderKey,
        'billing_email': billingEmail,
      },
    );

    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw StoreApiException('Could not fetch order status (${res.statusCode})');
    }

    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) {
      throw const StoreApiException('Unexpected order status response');
    }

    return StoreOrderStatus(
      status: json['status']?.toString() ?? '',
      needsPayment: json['needs_payment'] == true,
    );
  }
}

/// Session credentials for the WooCommerce Store API cart.
class StoreCartSession {
  final String token;
  final String nonce;

  const StoreCartSession({required this.token, required this.nonce});
}

/// Server-computed money breakdown for a cart at a given address.
class StoreCartTotals {
  final double totalItems;
  final List<StoreFee> fees;
  final double shipping;
  final double discount;
  final double totalPrice;
  final List<String> appliedCoupons;

  const StoreCartTotals({
    required this.totalItems,
    required this.fees,
    required this.shipping,
    this.discount = 0.0,
    required this.totalPrice,
    this.appliedCoupons = const [],
  });
}

/// A discount coupon from WooCommerce.
class StoreCoupon {
  final String code;
  final String description;
  final double discountAmount;
  final bool isApplied;

  const StoreCoupon({
    required this.code,
    this.description = '',
    this.discountAmount = 0.0,
    this.isApplied = false,
  });
}

/// A named fee line (e.g. "Handling Charges") from the store.
class StoreFee {
  final String name;
  final double amount;

  const StoreFee({required this.name, required this.amount});
}

/// Live status of a placed order.
class StoreOrderStatus {
  final String status;
  final bool needsPayment;

  const StoreOrderStatus({required this.status, required this.needsPayment});

  bool get isPaid =>
      status == 'processing' || status == 'completed' || status == 'on-hold';
  bool get isFailed =>
      status == 'failed' || status == 'cancelled' || status == 'refunded';
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
