// models/history.dart
class OperationHistory {
  final String id;
  final String operation;
  final String details;
  final DateTime timestamp;
  final String? userId;

  OperationHistory({
    required this.id,
    required this.operation,
    required this.details,
    required this.timestamp,
    this.userId,
  });

  factory OperationHistory.fromJson(Map<String, dynamic> json) {
    return OperationHistory(
      id: json['id'] ?? '',
      operation: json['operation'] ?? '',
      details: json['details'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}