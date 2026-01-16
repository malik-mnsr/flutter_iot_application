class SensorDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final int light;
  final bool ledState;

  SensorDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.ledState,
  });

  double get lightPercent => (light / 4095.0) * 100.0;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'lightPercent': lightPercent,
      'ledState': ledState,
    };
  }

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      light: (json['light'] ?? 0).toInt(),
      ledState: json['ledState'] ?? false,
    );
  }
}

class SensorDataHistory {
  final List<SensorDataPoint> dataPoints;
  final int maxPoints;

  SensorDataHistory({
    List<SensorDataPoint>? dataPoints,
    this.maxPoints = 50,
  }) : dataPoints = dataPoints ?? [];

  void addDataPoint(SensorDataPoint point) {
    dataPoints.insert(0, point);
    if (dataPoints.length > maxPoints) {
      dataPoints.removeLast();
    }
  }

  List<SensorDataPoint> getLastPoints(int count) {
    return dataPoints.take(count).toList();
  }

  SensorDataPoint? get latest => dataPoints.isEmpty ? null : dataPoints.first;

  double get averageTemperature {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.temperature).reduce((a, b) => a + b) / dataPoints.length;
  }

  double get averageLight {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.lightPercent).reduce((a, b) => a + b) / dataPoints.length;
  }

  double get maxTemperature {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
  }

  double get minTemperature {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
  }

  void clear() {
    dataPoints.clear();
  }
}