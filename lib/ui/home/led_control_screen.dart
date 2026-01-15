import 'dart:async';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../model/user/user.dart';
import '../../services/esp32/esp32_service.dart';
import '../../services/helper.dart';

class LEDControlScreen extends StatefulWidget {
  final User user;

  const LEDControlScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<LEDControlScreen> createState() => _LEDControlScreenState();
}

class _LEDControlScreenState extends State<LEDControlScreen> {
  DeviceStatus? deviceStatus;
  bool isLoading = false;
  bool isConnected = false;
  Timer? _refreshTimer;

  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _lightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tempController.dispose();
    _lightController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => isLoading = true);
    final connected = await ESP32Service.testConnection();
    setState(() {
      isConnected = connected;
      isLoading = false;
    });

    if (connected) {
      await _refreshStatus();
      _startAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshStatus();
    });
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;

    final status = await ESP32Service.getStatus();
    if (status != null && mounted) {
      setState(() {
        deviceStatus = status;
        _tempController.text = status.thresholds.tempThreshold.toString();
        _lightController.text = status.thresholds.lightThreshold.toString();
      });
    }
  }

  Future<void> _turnOn() async {
    setState(() => isLoading = true);
    final result = await ESP32Service.turnOn(user: widget.user);
    if (result != null) {
      showSnackBar(context, 'LED allumée ✓');
      await _refreshStatus();
    } else {
      showSnackBar(context, 'Erreur de connexion ✗');
    }
    setState(() => isLoading = false);
  }

  Future<void> _turnOff() async {
    setState(() => isLoading = true);
    final result = await ESP32Service.turnOff(user: widget.user);
    if (result != null) {
      showSnackBar(context, 'LED éteinte ✓');
      await _refreshStatus();
    } else {
      showSnackBar(context, 'Erreur de connexion ✗');
    }
    setState(() => isLoading = false);
  }

  Future<void> _toggle() async {
    setState(() => isLoading = true);
    final result = await ESP32Service.toggle(user: widget.user);
    if (result != null) {
      showSnackBar(context, 'LED basculée ✓');
      await _refreshStatus();
    } else {
      showSnackBar(context, 'Erreur de connexion ✗');
    }
    setState(() => isLoading = false);
  }

  Future<void> _toggleAutoMode() async {
    setState(() => isLoading = true);

    if (deviceStatus?.autoMode == true) {
      await ESP32Service.disableAutoMode(user: widget.user);
      showSnackBar(context, 'Mode automatique désactivé');
    } else {
      await ESP32Service.enableAutoMode(user: widget.user);
      showSnackBar(context, 'Mode automatique activé');
    }

    await _refreshStatus();
    setState(() => isLoading = false);
  }

  Future<void> _updateTemperatureThreshold() async {
    final value = double.tryParse(_tempController.text);
    if (value == null) {
      showSnackBar(context, 'Valeur invalide');
      return;
    }

    setState(() => isLoading = true);
    final result = await ESP32Service.setTemperatureThreshold(
      value: value,
      enabled: deviceStatus?.thresholds.tempEnabled ?? false,
      user: widget.user,
    );

    if (result != null) {
      showSnackBar(context, 'Seuil température mis à jour ✓');
      await _refreshStatus();
    } else {
      showSnackBar(context, 'Erreur mise à jour ✗');
    }
    setState(() => isLoading = false);
  }

  Future<void> _updateLightThreshold() async {
    final value = int.tryParse(_lightController.text);
    if (value == null) {
      showSnackBar(context, 'Valeur invalide');
      return;
    }

    setState(() => isLoading = true);
    final result = await ESP32Service.setLightThreshold(
      value: value,
      enabled: deviceStatus?.thresholds.lightEnabled ?? false,
      user: widget.user,
    );

    if (result != null) {
      showSnackBar(context, 'Seuil lumière mis à jour ✓');
      await _refreshStatus();
    } else {
      showSnackBar(context, 'Erreur mise à jour ✗');
    }
    setState(() => isLoading = false);
  }

  Future<void> _toggleTempControl(bool enabled) async {
    final value = double.tryParse(_tempController.text) ?? 25.0;
    await ESP32Service.setTemperatureThreshold(
      value: value,
      enabled: enabled,
      user: widget.user,
    );
    await _refreshStatus();
  }

  Future<void> _toggleLightControl(bool enabled) async {
    final value = int.tryParse(_lightController.text) ?? 500;
    await ESP32Service.setLightThreshold(
      value: value,
      enabled: enabled,
      user: widget.user,
    );
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Non connecté à l\'ESP32',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Configurez l\'IP dans les paramètres',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkConnection,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(COLOR_PRIMARY),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildSensorCard(),
            const SizedBox(height: 16),
            _buildManualControlCard(),
            const SizedBox(height: 16),
            _buildAutoModeCard(),
            const SizedBox(height: 16),
            if (deviceStatus?.autoMode == true) _buildThresholdsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final ledOn = deviceStatus?.ledOn ?? false;
    final autoMode = deviceStatus?.autoMode ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: ledOn
                ? [Colors.green.shade300, Colors.green.shade600]
                : [Colors.red.shade300, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(ledOn ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 64, color: Colors.white),
            const SizedBox(height: 12),
            Text(ledOn ? 'LED ALLUMÉE' : 'LED ÉTEINTE',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(autoMode ? 'MODE AUTOMATIQUE' : 'MODE MANUEL',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.sensors, color: Color(COLOR_PRIMARY)),
              SizedBox(width: 8),
              Text('Données Capteurs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 24),
            _buildSensorRow(Icons.thermostat, 'Température',
                '${deviceStatus?.sensorData.temperature.toStringAsFixed(2) ?? '--'} °C', Colors.orange),
            const SizedBox(height: 12),
            _buildSensorRow(
                Icons.light_mode,
                'Lumière',
                deviceStatus != null
                    ? '${deviceStatus!.sensorData.lightPercent.toStringAsFixed(1)} %'
                    : '--',
                Colors.amber),
            const SizedBox(height: 8),
            if (deviceStatus != null)
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text('ADC: ${deviceStatus!.sensorData.light}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildManualControlCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.touch_app, color: Color(COLOR_PRIMARY)),
              SizedBox(width: 8),
              Text('Contrôle Manuel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _turnOn,
                      icon: const Icon(Icons.lightbulb, color: Colors.white),
                      label: const Text('ALLUMER',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _turnOff,
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                      label: const Text('ÉTEINDRE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggle,
                      icon: const Icon(Icons.sync, color: Colors.white),
                      label: const Text('BASCULER',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(COLOR_PRIMARY),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoModeCard() {
    final autoMode = deviceStatus?.autoMode ?? false;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.auto_awesome, color: Color(COLOR_PRIMARY)),
              SizedBox(width: 8),
              Text('Mode Automatique',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            const Text('Contrôle LED selon seuils définis',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(autoMode ? 'ACTIVÉ' : 'DÉSACTIVÉ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(autoMode
                  ? 'LED contrôlée automatiquement'
                  : 'Contrôle manuel uniquement'),
              value: autoMode,
              onChanged: (_) => _toggleAutoMode(),
              activeColor: const Color(COLOR_PRIMARY),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsCard() {
    final currentTemp = deviceStatus?.sensorData.temperature ?? 0;
    final currentLight = deviceStatus?.sensorData.light ?? 0;
    final lightPercent = deviceStatus?.sensorData.lightPercent ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Configuration Seuils',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (deviceStatus?.autoMode == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green.shade800),
                        const SizedBox(width: 4),
                        Text('ACTIF',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Définissez les conditions d\'allumage automatique',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contrôle par Température',
                                style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Allumer si trop chaud',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: (deviceStatus?.thresholds.tempEnabled ?? false)
                              ? Colors.orange.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (deviceStatus?.thresholds.tempEnabled ?? false)
                                ? Colors.orange.shade300
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (deviceStatus?.thresholds.tempEnabled ?? false)
                                  ? 'ON'
                                  : 'OFF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (deviceStatus?.thresholds.tempEnabled ?? false)
                                    ? Colors.orange.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: deviceStatus?.thresholds.tempEnabled ?? false,
                              onChanged: _toggleTempControl,
                              activeColor: Colors.orange,
                              activeTrackColor: Colors.orange.shade300,
                              inactiveThumbColor: Colors.grey.shade600,
                              inactiveTrackColor: Colors.grey.shade400,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Actuelle',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey.shade600)),
                                Text('Seuil',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  height: 8,
                                  width: (currentTemp / 50.0) *
                                      MediaQuery.of(context).size.width *
                                      0.7,
                                  decoration: BoxDecoration(
                                    color: currentTemp >
                                        (double.tryParse(_tempController.text) ??
                                            25.0)
                                        ? Colors.orange
                                        : Colors.orange.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Positioned(
                                  left: ((double.tryParse(_tempController.text) ?? 25.0) /
                                      50.0) *
                                      MediaQuery.of(context).size.width *
                                      0.7 -
                                      2,
                                  child: Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${currentTemp.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800)),
                                Text('${_tempController.text}°C',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (deviceStatus?.thresholds.tempEnabled ?? false)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: double.tryParse(_tempController.text) ?? 25.0,
                                min: 0,
                                max: 50,
                                divisions: 50,
                                label:
                                '${(double.tryParse(_tempController.text) ?? 25.0).toStringAsFixed(1)}°C',
                                onChanged: (value) {
                                  setState(() {
                                    _tempController.text = value.toStringAsFixed(1);
                                  });
                                },
                                activeColor: Colors.orange,
                                inactiveColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _tempController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: '°C',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                onSubmitted: (value) => _updateTemperatureThreshold(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _updateTemperatureThreshold,
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('Appliquer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final current =
                                    double.tryParse(_tempController.text) ?? 25.0;
                                _tempController.text = (current + 5.0).toStringAsFixed(1);
                                _updateTemperatureThreshold();
                              },
                              icon: Icon(Icons.add, color: Colors.orange),
                              tooltip: 'Augmenter de 5°C',
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.light_mode, color: Colors.amber.shade700, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contrôle par Lumière',
                                style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Allumer si trop sombre',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: (deviceStatus?.thresholds.lightEnabled ?? false)
                              ? Colors.amber.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (deviceStatus?.thresholds.lightEnabled ?? false)
                                ? Colors.amber.shade300
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (deviceStatus?.thresholds.lightEnabled ?? false)
                                  ? 'ON'
                                  : 'OFF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (deviceStatus?.thresholds.lightEnabled ?? false)
                                    ? Colors.amber.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: deviceStatus?.thresholds.lightEnabled ?? false,
                              onChanged: _toggleLightControl,
                              activeColor: Colors.amber,
                              activeTrackColor: Colors.amber.shade300,
                              inactiveThumbColor: Colors.grey.shade600,
                              inactiveTrackColor: Colors.grey.shade400,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Actuelle',
                              style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text('Seuil',
                              style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 8,
                            width: ((4095 - currentLight) / 4095.0) *
                                MediaQuery.of(context).size.width *
                                0.7,
                            decoration: BoxDecoration(
                              color: currentLight <
                                  (int.tryParse(_lightController.text) ?? 1000)
                                  ? Colors.amber
                                  : Colors.amber.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Positioned(
                            left: ((4095 - (int.tryParse(_lightController.text) ?? 1000)) /
                                4095.0) *
                                MediaQuery.of(context).size.width *
                                0.7 -
                                2,
                            child: Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$currentLight',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800)),
                              Text('${lightPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_lightController.text,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700)),
                              Text(
                                  '${((int.tryParse(_lightController.text) ?? 1000) / 4095.0 * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (deviceStatus?.thresholds.lightEnabled ?? false)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: (int.tryParse(_lightController.text) ?? 1000)
                                    .toDouble(),
                                min: 0,
                                max: 4095,
                                divisions: 40,
                                label: _lightController.text,
                                onChanged: (value) {
                                  setState(() {
                                    _lightController.text = value.round().toString();
                                  });
                                },
                                activeColor: Colors.amber,
                                inactiveColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _lightController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'ADC',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                onSubmitted: (value) => _updateLightThreshold(),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.dark_mode,
                                      size: 16, color: Colors.grey.shade700),
                                  Text('Sombre',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey.shade700)),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.brightness_medium,
                                      size: 16, color: Colors.grey.shade700),
                                  Text('Moyen',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey.shade700)),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.brightness_high,
                                      size: 16, color: Colors.grey.shade700),
                                  Text('Clair',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey.shade700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _updateLightThreshold,
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('Appliquer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final current =
                                    int.tryParse(_lightController.text) ?? 1000;
                                _lightController.text =
                                    (current + 500).clamp(0, 4095).toString();
                                _updateLightThreshold();
                              },
                              icon: Icon(Icons.add, color: Colors.amber),
                              tooltip: 'Augmenter de 500',
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('Règles Actives',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!(deviceStatus?.thresholds.tempEnabled ?? false) &&
                      !(deviceStatus?.thresholds.lightEnabled ?? false))
                    Text('Aucune règle active - Le mode automatique est inactif',
                        style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  if (deviceStatus?.thresholds.tempEnabled ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Allumer la LED si température > ${_tempController.text}°C',
                              style:
                              TextStyle(fontSize: 14, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (deviceStatus?.thresholds.lightEnabled ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Allumer la LED si luminosité < ${_lightController.text} (${((int.tryParse(_lightController.text) ?? 1000) / 4095.0 * 100).toStringAsFixed(1)}%)',
                              style:
                              TextStyle(fontSize: 14, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'La LED s\'allume si au moins une condition est remplie (logique OU)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}