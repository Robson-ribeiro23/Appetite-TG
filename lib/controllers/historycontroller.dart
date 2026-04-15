import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:uuid/uuid.dart';

class HistoryController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  List<HistoryEntry> _history = [];

  HistoryController() {
    _loadHistory();
  }

  // Histórico completo
  List<HistoryEntry> _sortedHistory() {
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _history;
  }

  // Histórico por alimentador
  List<HistoryEntry> getHistoryForFeeder(String? feederId) {
    final sorted = _sortedHistory();
    if (feederId == null) return sorted;
    return sorted.where((e) => e.feederId == feederId).toList();
  }

  // getter antigo mantido por compatibilidade
  List<HistoryEntry> get history => _sortedHistory();

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString('saved_history');

      if (historyString != null) {
        final List<dynamic> decodedList = jsonDecode(historyString);
        _history = decodedList.map((item) => HistoryEntry.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_history.length > 50) {
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _history = _history.sublist(0, 50);
      }
      final String encodedList = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString('saved_history', encodedList);
    } catch (e) {
      debugPrint('Erro ao salvar histórico: $e');
    }
  }

  void addEntry({
    required HistoryType type,
    required String description,
    double? gramsDispensed,
    String? feederId,
  }) {
    final newEntry = HistoryEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: type,
      description: description,
      gramsDispensed: gramsDispensed,
      feederId: feederId,
    );
    _history.add(newEntry);
    _saveHistory();
    notifyListeners();
  }

  void clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_history');
    notifyListeners();
  }

  void resetToDefaults() {
    _history.clear();
    notifyListeners();
  }
}
