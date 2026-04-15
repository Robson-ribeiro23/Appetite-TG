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
  final String? feederId;

  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    this.gramsDispensed,
    this.feederId,
  });

  // Salvar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'description': description,
      'gramsDispensed': gramsDispensed,
      'feederId': feederId,
    };
  }

  // Ler
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: HistoryType.values[json['type']],
      description: json['description'],
      gramsDispensed: json['gramsDispensed'] != null ? (json['gramsDispensed'] as num).toDouble() : null,
      feederId: json['feederId'] as String?,
    );
  }
}