import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum MqttServiceStatus { disconnected, connecting, connected }

class MqttService {
  static const String brokerUrl =
      'a5be7b04667949908ba52635028c884d.s1.eu.hivemq.cloud';
  static const int port = 8883;

  final String clientIdentifier =
      'flutter_appetite_${Random().nextInt(100000)}';

  static const String username = 'appetite_admin';
  static const String password = 'Mkiujn123';

  late MqttServerClient _client;
  bool _isConnected = false;
  final Set<String> _subscribedTopics = {};

  // Stream de status da conexão (para reconexão automática)
  final StreamController<MqttServiceStatus> _statusController =
      StreamController<MqttServiceStatus>.broadcast();
  Stream<MqttServiceStatus> get statusStream => _statusController.stream;

  // Stream de mensagens do ESP32 — emite {topic, payload}
  final StreamController<Map<String, String>> _messageController =
      StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get messageStream => _messageController.stream;

  Timer? _reconnectTimer;
  static const Duration _reconnectInterval = Duration(seconds: 5);

  MqttService() {
    _client = MqttServerClient.withPort(brokerUrl, clientIdentifier, port);
    _setupClient();
  }

  void _setupClient() {
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.onBadCertificate = (dynamic cert) => true;

    _client.logging(on: kDebugMode);
    _client.keepAlivePeriod = 60;
    _client.setProtocolV311();

    final connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier(clientIdentifier)
        .startClean();

    _client.connectionMessage = connMess;
    _client.onDisconnected = () {
      _isConnected = false;
      _statusController.add(MqttServiceStatus.disconnected);
      if (kDebugMode) print('MQTT: Desconectado! Tentando reconectar...');
      _attemptReconnect();
    };
  }

  void _listenToUpdates() {
    _client.updates!.listen((dynamic c) {
      final MqttPublishMessage recMess = c[0].payload;

      if (recMess.header!.retain) {
        if (kDebugMode) print('MQTT: Mensagem retida ignorada.');
        return;
      }

      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _messageController.add({'topic': c[0].topic, 'payload': pt});
    });
  }

  /// Subscreve a um tópico arbitrário (ex: status de um alimentador)
  void subscribeToTopic(String topic) {
    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
      if (_isConnected) {
        _client.subscribe(topic, MqttQos.atLeastOnce);
      }
    }
  }

  /// Re-aplica subscrições após reconexão
  void _resubscribe() {
    for (final topic in _subscribedTopics) {
      _client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectInterval, (timer) async {
      if (_isConnected) {
        timer.cancel();
        return;
      }
      _statusController.add(MqttServiceStatus.connecting);
      bool success = await _reconnect();
      if (success) {
        timer.cancel();
      }
    });
  }

  Future<bool> _reconnect() async {
    try {
      if (kDebugMode) print('MQTT: Tentando reconectar...');
      await _client.connect();
    } catch (e) {
      return false;
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;
      _resubscribe();
      _listenToUpdates();
      _statusController.add(MqttServiceStatus.connected);
      if (kDebugMode) print('MQTT: Reconectado com sucesso!');
      return true;
    } else {
      _client.disconnect();
      return false;
    }
  }

  Future<bool> connectToBroker() async {
    if (_isConnected) return true;

    _statusController.add(MqttServiceStatus.connecting);

    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      _statusController.add(MqttServiceStatus.disconnected);
      return false;
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;
      _resubscribe();
      _listenToUpdates();
      _statusController.add(MqttServiceStatus.connected);
      return true;
    } else {
      _client.disconnect();
      _statusController.add(MqttServiceStatus.disconnected);
      return false;
    }
  }

  Future<bool> publishCommand({
    required String topic,
    required String payload,
  }) async {
    if (!_isConnected) {
      if (kDebugMode) {
        print('MQTT: Tentando reconectar antes de publicar...');
        _reconnectTimer?.cancel();
        bool success = await _reconnect();
        if (!success) return false;
      } else {
        return false;
      }
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      return true;
    } catch (e) {
      if (kDebugMode) print('MQTT: Erro ao publicar: $e');
      return false;
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _client.disconnect();
    _isConnected = false;
    _statusController.add(MqttServiceStatus.disconnected);
  }
}
