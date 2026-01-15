// services/history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/history/history.dart';
import '../../model/user/user.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _storageKey = 'operation_history';
  List<OperationHistory> _history = [];

  Future<void> initialize() async {
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _history = historyList
            .map((item) => OperationHistory.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Erreur chargement historique: $e');
      _history = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, historyJson);
    } catch (e) {
      print('Erreur sauvegarde historique: $e');
    }
  }

  Future<void> addOperation({
    required String operation,
    required String details,
    User? user,
  }) async {
    final history = OperationHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      details: details,
      timestamp: DateTime.now(),
      userId: user?.userID,
    );

    _history.insert(0, history);

    // Garder seulement les 100 dernières opérations
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }

    await _saveHistory();
  }

  List<OperationHistory> getHistory() {
    return List.from(_history);
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  List<OperationHistory> getHistoryByOperation(String operation) {
    return _history
        .where((item) => item.operation.toLowerCase().contains(operation.toLowerCase()))
        .toList();
  }
}