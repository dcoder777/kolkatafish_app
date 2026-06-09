/// Configuration for WooCommerce REST API connection.
///
/// Update these values with your WooCommerce store details
/// before switching [DataSource] to [DataSource.api].
class AppConfig {
  AppConfig._();

  /// WooCommerce store base URL (e.g., https://yourstore.com)
  static const String baseUrl = 'https://yourstore.com';

  /// WooCommerce REST API consumer key
  static const String consumerKey = 'ck_your_consumer_key';

  /// WooCommerce REST API consumer secret
  static const String consumerSecret = 'cs_your_consumer_secret';

  /// API version prefix
  static const String apiPrefix = '/wp-json/wc/v3';

  /// Request timeout in seconds
  static const int timeoutSeconds = 30;

  /// Pagination: items per page
  static const int pageSize = 20;
}
