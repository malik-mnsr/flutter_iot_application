import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../model/user/user.dart';
import '../../services/esp32/esp32_service.dart';

class JsonViewerScreen extends StatefulWidget {
  final User user;

  const JsonViewerScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<JsonViewerScreen> createState() => _JsonViewerScreenState();
}

class _JsonViewerScreenState extends State<JsonViewerScreen> {
  DeviceStatus? _deviceStatus;
  bool _isLoading = true;
  bool _isPrettyPrint = true;
  String _jsonString = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final status = await ESP32Service.getStatus();

    if (status != null) {
      setState(() {
        _deviceStatus = status;
        _updateJsonString();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _updateJsonString() {
    if (_deviceStatus == null) return;

    final Map<String, dynamic> data = {
      'device': {
        'led': _deviceStatus!.ledOn ? 'ON' : 'OFF',
        'mode': _deviceStatus!.autoMode ? 'AUTO' : 'MANUAL',
      },
      'sensors': {
        'temperature': {
          'value': _deviceStatus!.sensorData.temperature,
          'unit': '°C',
        },
        'humidity': {
          'value': _deviceStatus!.sensorData.humidity,
          'unit': '%',
        },
        'light': {
          'raw': _deviceStatus!.sensorData.light,
          'percent': _deviceStatus!.sensorData.lightPercent,
          'max': 4095,
        },
      },
      'thresholds': {
        'temperature': {
          'value': _deviceStatus!.thresholds.tempThreshold,
          'enabled': _deviceStatus!.thresholds.tempEnabled,
        },
        'light': {
          'value': _deviceStatus!.thresholds.lightThreshold,
          'enabled': _deviceStatus!.thresholds.lightEnabled,
        },
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    final encoder = _isPrettyPrint
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();

    _jsonString = encoder.convert(data);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vue JSON', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(COLOR_PRIMARY),
        actions: [
          IconButton(
            icon: Icon(
              _isPrettyPrint ? Icons.compress : Icons.code,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isPrettyPrint = !_isPrettyPrint;
                _updateJsonString();
              });
            },
            tooltip: _isPrettyPrint ? 'Compresser' : 'Formatter',
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _deviceStatus != null ? _copyToClipboard : null,
            tooltip: 'Copier',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deviceStatus == null
          ? _buildErrorView()
          : _buildJsonView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les données',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(COLOR_PRIMARY),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonView() {
    return Column(
      children: [
        // Header avec info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Icon(Icons.data_object, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Format JSON',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isPrettyPrint ? 'Formaté (Pretty Print)' : 'Compressé',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  '${_jsonString.length} caractères',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.blue.shade50,
              ),
            ],
          ),
        ),

        // JSON content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _jsonString,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Colors.greenAccent,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Footer avec actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier JSON'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPrettyPrint = !_isPrettyPrint;
                      _updateJsonString();
                    });
                  },
                  icon: Icon(_isPrettyPrint ? Icons.compress : Icons.code),
                  label: Text(_isPrettyPrint ? 'Compresser' : 'Formatter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(COLOR_PRIMARY),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
