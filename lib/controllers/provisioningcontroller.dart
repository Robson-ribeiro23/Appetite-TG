import 'package:flutter/material.dart';
import 'package:appetite/services/provisioningservice.dart';
import 'package:appetite/controllers/homecontroller.dart'; // Para tentar o MQTT no sucesso

enum ProvisioningState {
  initial,
  userConnectingToAp, // Usuário deve mudar o Wi-Fi
  sendingCredentials,
  waitingForWifiConnection, // ESP32 está tentando conectar ao Wi-Fi doméstico
  success,
  failure,
}

class ProvisioningController extends ChangeNotifier {
  final ProvisioningService _service = ProvisioningService();
  ProvisioningState _state = ProvisioningState.initial;
  String _message =
      'Bem-vindo! Para começar, prepare as credenciais do seu Wi-Fi doméstico.';

  // Referência ao HomeController (para disparar a conexão MQTT após o setup)
  final HomeController homeController;

  ProvisioningController({required this.homeController});

  ProvisioningState get state => _state;
  String get message => _message;

  // Nome da rede que o ESP32 deve criar (Deve ser igual ao ESP32!)
  static const String esp32ApName = 'Appetite_SETUP';

  void startSetup() {
    _state = ProvisioningState.userConnectingToAp;
    _message =
        '1. Desconecte o Wi-Fi atual e conecte-se à rede "$esp32ApName".';
    notifyListeners();
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    _state = ProvisioningState.sendingCredentials;
    _message =
        '2. Enviando credenciais do Wi-Fi doméstico para o dispositivo...';
    notifyListeners();

    bool success = await _service.sendCredentials(ssid, password);

    if (success) {
      _state = ProvisioningState.waitingForWifiConnection;
      _message =
          '3. Credenciais enviadas! Aguarde o dispositivo reiniciar e conectar à sua rede...';
      notifyListeners();

      // Simula o tempo que o ESP32 leva para reiniciar e conectar (10 segundos)
      await Future.delayed(const Duration(seconds: 10));

      _state = ProvisioningState.success;
      _message =
          'Configuração concluída! Voltando ao aplicativo e testando a conexão remota...';
      notifyListeners();

      // CRÍTICO: Tenta iniciar a conexão MQTT remota após o provisionamento
      homeController.attemptConnection();
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
