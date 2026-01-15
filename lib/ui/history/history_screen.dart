// ui/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../model/history/history.dart';
import '../../services/history/history_service.dart';

class HistoryScreen extends StatefulWidget {
  final String userId; // NOUVEAU: ajouter userId

  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<OperationHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await _historyService.initialize(widget.userId);
    _history = _historyService.getHistory();
    setState(() => _isLoading = false);
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text('Voulez-vous vraiment effacer tout l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _historyService.clearHistory(widget.userId);
              await _loadHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Effacer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(OperationHistory item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getOperationColor(item.operation),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getOperationIcon(item.operation),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.operation,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          item.details,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.formattedDate,
              style:  const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              DateFormat('HH:mm').format(item.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOperationColor(String operation) {
    if (operation. toLowerCase().contains('allumée')) return Colors.green;
    if (operation.toLowerCase().contains('éteinte')) return Colors.red;
    if (operation.toLowerCase().contains('basculée')) return Colors.blue;
    if (operation.toLowerCase().contains('seuil')) return Colors.orange;
    if (operation.toLowerCase().contains('mode')) return Colors.purple;
    return const Color(COLOR_PRIMARY);
  }

  IconData _getOperationIcon(String operation) {
    if (operation.toLowerCase().contains('led')) return Icons.lightbulb;
    if (operation.toLowerCase().contains('température')) return Icons.thermostat;
    if (operation.toLowerCase().contains('lumière')) return Icons.light_mode;
    if (operation.toLowerCase().contains('mode')) return Icons.auto_awesome;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Opérations'),
        backgroundColor:  const Color(COLOR_PRIMARY),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Effacer l\'historique',
            ),
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey. shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucune opération enregistrée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les opérations que vous effectuez\napparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            return _buildHistoryItem(_history[index]);
          },
        ),
      ),
    );
  }
}