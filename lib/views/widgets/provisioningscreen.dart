import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';

class ProvisioningScreen extends StatelessWidget {
  const ProvisioningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Consumer porque esta tela depende 100% do ProvisioningController
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Inicial do Wi-Fi')),
      body: Consumer<ProvisioningController>(
        builder: (context, controller, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícone de Status Dinâmico
                    _buildStatusIcon(context, controller.state),
                    const SizedBox(height: 24),
                    
                    // Texto de instrução amigável
                    Text(
                      controller.message, // Mensagem vinda do Controller
                      textAlign: TextAlign.center, 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, height: 1.5)
                    ),
                    const SizedBox(height: 40),

                    // Botão principal que inicia o processo
                    if (controller.state == ProvisioningState.initial)
                      ElevatedButton(
                        onPressed: controller.startSetup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black
                        ),
                        child: const Text('INICIAR CONFIGURAÇÃO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                    // Formulário de credenciais
                    if (controller.state == ProvisioningState.userConnectingToAp ||
                        controller.state == ProvisioningState.sendingCredentials ||
                        controller.state == ProvisioningState.failure)
                      _BuildCredentialForm(controller: controller),

                    // Indicador de carregamento
                    if (controller.state == ProvisioningState.sendingCredentials ||
                        controller.state == ProvisioningState.waitingForWifiConnection)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    // Volta à tela principal após sucesso
                    if (controller.state == ProvisioningState.success)
                      ElevatedButton(
                        onPressed: () {
                          // Fecha esta tela e volta para a HomeTab
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('SETUP CONCLUÍDO!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    
                    // Botão de "Tentar Novamente" em caso de falha
                    if (controller.state == ProvisioningState.failure)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: controller.reset,
                          child: const Text('Tentar Novamente (Reiniciar Setup)'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET: Ícone de Status Amigável
  Widget _buildStatusIcon(BuildContext context, ProvisioningState state) {
    IconData icon;
    Color color;

    switch (state) {
      case ProvisioningState.initial:
        icon = Icons.wifi_find_rounded;
        color = Colors.grey;
        break;
      case ProvisioningState.userConnectingToAp:
        icon = Icons.tap_and_play_rounded;
        color = Theme.of(context).primaryColor;
        break;
      case ProvisioningState.sendingCredentials:
      case ProvisioningState.waitingForWifiConnection:
        icon = Icons.settings_ethernet_rounded;
        color = Colors.orange;
        break;
      case ProvisioningState.failure:
        icon = Icons.wifi_off_rounded;
        color = Colors.red;
        break;
      case ProvisioningState.success:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2)
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }
}

// --- WIDGET: Formulário de Credenciais ---

class _BuildCredentialForm extends StatefulWidget {
  final ProvisioningController controller;
  const _BuildCredentialForm({required this.controller});

  @override
  State<_BuildCredentialForm> createState() => __BuildCredentialFormState();
}

class __BuildCredentialFormState extends State<_BuildCredentialForm> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Não mostra o formulário se o estado não for o correto
    if (widget.controller.state == ProvisioningState.initial || 
        widget.controller.state == ProvisioningState.success ||
        widget.controller.state == ProvisioningState.waitingForWifiConnection) {
      return const SizedBox.shrink(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Banner para a rede do ESP32
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700)
          ),
          child: Text(
            'Conecte-se à Rede: ${ProvisioningController.esp32ApName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Agora, insira as credenciais do seu Wi-Fi doméstico:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Campo de Texto para SSID
        TextField(
          controller: _ssidController,
          decoration: const InputDecoration(
            labelText: 'Seu SSID (Nome da Rede)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wifi),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        
        // Campo de Texto para Senha
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Senha do Wi-Fi',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          obscureText: _obscureText,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),

        // Botão de Enviar
        ElevatedButton(
          onPressed: widget.controller.state == ProvisioningState.sendingCredentials
              ? null // Desabilita o botão enquanto envia
              : () {
                  // Validação simples
                  if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha o SSID e a senha.')),
                    );
                    return;
                  }
                  // Chama o Controller para enviar
                  widget.controller.sendWifiCredentials(
                    _ssidController.text,
                    _passwordController.text,
                  );
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.black,
          ),
          child: Text(
            widget.controller.state == ProvisioningState.sendingCredentials
                ? 'ENVIANDO...'
                : 'ENVIAR CREDENCIAIS',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}