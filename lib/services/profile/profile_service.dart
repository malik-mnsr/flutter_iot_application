// services/profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/user/user.dart';
import '../../model/user/user_profile.dart';
import '../history/history_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _lastLoginKey = 'last_login';
  static const String _totalOpsKey = 'total_operations';
  static const String _accountCreatedKey = 'account_created';

  Future<UserProfile> getUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final historyService = HistoryService();

    try {
      await historyService.initialize(user. userID);
      final userHistory = await historyService.getUserHistoryFromFirebase(user. userID);

      final userOperations = userHistory.length;

      // Récupérer ou créer les métadonnées
      final lastLoginStr = prefs.getString('${_lastLoginKey}_${user.userID}');
      final accountCreatedStr = prefs.getString('${_accountCreatedKey}_${user.userID}');

      DateTime? lastLogin;
      if (lastLoginStr != null) {
        lastLogin = DateTime.tryParse(lastLoginStr);
      }

      DateTime accountCreated;
      if (accountCreatedStr != null) {
        accountCreated = DateTime.parse(accountCreatedStr);
      } else {
        accountCreated = DateTime.now();
        // Si premier login, enregistrer la date de création
        await prefs.setString(
          '${_accountCreatedKey}_${user.userID}',
          accountCreated.toIso8601String(),
        );
      }

      // Mettre à jour le dernier login
      await prefs. setString(
        '${_lastLoginKey}_${user.userID}',
        DateTime.now().toIso8601String(),
      );

      return UserProfile(
        userId: user.userID,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        profilePictureUrl: user.profilePictureURL,
        lastLogin: lastLogin ??  DateTime.now(),
        totalOperations: userOperations,
        accountCreated: accountCreated,
      );
    } catch (e) {
      print('❌ Erreur getUserProfile: $e');
      return UserProfile(
        userId: user.userID,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        totalOperations: 0,
        accountCreated: DateTime.now(),
      );
    }
  }

  Future<void> updateLastActivity(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_lastLoginKey}_${user.userID}',
      DateTime.now().toIso8601String(),
    );
  }

  Future<int> getUserTotalOperations(User user) async {
    final historyService = HistoryService();
    final history = await historyService.getUserHistoryFromFirebase(user.userID);
    return history.length;
  }

  Future<DateTime? > getLastLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString('${_lastLoginKey}_${user.userID}');
    if (lastLoginStr != null) {
      return DateTime.tryParse(lastLoginStr);
    }
    return null;
  }
}