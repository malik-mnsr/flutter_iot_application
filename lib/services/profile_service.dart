import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../model/user_profile.dart';
import '../services/history_service.dart';

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
    await historyService.initialize(); // Assurez-vous que l'historique est chargé
    final history = historyService.getHistory();

    // Compter les opérations de cet utilisateur
    final userOperations = history
        .where((item) => item.userId == user.userID)
        .length;

    // Récupérer ou créer les métadonnées
    final lastLoginStr = prefs.getString('${_lastLoginKey}_${user.userID}');
    final totalOps = prefs.getInt('${_totalOpsKey}_${user.userID}') ?? 0;
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
    await prefs.setString(
      '${_lastLoginKey}_${user.userID}',
      DateTime.now().toIso8601String(),
    );

    // Mettre à jour le total des opérations
    await prefs.setInt(
      '${_totalOpsKey}_${user.userID}',
      userOperations + totalOps,
    );

    return UserProfile(
      userId: user.userID,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      profilePictureUrl: user.profilePictureURL,
      lastLogin: lastLogin ?? DateTime.now(),
      totalOperations: userOperations + totalOps,
      accountCreated: accountCreated,
    );
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
    await historyService.initialize();
    final history = historyService.getHistory();
    return history
        .where((item) => item.userId == user.userID)
        .length;
  }

  Future<DateTime?> getLastLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString('${_lastLoginKey}_${user.userID}');
    if (lastLoginStr != null) {
      return DateTime.tryParse(lastLoginStr);
    }
    return null;
  }
}