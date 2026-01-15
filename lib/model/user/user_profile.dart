import 'user.dart';
class UserProfile {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final DateTime? lastLogin;
  final int totalOperations;
  final DateTime accountCreated;

  UserProfile({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    this.lastLogin,
    this.totalOperations = 0,
    required this.accountCreated,
  });

  factory UserProfile.fromUser(User user, {int totalOps = 0}) {
    return UserProfile(
      userId: user.userID,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      profilePictureUrl: user.profilePictureURL,
      lastLogin: DateTime.now(),
      totalOperations: totalOps,
      accountCreated: DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName';

  String get formattedAccountDate {
    return '${accountCreated.day}/${accountCreated.month}/${accountCreated.year}';
  }

  String get formattedLastLogin {
    if (lastLogin == null) return 'Jamais';
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else {
      return 'À l\'instant';
    }
  }
}