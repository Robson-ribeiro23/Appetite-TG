import 'dart:async';
import 'dart:convert'; // Necessário para jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necessário para salvar no disco
import 'package:appetite/models/historyentrymodel.dart';
import 'package:uuid/uuid.dart';

class HistoryController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  
  // Lista privada de histórico (Inicia vazia e carrega do disco)
  List<HistoryEntry> _history = []; 

  HistoryController() {
    _loadHistory(); // Carrega o histórico assim que o controller nasce
  }

  // Getter que retorna a lista ordenada pela data mais recente
  List<HistoryEntry> get history {
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _history;
  }

  // --- MÉTODOS DE PERSISTÊNCIA ---

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString('saved_history');

      if (historyString != null) {
        final List<dynamic> decodedList = jsonDecode(historyString);
        // Converte a lista de JSON de volta para objetos HistoryEntry
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
      
      // Limpeza Automática: Mantém apenas os 50 itens mais recentes para economizar memória
      if (_history.length > 50) {
         // Ordena para garantir que os antigos fiquem no fim
         _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
         // Corta a lista mantendo apenas os 50 primeiros (mais novos)
         _history = _history.sublist(0, 50);
      }

      // Converte a lista de objetos para JSON String
      final String encodedList = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString('saved_history', encodedList);
    } catch (e) {
      debugPrint('Erro ao salvar histórico: $e');
    }
  }

  // --- MÉTODOS PÚBLICOS ---

  void addEntry({
    required HistoryType type,
    required String description,
    double? gramsDispensed,
  }) {
    final newEntry = HistoryEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: type,
      description: description,
      gramsDispensed: gramsDispensed,
    );
    
    _history.add(newEntry);
    _saveHistory(); // Salva no disco imediatamente
    notifyListeners();
  }
  
  // Limpa o histórico da memória e do disco
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