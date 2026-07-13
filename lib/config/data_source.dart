/// Defines the current data source for the app.
///
/// Switch to [DataSource.api] when your WooCommerce store is ready.
/// While in [DataSource.static] mode, the app uses bundled dummy data.
enum DataSource {
  static,
  api,
}

/// Central runtime configuration.
///
/// Toggle [current] between [DataSource.static] and [DataSource.api]
/// to switch from static dummy data to live WooCommerce API calls.
class RuntimeConfig {
  /// Change this to [DataSource.api] to enable WooCommerce API integration.
  static DataSource current = DataSource.static;

  /// Whether the app should fetch data from the WooCommerce API.
  static bool get useApi => current == DataSource.api;
}
