import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../model/user.dart';
import '../../model/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/history_service.dart';
import '../../model/history/history.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profileFuture;
  late Future<List<OperationHistory>> _recentActivitiesFuture;
  final ProfileService _profileService = ProfileService();
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _profileFuture = _profileService.getUserProfile(widget.user);
    _recentActivitiesFuture = _getRecentActivities();
  }

  Future<List<OperationHistory>> _getRecentActivities() async {
    await _historyService.initialize();
    final history = _historyService.getHistory();
    return history
        .where((item) => item.userId == widget.user.userID)
        .take(10)
        .toList();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(COLOR_PRIMARY), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: profile.profilePictureUrl != null &&
                  profile.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(profile.profilePictureUrl!)
                  : null,
              child: profile.profilePictureUrl == null ||
                  profile.profilePictureUrl!.isEmpty
                  ? Text(
                profile.firstName.isNotEmpty && profile.lastName.isNotEmpty
                    ? '${profile.firstName.substring(0, 1)}${profile.lastName.substring(0, 1)}'
                    : profile.email.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(COLOR_PRIMARY),
                ),
              )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName.isNotEmpty
                  ? profile.fullName
                  : 'Utilisateur',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.email,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.totalOperations} opérations',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(COLOR_PRIMARY),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.login,
              label: 'Dernière activité',
              value: profile.formattedLastLogin,
              color: Colors.green,
            ),
            const Divider(height: 20),
            _buildStatRow(
              icon: Icons.calendar_today,
              label: 'Compte créé le',
              value: profile.formattedAccountDate,
              color: Colors.blue,
            ),
            const Divider(height: 20),
            _buildStatRow(
              icon: Icons.auto_graph,
              label: 'Total opérations',
              value: '${profile.totalOperations} actions',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(List<OperationHistory> activities) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(COLOR_PRIMARY)),
                const SizedBox(width: 8),
                const Text(
                  'Activités Récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
                const Spacer(),
                if (activities.isNotEmpty)
                  Text(
                    '${activities.length} activités',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Aucune activité récente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: activities
                    .map((activity) => _buildActivityItem(activity))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(OperationHistory activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.operation),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _getActivityIcon(activity.operation),
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.operation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.formattedDate,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(activity.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String operation) {
    if (operation.toLowerCase().contains('led')) return Colors.green;
    if (operation.toLowerCase().contains('température')) return Colors.orange;
    if (operation.toLowerCase().contains('lumière')) return Colors.amber;
    if (operation.toLowerCase().contains('mode')) return Colors.purple;
    if (operation.toLowerCase().contains('seuil')) return Colors.blue;
    return const Color(COLOR_PRIMARY);
  }

  IconData _getActivityIcon(String operation) {
    if (operation.toLowerCase().contains('led')) return Icons.lightbulb;
    if (operation.toLowerCase().contains('température')) return Icons.thermostat;
    if (operation.toLowerCase().contains('lumière')) return Icons.light_mode;
    if (operation.toLowerCase().contains('mode')) return Icons.auto_awesome;
    if (operation.toLowerCase().contains('seuil')) return Icons.tune;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(COLOR_PRIMARY),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (profileSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final profile = profileSnapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 20),
                  _buildStatsCard(profile),
                  const SizedBox(height: 20),
                  FutureBuilder<List<OperationHistory>>(
                    future: _recentActivitiesFuture,
                    builder: (context, activitiesSnapshot) {
                      if (activitiesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildRecentActivities(
                          activitiesSnapshot.data ?? []);
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations du compte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(COLOR_PRIMARY),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'ID Utilisateur',
                            widget.user.userID.isNotEmpty
                                ? widget.user.userID
                                : 'Non disponible',
                            Icons.fingerprint,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Email',
                            widget.user.email,
                            Icons.email,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Nom complet',
                            widget.user.fullName(),
                            Icons.person,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}