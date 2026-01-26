enum Environment { development, production }

class ApiConfig {
  static const Environment currentEnvironment = Environment.development;

  // Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.development: "http://10.0.2.2:8000",
    Environment.production: "https://calvo-api.example.com",
  };

  /// Lấy Base URL hiện tại
  static String get baseUrl => _baseUrls[currentEnvironment] ?? _baseUrls[Environment.development]!;

  // API paths
  static const String _webhookPath = "/gatekeeper/webhook";
  static const String _healthPath = "/";

  /// Đối tượng chứa các Endpoints để truy cập theo dạng ApiConfig.endpoints.xxx
  static const _Endpoints endpoints = _Endpoints();
}

/// Class nội bộ để quản lý các Endpoint
class _Endpoints {
  const _Endpoints();

  String get webhook => "${ApiConfig.baseUrl}${ApiConfig._webhookPath}";
  String get health => "${ApiConfig.baseUrl}${ApiConfig._healthPath}";
  
  // Bạn có thể thêm các route khác của Calvo Backend vào đây
  // String get login => "${ApiConfig.baseUrl}/auth/login";
}
