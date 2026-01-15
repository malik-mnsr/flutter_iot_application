// services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/history/history.dart';
import '../../model/user/user.dart';




class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _collectionKey = 'operation_history';
  List<OperationHistory> _history = [];
  String? _currentUserId;

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _loadHistory(userId);
  }

  Future<void> _loadHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionKey)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      _history = snapshot.docs
          .map((doc) => OperationHistory.fromJson(doc.data()))
          .toList();
      print('✅ Historique chargé:  ${_history.length} opérations');
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      _history = [];
    }
  }

  Future<void> addOperation({
    required String operation,
    required String details,
    User? user,
  }) async {
    if (user == null) {
      print('⚠️ Utilisateur null, opération non enregistrée');
      return;
    }

    final history = OperationHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      details: details,
      timestamp: DateTime.now(),
      userId: user.userID,
    );

    try {
      await FirebaseFirestore.instance
          .collection(_collectionKey)
          .doc(history.id)
          .set(history.toJson());

      // Recharge l'historique local
      _history.insert(0, history);

      // Limite à 100 opérations locales
      if (_history.length > 100) {
        _history = _history.sublist(0, 100);
      }

      print('✅ Opération enregistrée: $operation');
    } catch (e) {
      print('❌ Erreur sauvegarde opération: $e');
    }
  }

  List<OperationHistory> getHistory() {
    return List.from(_history);
  }

  Future<void> clearHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionKey)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _history.clear();
      print('✅ Historique effacé');
    } catch (e) {
      print('❌ Erreur suppression historique: $e');
    }
  }

  List<OperationHistory> getHistoryByOperation(String operation) {
    return _history
        .where((item) =>
        item.operation.toLowerCase().contains(operation.toLowerCase()))
        .toList();
  }

  // Nouveau:  récupérer l'historique d'un utilisateur spécifique
  Future<List<OperationHistory>> getUserHistoryFromFirebase(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionKey)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => OperationHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération historique utilisateur:  $e');
      return [];
    }
  }
}