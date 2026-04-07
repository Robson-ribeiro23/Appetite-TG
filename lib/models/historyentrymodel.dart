// lib/models/history_entry_model.dart


// Tipos de eventos possíveis no histórico
enum HistoryType { 
  alarm, // Evento gerado por um alarme automático
  manual, // Evento gerado por acionamento manual na HomeTab
  error // Evento de erro (ex: falha de conexão ou dispensa)
}

class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final HistoryType type;
  final String description;
  final double? gramsDispensed;

  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    this.gramsDispensed,
  });

  // Salvar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(), // Salva data como texto
      'type': type.index, // Salva o índice do Enum (0, 1, 2)
      'description': description,
      'gramsDispensed': gramsDispensed,
    };
  }

  // Ler
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: HistoryType.values[json['type']], // Recupera o Enum pelo índice
      description: json['description'],
      gramsDispensed: json['gramsDispensed'] != null ? (json['gramsDispensed'] as num).toDouble() : null,
    );
  }
}