import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
//import 'dart:convert';

class ProvisioningService {
  // Endereço fixo do ESP32 quando está no modo Access Point (SoftAP)
  static const String apUrl = 'http://192.168.4.1/config';

  /// Envia o SSID e a senha do Wi-Fi doméstico do usuário para o ESP32.
  Future<bool> sendCredentials(
      String ssid, String password, String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse(apUrl),
        // O corpo da requisição deve corresponder ao que o ESP32 espera (chave/valor)
        body: {
          'ssid': ssid,
          'password': password,
          'id': deviceId,
        },
      );

      // O ESP32 deve retornar um status 200 (OK) se receber as credenciais.
      if (response.statusCode == 200 &&
          response.body.contains("Credenciais recebidas")) {
        return true;
      } else {
        // Log detalhado de falha de comunicação
        debugPrint(
            "Provisioning Failure: Status ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      // Falha de rede: geralmente significa que o celular não está conectado ao AP do ESP32
      debugPrint(
          "Provisioning Error: Celular não conectado ao AP do ESP32 (192.168.4.1 inacessível). Erro: $e");
      return false;
    }
  }
}
