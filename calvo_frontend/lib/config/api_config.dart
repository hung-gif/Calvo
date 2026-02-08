// lib/config/api_config.dart
// Purpose: Centralized API configuration for dev/production environments

enum Environment { development, production }

class ApiConfig {
  static const Environment currentEnvironment = Environment.development;

  // Base URLs for different environments
  static const Map<Environment, String> baseUrls = {
    Environment.development: "http://10.0.2.2:8000",  // Android Emulator pointing to host machine
    Environment.production: "https://calvo-api.example.com",  // Replace with real domain
  };

  // API endpoints
  static const String webhookPath = "/gatekeeper/webhook";

  /// Get the current base URL based on environment
  static String getBaseUrl() {
    return baseUrls[currentEnvironment] ?? baseUrls[Environment.development]!;
  }

  /// Get the webhook endpoint URL
  static String getWebhookUrl() {
    return "${getBaseUrl()}$webhookPath";
  }

  /// Get all available endpoints
  static class Endpoints {
    static String get webhook => ApiConfig.getWebhookUrl();
    static String get health => "${getBaseUrl()}/";
  }
}
