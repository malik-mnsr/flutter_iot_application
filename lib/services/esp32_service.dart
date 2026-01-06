import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorData {
  final double temperature;
  final double humidity;
  final int light;
  final int timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      light: (json['light'] ?? 0).toInt(),
      timestamp: (json['timestamp'] ?? 0).toInt(),
    );
  }

  double get lightPercent => (light / 4095.0) * 100.0;
}

class DeviceStatus {
  final bool ledOn;
  final bool autoMode;
  final SensorData sensorData;
  final ThresholdSettings thresholds;

  DeviceStatus({
    required this.ledOn,
    required this.autoMode,
    required this.sensorData,
    required this.thresholds,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      ledOn: json['led'] == 'ON',
      autoMode: json['mode'] == 'AUTO',
      sensorData: SensorData.fromJson(json),
      thresholds: ThresholdSettings.fromJson(json['thresholds'] ?? {}),
    );
  }
}

class ThresholdSettings {
  final double tempThreshold;
  final bool tempEnabled;
  final int lightThreshold;
  final bool lightEnabled;

  ThresholdSettings({
    required this.tempThreshold,
    required this.tempEnabled,
    required this.lightThreshold,
    required this.lightEnabled,
  });

  factory ThresholdSettings.fromJson(Map<String, dynamic> json) {
    return ThresholdSettings(
      tempThreshold: (json['temp'] ?? 25.0).toDouble(),
      tempEnabled: json['temp_enabled'] ?? false,
      lightThreshold: (json['light'] ?? 500).toInt(),
      lightEnabled: json['light_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp': tempThreshold,
      'temp_enabled': tempEnabled,
      'light': lightThreshold,
      'light_enabled': lightEnabled,
    };
  }
}

class ESP32Service {
  static String baseUrl = "http://192.168.1.100";

  static void setIPAddress(String ip) {
    baseUrl = "http://$ip";
  }

  // ==================== LED Control ====================

  static Future<Map<String, dynamic>?> turnOn() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/on'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error turning on LED: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> turnOff() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/off'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error turning off LED: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> toggle() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/toggle'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error toggling LED: $e');
      return null;
    }
  }

  // ==================== Auto Mode ====================

  static Future<Map<String, dynamic>?> enableAutoMode() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auto/on'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error enabling auto mode: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> disableAutoMode() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auto/off'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error disabling auto mode: $e');
      return null;
    }
  }

  // ==================== Sensor Data ====================

  static Future<SensorData?> getSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sensors'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SensorData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting sensor data: $e');
      return null;
    }
  }

  // ==================== Status ====================

  static Future<DeviceStatus?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting status: $e');
      return null;
    }
  }

  // ==================== Thresholds ====================

  static Future<Map<String, dynamic>?> setTemperatureThreshold({
    required double value,
    required bool enabled,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/threshold/temp?value=$value&enabled=$enabled'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error setting temperature threshold: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> setLightThreshold({
    required int value,
    required bool enabled,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/threshold/light?value=$value&enabled=$enabled'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error setting light threshold: $e');
      return null;
    }
  }

  // ==================== Connection ====================

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}