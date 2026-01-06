import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import '../../model/user.dart';
import '../../services/esp32_service.dart';
import '../../services/helper.dart';
import '../auth/authentication_bloc.dart';
import '../auth/welcome/welcome_screen.dart';
import 'led_control_screen.dart';


class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _showIPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurer ESP32'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi, size: 48, color: Color(COLOR_PRIMARY)),
            const SizedBox(height: 16),
            const Text('Entrez l\'adresse IP de votre ESP32', style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                hintText: 'ex: 192.168.1.145',
                labelText: 'Adresse IP',
                prefixIcon: const Icon(Icons.router),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.yellow.shade700)),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(height: 8),
                  Text('L\'IP s\'affiche en JAUNE sur l\'écran ESP32', style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Format: IP: 192.168.x.x', style: TextStyle(fontSize: 11, color: Colors.orange.shade800), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () async {
              if (_ipController.text.isEmpty) {
                showSnackBar(context, 'Entrez une adresse IP');
                return;
              }
              String ip = _ipController.text.trim();
              ESP32Service.setIPAddress(ip);
              Navigator.pop(context);
              showSnackBar(context, 'Test connexion...');
              await Future.delayed(const Duration(milliseconds: 500));
              final connected = await ESP32Service.testConnection();
              if (connected) {
                showSnackBar(context, '✓ Connecté à $ip');
                setState(() => _selectedIndex = 1);
              } else {
                showSnackBar(context, '✗ Échec. Vérifiez IP et WiFi');
              }
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Connecter', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(COLOR_PRIMARY), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [_buildDashboardPage(), const LEDControlScreen(), _buildSettingsPage()];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Accueil' : _selectedIndex == 1 ? 'Contrôle LED' : 'Paramètres', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(COLOR_PRIMARY),
        actions: [
          if (_selectedIndex == 1) IconButton(icon: const Icon(Icons.settings_ethernet, color: Colors.white), onPressed: _showIPDialog, tooltip: 'IP'),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vous déconnecter ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthenticationBloc>().add(LogoutEvent());
                        pushAndRemoveUntil(context, const WelcomeScreen(), false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state.authState == AuthState.unauthenticated) {
            pushAndRemoveUntil(context, const WelcomeScreen(), false);
          }
        },
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'LED'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(COLOR_PRIMARY),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(COLOR_PRIMARY), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(
                children: [
                  displayCircleImage(widget.user.profilePictureURL, 70, true),
                  const SizedBox(height: 16),
                  Text('${widget.user.firstName} ${widget.user.lastName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(widget.user.email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Bienvenue ! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text('Contrôlez votre ESP32 et capteurs', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildQuickActionCard(icon: Icons.lightbulb, title: 'Contrôle\nLED', color: Colors.amber, onTap: () => _onItemTapped(1))),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickActionCard(icon: Icons.settings_ethernet, title: 'Config\nESP32', color: Colors.blue, onTap: _showIPDialog)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [Icon(Icons.info_outline, color: Color(COLOR_PRIMARY)), SizedBox(width: 8), Text('Fonctionnalités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                  const Divider(height: 24),
                  _buildFeatureItem('💡', 'Contrôle LED', 'Allumez/Éteignez la LED'),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🌡️', 'Température', 'Thermistance NTC 10kΩ'),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🔆', 'Luminosité', 'Capteur LDR'),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🤖', 'Mode Auto', 'Contrôle par seuils'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.memory, color: Colors.blue.shade700), const SizedBox(width: 8), Text('Matériel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900))]),
                  const Divider(height: 20),
                  _buildHardwareItem('LED', 'GPIO 25'),
                  _buildHardwareItem('LDR', 'GPIO 32'),
                  _buildHardwareItem('Thermistance', 'GPIO 33'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 36, color: color)),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])),
      ],
    );
  }

  Widget _buildHardwareItem(String label, String pin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)), child: Text(pin, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900))),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              ListTile(leading: const Icon(Icons.person, color: Color(COLOR_PRIMARY)), title: const Text('Profil'), subtitle: Text('${widget.user.firstName} ${widget.user.lastName}')),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.email, color: Color(COLOR_PRIMARY)), title: const Text('Email'), subtitle: Text(widget.user.email)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.settings_ethernet, color: Color(COLOR_PRIMARY)), title: const Text('Configuration ESP32'), subtitle: const Text('IP de l\'ESP32'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: _showIPDialog)),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Color(COLOR_PRIMARY)),
                title: const Text('À propos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => showDialog(context: context, builder: (context) => AlertDialog(title: const Text('À propos'), content: const Text('Application IoT ESP32\nVersion 1.0.0\n\nContrôlez ESP32 en temps réel\n\nMatériel:\n• ESP32 TTGO T-Display\n• Thermistance NTC 10kΩ\n• Capteur LDR\n• LED GPIO 25'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vous déconnecter ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      ElevatedButton(onPressed: () {Navigator.pop(context); context.read<AuthenticationBloc>().add(LogoutEvent()); pushAndRemoveUntil(context, const WelcomeScreen(), false);}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Déconnexion')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}