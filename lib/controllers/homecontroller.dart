import 'package:flutter/material.dart';
import 'package:appetite/controllers/feedercontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';

class HomeController extends ChangeNotifier {
  final FeederController feederController;
  final HistoryController historyController;

  String _message = '';

  String get message => _message.isNotEmpty
      ? _message
      : feederController.getStatusMessage();

  bool get isConnected => feederController.isConnected;

  HomeController({
    required this.feederController,
    required this.historyController,
  });

  Future<bool> manualFeed(double grams, {bool isMaintenance = false}) async {
    if (!feederController.isConnected) return false;
    _message = 'Enviando comando...';
    notifyListeners();

    final payload = '{"grams": ${grams.toStringAsFixed(1)}}';
    bool success = await feederController.sendCommand(payload);

    if (success) {
      _message = isMaintenance ? 'Manutenção enviada!' : 'Comando enviado!';
      historyController.addEntry(
        type: HistoryType.manual,
        description: isMaintenance
            ? 'Manutenção: Preenchimento.'
            : 'Alimentação manual de ${grams.toStringAsFixed(1)}g.',
        gramsDispensed: grams,
        feederId: feederController.selectedFeeder?.id,
      );
    } else {
      _message = 'Falha ao publicar comando.';
    }
    notifyListeners();
    return success;
  }

  void fillTube() => manualFeed(34.0, isMaintenance: true);

  Future<void> sendAlarmConfiguration(String alarmsJson) async {
    if (!feederController.isConnected) return;
    final feeder = feederController.selectedFeeder;
    if (feeder == null) return;

    final success = await feederController.sendAlarmConfiguration(alarmsJson);
    _message = success
        ? 'Alarmes sincronizados com a Nuvem.'
        : 'Erro ao sincronizar alarmes.';
    notifyListeners();
  }

  void resetMessage() {
    _message = '';
    notifyListeners();
  }
}
