enum FeederStatus { online, offline, unknown }

class FeederModel {
  final String id;
  final String name;
  final String mqttTopicPrefix;
  FeederStatus status;
  String lastSeen;

  FeederModel({
    required this.id,
    required this.name,
    required this.mqttTopicPrefix,
    this.status = FeederStatus.unknown,
    this.lastSeen = 'Nunca',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'topic': mqttTopicPrefix,
        'status': status.index,
        'lastSeen': lastSeen,
      };

  factory FeederModel.fromJson(Map<String, dynamic> json) => FeederModel(
        id: json['id'] as String,
        name: json['name'] as String,
        mqttTopicPrefix: json['topic'] as String,
        status: FeederStatus.values[json['status'] as int? ?? 2],
        lastSeen: json['lastSeen'] as String? ?? 'Nunca',
      );

  FeederModel copyWith({
    String? name,
    FeederStatus? status,
    String? lastSeen,
  }) =>
      FeederModel(
        id: id,
        name: name ?? this.name,
        mqttTopicPrefix: mqttTopicPrefix,
        status: status ?? this.status,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}
