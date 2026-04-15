import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final String feederId;
  TimeOfDay time;
  double grams;
  List<int> repeatDays;
  bool isActive;
  bool isRepeatingWeekly;

  Alarm({
    required this.id,
    required this.feederId,
    required this.time,
    required this.grams,
    required this.repeatDays,
    this.isActive = true,
    this.isRepeatingWeekly = true,
  });

  // Converte para JSON (Salvar)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feederId': feederId,
      'hour': time.hour,
      'minute': time.minute,
      'grams': grams,
      'repeatDays': repeatDays,
      'isActive': isActive,
      'isRepeatingWeekly': isRepeatingWeekly,
    };
  }

  // Converte de JSON (Ler)
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      feederId: json['feederId'] as String? ?? 'alimentador_01',
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      grams: (json['grams'] as num).toDouble(),
      repeatDays: List<int>.from(json['repeatDays']),
      isActive: json['isActive'],
      isRepeatingWeekly: json['isRepeatingWeekly'],
    );
  }

  Alarm copyWith({
    String? id,
    String? feederId,
    TimeOfDay? time,
    double? grams,
    List<int>? repeatDays,
    bool? isActive,
    bool? isRepeatingWeekly,
  }) {
    return Alarm(
      id: id ?? this.id,
      feederId: feederId ?? this.feederId,
      time: time ?? this.time,
      grams: grams ?? this.grams,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      isRepeatingWeekly: isRepeatingWeekly ?? this.isRepeatingWeekly,
    );
  }
}