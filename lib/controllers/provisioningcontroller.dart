import 'package:flutter/material.dart';
import 'package:appetite/services/provisioningservice.dart';
import 'package:appetite/controllers/feedercontroller.dart';

enum ProvisioningState {
  initial,
  userConnectingToAp,
  sendingCredentials,
  waitingForWifiConnection,
  success,
  failure,
}

class ProvisioningController extends ChangeNotifier {
  final ProvisioningService _service = ProvisioningService();
  ProvisioningState _state = ProvisioningState.initial;
  String _message =
      'Bem-vindo! Para começar, prepare as credenciais do seu Wi-Fi doméstico.';

  final FeederController feederController;

  String _feederName = 'Alimentador 01';

  ProvisioningController({required this.feederController});

  ProvisioningState get state => _state;
  String get message => _message;

  static const String esp32ApName = 'Appetite_SETUP';

  void startSetup(String name) {
    _feederName = name;
    _state = ProvisioningState.userConnectingToAp;
    _message =
        '1. Desconecte o Wi-Fi atual e conecte-se à rede "$esp32ApName".';
    notifyListeners();
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    _state = ProvisioningState.sendingCredentials;
    _message =
        '2. Enviando credenciais do Wi-Fi doméstico para o dispositivo ($_feederName)...';
    notifyListeners();

    bool success = await _service.sendCredentials(ssid, password);

    if (success) {
      _state = ProvisioningState.waitingForWifiConnection;
      _message =
          '3. Credenciais enviadas! Aguarde o dispositivo reiniciar e conectar à sua rede...';
      notifyListeners();

      await Future.delayed(const Duration(seconds: 10));

      _state = ProvisioningState.success;
      _message =
          'Configuração concluída! Voltando ao aplicativo e testando a conexão remota...';
      notifyListeners();

      // Re-descobre feeders após o provisionamento
      feederController.rediscoverFeeders();
    } else {
      _state = ProvisioningState.failure;
      _message =
          'Falha ao enviar credenciais. Verifique se o celular ainda está conectado à rede "$esp32ApName".';
      notifyListeners();
    }
  }

  void reset() {
    _state = ProvisioningState.initial;
    _message = 'Inicie a configuração novamente.';
    notifyListeners();
  }
}
