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

  // Feeder atualmente selecionado para alarmes
  String? _currentFeederId;
  String? get currentFeederId => _currentFeederId;

  final Set<String> _triggeredAlarmsToday = {};
  int _lastCheckedMinute = -1;
  bool _hasSentAlarmsOnConnect = false;
  bool _isDataLoaded = false;

  List<Alarm> _alarms = [];
  List<Alarm> get alarms => _alarms;

  // Alarmes do feeder ativo
  List<Alarm> get alarmsForCurrentFeeder {
    if (_currentFeederId == null) return [];
    return _alarms.where((a) => a.feederId == _currentFeederId).toList();
  }

  void setCurrentFeeder(String feederId) {
    _currentFeederId = feederId;
    _hasSentAlarmsOnConnect = false;
    if (homeController.isConnected) {
      _sendAlarmsToEsp32();
    }
    notifyListeners();
  }

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
    if (homeController.isConnected) {
      _onHomeStatusChanged();
    }
  }

  void resetToDefaults() {
    _alarms.clear();
    _saveAlarmsLocal();
    notifyListeners();
    _sendAlarmsToEsp32();
    if (kDebugMode) print('AlarmController: Resetado para os padrões de fábrica.');
  }

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

  void _onHomeStatusChanged() {
    if (homeController.isConnected && _isDataLoaded) {
      if (!_hasSentAlarmsOnConnect && _currentFeederId != null) {
        _sendAlarmsToEsp32();
        _hasSentAlarmsOnConnect = true;
      }
    } else {
      if (!homeController.isConnected) {
        _hasSentAlarmsOnConnect = false;
      }
    }
  }

  void _sendAlarmsToEsp32() {
    if (!_isDataLoaded) return;
    if (!homeController.isConnected) return;
    if (_currentFeederId == null) return;

    try {
      final feederAlarms = _alarms.where((a) => a.feederId == _currentFeederId).toList();
      final List<Map<String, dynamic>> alarmsJsonList =
          feederAlarms.map((alarm) => alarm.toJson()).toList();
      final String alarmsJson = jsonEncode(alarmsJsonList);
      homeController.sendAlarmConfiguration(alarmsJson);
    } catch (e) {
      if (kDebugMode) print('Erro JSON: $e');
    }
  }

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

    String feederLabel = alarm.feederId;
    String timeString = "${alarm.time.hour}:${alarm.time.minute}";
    NotificationService().showAlarmNotification(
      title: 'Hora de comer! 🐾',
      body: 'Alarme do $feederLabel às $timeString.',
    );
    historyController.addEntry(
      type: HistoryType.alarm,
      description: 'Alarme do app disparado ($timeString) — $feederLabel',
      gramsDispensed: alarm.grams,
      feederId: alarm.feederId,
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
    final feederId = _currentFeederId ?? 'alimentador_01';
    final newAlarm = Alarm(
      id: _uuid.v4(),
      feederId: feederId,
      time: time,
      grams: grams,
      repeatDays: days,
    );
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
