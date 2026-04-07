import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:appetite/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AlarmController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  Timer? _timer;

  final HomeController homeController;
  final HistoryController historyController;

  final Set<String> _triggeredAlarmsToday = {};
  int _lastCheckedMinute = -1;
  bool _hasSentAlarmsOnConnect = false;
  
  bool _isDataLoaded = false;

  List<Alarm> _alarms = [];
  List<Alarm> get alarms => _alarms;

  AlarmController({
    required this.homeController,
    required this.historyController,
  }) {
    _initController();
  }

  Future<void> _initController() async {
    await _loadAlarms();
    _startMonitoring();
    homeController.addListener(_onHomeStatusChanged);
    
    if (homeController.status == ConnectionStatus.connected) {
      _onHomeStatusChanged();
    }
  }

  // ---  RESET DE FÁBRICA ---
  void resetToDefaults() {
    _alarms.clear(); // Limpa lista da memória
    _saveAlarmsLocal(); // Limpa do disco (salva lista vazia)
    notifyListeners(); // Atualiza a tela
    _sendAlarmsToEsp32(); // Avisa o ESP32 para limpar também
    if (kDebugMode) print('AlarmController: Resetado para os padrões de fábrica.');
  }

  // --- PERSISTÊNCIA ---

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? alarmsString = prefs.getString('saved_alarms');

      if (alarmsString != null) {
        final List<dynamic> decodedList = jsonDecode(alarmsString);
        _alarms = decodedList.map((item) => Alarm.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar alarmes: $e');
    } finally {
      _isDataLoaded = true;
    }
  }

  Future<void> _saveAlarmsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList = jsonEncode(_alarms.map((a) => a.toJson()).toList());
      await prefs.setString('saved_alarms', encodedList);
    } catch (e) {
      if (kDebugMode) print('Erro ao salvar alarmes: $e');
    }
  }

  // --- CONEXÃO ---

  void _onHomeStatusChanged() {
    if (homeController.status == ConnectionStatus.connected && _isDataLoaded) {
      if (!_hasSentAlarmsOnConnect) {
        _sendAlarmsToEsp32();
        _hasSentAlarmsOnConnect = true;
      }
    } else {
      if (homeController.status != ConnectionStatus.connected) {
        _hasSentAlarmsOnConnect = false;
      }
    }
  }

  void _sendAlarmsToEsp32() {
    if (!_isDataLoaded) return;
    if (homeController.status != ConnectionStatus.connected) return;

    try {
      final List<Map<String, dynamic>> alarmsJsonList =
          _alarms.map((alarm) => alarm.toJson()).toList();
      final String alarmsJson = jsonEncode(alarmsJsonList);
      homeController.sendAlarmConfiguration(alarmsJson);
    } catch (e) {
      if (kDebugMode) print('Erro JSON: $e');
    }
  }

  // --- MONITORAMENTO ---
  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    if (now.minute == _lastCheckedMinute) return;
    _lastCheckedMinute = now.minute;

    if (now.hour == 0 && now.minute == 0) {
      _triggeredAlarmsToday.clear();
    }

    for (final alarm in _alarms) {
      if (!alarm.isActive) continue;
      if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
        _triggerAlarm(alarm);
      }
    }
  }

  void _triggerAlarm(Alarm alarm) {
    final todayKey = "${alarm.id}_${DateTime.now().day}";
    if (_triggeredAlarmsToday.contains(todayKey)) return;

    String timeString = "${alarm.time.hour}:${alarm.time.minute}";
    NotificationService().showAlarmNotification(
      title: 'Hora de comer! 🐾',
      body: 'Horário programado: $timeString.',
    );
    historyController.addEntry(
      type: HistoryType.alarm,
      description: 'Alarme do app disparado ($timeString).',
      gramsDispensed: alarm.grams,
    );
    _triggeredAlarmsToday.add(todayKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    homeController.removeListener(_onHomeStatusChanged);
    super.dispose();
  }

  // --- CRUD ---

  void addAlarm({required TimeOfDay time, required double grams, required List<int> days}) {
    final newAlarm = Alarm(id: _uuid.v4(), time: time, grams: grams, repeatDays: days);
    _alarms.add(newAlarm);
    notifyListeners();
    _saveAlarmsLocal();
    _sendAlarmsToEsp32();
  }

  void deleteAlarm(String alarmId) {
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    notifyListeners();
    _saveAlarmsLocal();
    _sendAlarmsToEsp32();
  }

  void toggleAlarmActive(String alarmId) {
    final index = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (index != -1) {
      _alarms[index].isActive = !_alarms[index].isActive;
      notifyListeners();
      _saveAlarmsLocal();
      _sendAlarmsToEsp32();
    }
  }

  void updateAlarm(Alarm updatedAlarm) {
    final index = _alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
      _saveAlarmsLocal();
      _sendAlarmsToEsp32();
    }
  }
}