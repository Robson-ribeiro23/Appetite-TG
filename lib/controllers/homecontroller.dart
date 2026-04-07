import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appetite/services/mqtt_service.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  final MqttService _service = MqttService();
  final HistoryController historyController;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar";

  ConnectionStatus get status => _status;
  String get message => _message;

  StreamSubscription? _statusSubscription;
  StreamSubscription? _mqttStatusSub;
  Timer? _pingTimeoutTimer;

  HomeController({required this.historyController}) {
    // Monitora mudanças de status do MQTT (inclui reconexão automática)
    _mqttStatusSub = _service.statusStream.listen((status) {
      switch (status) {
        case MqttServiceStatus.connected:
          // Se já estava conectado, não muda nada (reconexão silenciosa)
          break;
        case MqttServiceStatus.connecting:
          _status = ConnectionStatus.connecting;
          _message = "Reconectando...";
          notifyListeners();
          break;
        case MqttServiceStatus.disconnected:
          _status = ConnectionStatus.error;
          _message = "Conexão perdida. Reconectando automaticamente...";
          notifyListeners();
          break;
      }
    });

    // Fica escutando o "PONG" do ESP32
    _statusSubscription = _service.messageStream.listen((payload) {
      if (payload.contains("online") ||
          payload.contains("alimentando") ||
          payload.contains("sucesso") ||
          payload.contains("alarmes")) {
        if (_status != ConnectionStatus.connected) {
          _status = ConnectionStatus.connected;
          _message = "Alimentador Online e Pronto";
          _pingTimeoutTimer?.cancel();
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _mqttStatusSub?.cancel();
    _pingTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> attemptConnection() async {
    if (_status == ConnectionStatus.connecting) return;

    _status = ConnectionStatus.connecting;
    _message = "Conectando ao servidor MQTT...";
    notifyListeners();

    bool success = await _service.connectToBroker();

    if (success) {
      _message = "Buscando o Alimentador...";
      notifyListeners();

      // Envia o PING (Pergunta se o ESP32 está vivo)
      await _service.publishCommand('manual', '{"ping": true}');

      // Espera 4 segundos. Se a Stream lá de cima não trocar para 'connected', offline!
      _pingTimeoutTimer = Timer(const Duration(seconds: 4), () {
        if (_status != ConnectionStatus.connected) {
          _status = ConnectionStatus.error;
          _message = "Alimentador Offline. Conecte-o à rede.";
          notifyListeners();
        }
      });
    } else {
      _status = ConnectionStatus.error;
      _message = "Falha ao acessar o servidor na nuvem.";
      notifyListeners();
    }
  }

  Future<bool> manualFeed(double grams, {bool isMaintenance = false}) async {
    if (_status != ConnectionStatus.connected) return false;
    _message = "Enviando comando via MQTT...";
    notifyListeners();

    final payload = '{"grams": ${grams.toStringAsFixed(1)}}';
    bool success = await _service.publishCommand('manual', payload);

    if (success) {
      _message = isMaintenance
          ? "Manutenção enviada!"
          : "Comando enviado para a nuvem!";
      historyController.addEntry(
        type: HistoryType.manual,
        description: isMaintenance
            ? "Manutenção: Preenchimento."
            : "Alimentação manual de ${grams.toStringAsFixed(1)}g.",
        gramsDispensed: grams,
      );
    } else {
      _message = "Falha ao publicar comando.";
    }
    notifyListeners();
    return success;
  }

  void fillTube() => manualFeed(34.0, isMaintenance: true);

  Future<void> sendAlarmConfiguration(String alarmsJson) async {
    if (_status != ConnectionStatus.connected) return;
    bool success = await _service.publishCommand('alarme', alarmsJson);
    _message = success
        ? "Alarmes sincronizados com a Nuvem."
        : "Erro ao sincronizar alarmes.";
    notifyListeners();
  }

  void disconnect() {
    _service.disconnect();
    _status = ConnectionStatus.disconnected;
    _message = "Desconectado.";
    notifyListeners();
  }
}
