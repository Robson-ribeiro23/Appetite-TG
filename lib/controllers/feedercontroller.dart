import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appetite/models/feedermodel.dart';
import 'package:appetite/services/mqtt_service.dart';

enum FeederConnectionState { discovering, idle, connected }

class FeederController extends ChangeNotifier {
  final MqttService _service = MqttService();

  FeederConnectionState _connectionState = FeederConnectionState.discovering;
  FeederModel? _selectedFeeder;
  final List<FeederModel> _feeders = [];
  final Map<String, Timer> _pingTimeouts = {};

  // Feeders conhecidos (persistidos)
  List<FeederModel> get feeders => List.unmodifiable(_feeders);
  FeederModel? get selectedFeeder => _selectedFeeder;
  FeederConnectionState get connectionState => _connectionState;
  bool get isConnected =>
      _connectionState == FeederConnectionState.connected &&
      _selectedFeeder?.status == FeederStatus.online;

  StreamSubscription? _statusSub;

  FeederController() {
    _loadFeeders();

    // Monitora status da conexao MQTT
    _statusSub = _service.statusStream.listen((status) {
      if (status == MqttServiceStatus.connected) {
        _discoverFeeders();
      } else if (status == MqttServiceStatus.disconnected) {
        for (final f in _feeders) {
          f.status = FeederStatus.offline;
        }
        if (_connectionState == FeederConnectionState.connected) {
          _connectionState = FeederConnectionState.idle;
        }
        notifyListeners();
      }
    });

    // Monitora respostas de todos os alimentadores
    _service.messageStream.listen((event) {
      final topic = event['topic'] ?? '';
      final payload = event['payload'] ?? '';
      onMessage(topic: topic, payload: payload);
    });
  }

  void onMessage({required String topic, required String payload}) {
    for (final feeder in _feeders) {
      if (topic.contains(feeder.mqttTopicPrefix) ||
          topic.contains(feeder.id)) {
        if (payload.contains('online') ||
            payload.contains('alimentando') ||
            payload.contains('sucesso') ||
            payload.contains('alarmes')) {
          feeder.status = FeederStatus.online;
          feeder.lastSeen = 'Agora';
          _pingTimeouts[feeder.id]?.cancel();
          if (_selectedFeeder?.id == feeder.id &&
              _connectionState == FeederConnectionState.discovering) {
            _connectionState = FeederConnectionState.connected;
          }
          notifyListeners();
        }
      }
    }
  }

  Future<void> _loadFeeders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('saved_feeders');
    if (savedJson != null) {
      final List<dynamic> list = jsonDecode(savedJson);
      _feeders.clear();
      for (final item in list) {
        _feeders.add(FeederModel.fromJson(item));
      }
    }
    // Se nenhum feeder salvo, adicionar o padrao
    if (_feeders.isEmpty) {
      _feeders.add(FeederModel(
        id: 'alimentador_01',
        name: 'Alimentador 01',
        mqttTopicPrefix: 'appetite/device/alimentador_01',
        status: FeederStatus.unknown,
      ));
    }
    _startMqttConnection();
    notifyListeners();
  }

  Future<void> _saveFeeders() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_feeders.map((e) => e.toJson()).toList());
    await prefs.setString('saved_feeders', encoded);
  }

  Future<void> _startMqttConnection() async {
    _connectionState = FeederConnectionState.discovering;
    notifyListeners();

    final success = await _service.connectToBroker();
    if (success) {
      Timer(const Duration(milliseconds: 500), () {
        // subscreve aos topics de todos os feeders
        for (final feeder in _feeders) {
          _service.subscribeToTopic('${feeder.mqttTopicPrefix}/status');
        }
        _discoverFeeders();
      });
    } else {
      _connectionState = FeederConnectionState.idle;
      notifyListeners();
    }
  }

  void _discoverFeeders() {
    _connectionState = FeederConnectionState.discovering;
    for (final feeder in _feeders) {
      feeder.status = FeederStatus.unknown;
      _service.publishCommand(
        topic: '${feeder.mqttTopicPrefix}/command/manual',
        payload: '{"ping": true}',
      );
      _pingTimeouts[feeder.id] = Timer(const Duration(seconds: 4), () {
        if (feeder.status == FeederStatus.unknown) {
          feeder.status = FeederStatus.offline;
          feeder.lastSeen = 'Offline';
          notifyListeners();
        }
      });
    }
    Timer(const Duration(seconds: 5), () {
      if (_connectionState == FeederConnectionState.discovering) {
        _connectionState = FeederConnectionState.idle;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> selectFeeder(FeederModel feeder) async {
    _selectedFeeder = feeder;
    _service.subscribeToTopic('${feeder.mqttTopicPrefix}/status');

    _connectionState = FeederConnectionState.discovering;
    notifyListeners();

    _service.publishCommand(
      topic: '${feeder.mqttTopicPrefix}/command/manual',
      payload: '{"ping": true}',
    );

    _pingTimeouts[feeder.id] = Timer(const Duration(seconds: 4), () {
      if (_selectedFeeder?.id == feeder.id) {
        if (feeder.status != FeederStatus.online) {
          feeder.status = FeederStatus.offline;
          feeder.lastSeen = 'Offline';
          _connectionState = FeederConnectionState.idle;
        }
        notifyListeners();
      }
    });
  }

  Future<bool> sendCommand(String payload) async {
    if (_selectedFeeder == null) return false;
    return _service.publishCommand(
      topic: '${_selectedFeeder!.mqttTopicPrefix}/command/manual',
      payload: payload,
    );
  }

  Future<bool> sendAlarmConfiguration(String alarmsJson) async {
    if (_selectedFeeder == null) return false;
    return _service.publishCommand(
      topic: '${_selectedFeeder!.mqttTopicPrefix}/command/alarms',
      payload: alarmsJson,
    );
  }

  Future<void> addCustomFeeder(String id, String name) async {
    // Evita duplicatas
    if (_feeders.any((f) => f.id == id)) {
      return;
    }
    final topicPrefix = 'appetite/device/$id';
    final feeder = FeederModel(
      id: id,
      name: name,
      mqttTopicPrefix: topicPrefix,
    );
    _feeders.add(feeder);
    _service.subscribeToTopic('$topicPrefix/status');
    await _saveFeeders();
    notifyListeners();
  }

  Future<void> removeFeeder(FeederModel feeder) async {
    if (feeder.id == 'alimentador_01') return;
    _feeders.remove(feeder);
    if (_selectedFeeder?.id == feeder.id) {
      _selectedFeeder = null;
      _connectionState = FeederConnectionState.idle;
    }
    await _saveFeeders();
    notifyListeners();
  }

  Future<void> rediscoverFeeders() async {
    _discoverFeeders();
  }

  void deselectFeeder() {
    _selectedFeeder = null;
    _connectionState = FeederConnectionState.idle;
    notifyListeners();
  }

  String getStatusMessage() {
    if (_connectionState == FeederConnectionState.discovering) {
      return 'Buscando alimentadores...';
    }
    if (_selectedFeeder != null) {
      switch (_selectedFeeder!.status) {
        case FeederStatus.online:
          return '${_selectedFeeder!.name} — Online e Pronto';
        case FeederStatus.offline:
          return '${_selectedFeeder!.name} — Offline';
        case FeederStatus.unknown:
          return '${_selectedFeeder!.name} — Verificando...';
      }
    }
    return 'Selecione um alimentador';
  }

  Future<void> disconnect() async {
    _service.disconnect();
    _connectionState = FeederConnectionState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    for (final timer in _pingTimeouts.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
