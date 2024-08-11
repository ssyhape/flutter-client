import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ServiceConfig {
  final String apiUrl;
  final int port;

  ServiceConfig({required this.apiUrl, required this.port});

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      apiUrl: json['apiUrl'],
      port: json['port'],
    );
  }
}

class Config {
  final Map<String, ServiceConfig> services;

  Config({required this.services});

  factory Config.fromJson(Map<String, dynamic> json) {
    Map<String, ServiceConfig> services = {};
    json['services'].forEach((key, value) {
      services[key] = ServiceConfig.fromJson(value);
    });
    return Config(services: services);
  }
}

class ConfigService {
  static Future<Config> loadConfig() async {
    final jsonString = await rootBundle.loadString('assets/config.json');
    final jsonMap = json.decode(jsonString);
    return Config.fromJson(jsonMap);
  }
}
