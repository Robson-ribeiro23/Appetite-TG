import 'package:flutter/material.dart';

class Alarm {
  final String id;
  TimeOfDay time;
  double grams;
  List<int> repeatDays;
  bool isActive;
  bool isRepeatingWeekly;

  Alarm({
    required this.id,
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
      'hour': time.hour,
      'minute': time.minute,
      'grams': grams,
      'repeatDays': repeatDays,
      'isActive': isActive,
      'isRepeatingWeekly': isRepeatingWeekly,
    };
  }

  // Converte de JSON (Ler) -> NOVO MÉTODO
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      grams: (json['grams'] as num).toDouble(),
      repeatDays: List<int>.from(json['repeatDays']),
      isActive: json['isActive'],
      isRepeatingWeekly: json['isRepeatingWeekly'],
    );
  }
  // Método para criar uma cópia do objeto (útil para edição)
  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    double? grams,
    List<int>? repeatDays,
    bool? isActive,
    bool? isRepeatingWeekly,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      grams: grams ?? this.grams,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      isRepeatingWeekly: isRepeatingWeekly ?? this.isRepeatingWeekly,
    );
  }

  
}