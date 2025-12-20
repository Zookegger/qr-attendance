import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _kBaseUrlKey = 'base_api_url';

  String _baseUrl = '';

  String get baseUrl => _baseUrl;
  bool get hasBaseUrl => _baseUrl.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString((_kBaseUrlKey)) ?? '';
  }

  Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrlKey, cleanUrl);
    _baseUrl = cleanUrl;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrlKey);
    _baseUrl = '';
  }
}
