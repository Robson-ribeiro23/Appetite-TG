import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';
import 'package:appetite/controllers/feedercontroller.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndStart() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o ID e nome do alimentador.')),
      );
      return;
    }

    // Cadastra automaticamente no FeederController
    final fc = Provider.of<FeederController>(context, listen: false);
    fc.addCustomFeeder(id, name);

    // Auto-seleciona o alimentador configurado
    final feeders = fc.feeders;
    final feeder = feeders.isNotEmpty ? feeders.last : null;
    if (feeder != null && feeder.id == id) {
      fc.selectFeeder(feeder);
    }

    // Inicia provisioning
    if (mounted) {
      Provider.of<ProvisioningController>(context, listen: false)
          .startSetup(id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    _buildStatusIcon(context, controller.state),
                    const SizedBox(height: 24),
                    Text(
                      controller.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Formulário de ID/nome do alimentador (antes de começar)
                    if (controller.state == ProvisioningState.initial) ...[
                      Text(
                        'Identifique seu alimentador:',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'ID do dispositivo',
                          hintText: 'Ex: alimentador_02',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome de exibição',
                          hintText: 'Ex: Cozinha',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _confirmAndStart,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                        child: const Text(
                          'INICIAR',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    // Botão que inicia o processo (sem form, já tem ID/nome)
                    if (controller.state == ProvisioningState.initial)
                      const SizedBox.shrink(),

                    // Formulário de credenciais
                    if (controller.state ==
                            ProvisioningState.userConnectingToAp ||
                        controller.state ==
                            ProvisioningState.sendingCredentials ||
                        controller.state == ProvisioningState.failure)
                      _BuildCredentialForm(controller: controller),

                    // Indicador de carregamento
                    if (controller.state ==
                            ProvisioningState.sendingCredentials ||
                        controller.state ==
                            ProvisioningState.waitingForWifiConnection)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    // Volta à tela principal após sucesso
                    if (controller.state == ProvisioningState.success)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'SETUP CONCLUÍDO!',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Botão de "Tentar Novamente"
                    if (controller.state == ProvisioningState.failure)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: controller.reset,
                          child:
                              const Text('Tentar Novamente (Reiniciar Setup)'),
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }
}

// --- Formulário de Credenciais Wi-Fi ---

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
    if (widget.controller.state == ProvisioningState.initial ||
        widget.controller.state == ProvisioningState.success ||
        widget.controller.state == ProvisioningState.waitingForWifiConnection) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
          ),
          child: Text(
            'Conecte-se à Rede: ${ProvisioningController.esp32ApName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Insira as credenciais do seu Wi-Fi doméstico:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ssidController,
          decoration: const InputDecoration(
            labelText: 'SSID (Nome da Rede)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Senha do Wi-Fi',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon:
                  Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          obscureText: _obscureText,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed:
              widget.controller.state == ProvisioningState.sendingCredentials
                  ? null
                  : () {
                      if (_ssidController.text.isEmpty ||
                          _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Preencha o SSID e a senha.')),
                        );
                        return;
                      }
                      widget.controller.sendWifiCredentials(
                        _ssidController.text,
                        _passwordController.text,
                      );
                    },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
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
