import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Low-level HTTP client for WooCommerce REST API.
///
/// Handles authentication via OAuth 1.0a (WooCommerce default)
/// and provides GET / POST helpers.
class ApiClient {
  final http.Client _client;
  final String _baseUrl;
  final String _consumerKey;
  final String _consumerSecret;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.baseUrl,
        _consumerKey = consumerKey ?? AppConfig.consumerKey,
        _consumerSecret = consumerSecret ?? AppConfig.consumerSecret;

  /// Perform a GET request to [endpoint] with optional [params].
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.apiPrefix}$endpoint')
        .replace(queryParameters: _buildAuthParams(params));

    return _client
        .get(uri, headers: {'User-Agent': 'KolkataFish/1.0'})
        .timeout(Duration(seconds: AppConfig.timeoutSeconds));
  }

  /// Perform a POST request to [endpoint] with optional [body].
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl${AppConfig.apiPrefix}$endpoint')
        .replace(queryParameters: _buildAuthParams());

    return _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'KolkataFish/1.0',
          },
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(Duration(seconds: AppConfig.timeoutSeconds));
  }

  /// Build query parameters with OAuth 1.0a signature.
  Map<String, String> _buildAuthParams([Map<String, String>? extra]) {
    final params = <String, String>{
      'consumer_key': _consumerKey,
      'consumer_secret': _consumerSecret,
      if (extra != null) ...extra,
    };

    // In production, implement full OAuth 1.0a signature.
    // For now, use query-string auth (simpler, but less secure).
    return params;
  }

  void dispose() {
    _client.close();
  }
}
