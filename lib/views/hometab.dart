import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/feedercontroller.dart';
import 'package:appetite/controllers/themecontroller.dart';
import '../views/widgets/provisioningscreen.dart';
import '../models/feedermodel.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _gramsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              'Sucesso!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _performManualFeed(HomeController controller) async {
    final gramsText = _gramsController.text;
    final grams = double.tryParse(gramsText);

    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, insira uma quantidade válida.')),
      );
      return;
    }

    if (controller.isConnected) {
      setState(() => _isLoading = true);

      bool success = await controller.manualFeed(grams);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _showSuccessDialog('Comando de $grams g enviado!');
        _gramsController.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar. Tente novamente.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo offline.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context);
    final feederController = Provider.of<FeederController>(context);
    final homeController = Provider.of<HomeController>(context);

    // Tela de carregamento: mostra spinner enquanto busca alimentadores
    bool shouldShowLoading = feederController.connectionState ==
            FeederConnectionState.discovering &&
        feederController.feeders.every((f) => f.status != FeederStatus.online);

    if (shouldShowLoading) {
      return _buildLoadingScreen(theme, themeController.primaryColor);
    }

    // Se tem selecionado e conectado → mostra tela de alimentação
    if (homeController.isConnected && feederController.selectedFeeder != null) {
      return _buildManualFeedView(
        context,
        theme,
        themeController,
        homeController,
        feederController,
      );
    }

    // Seleção de alimentadores
    return _buildFeederSelectionView(
      context,
      theme,
      themeController,
      homeController,
      feederController,
    );
  }

  Widget _buildLoadingScreen(ThemeData theme, Color themeColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Buscando alimentadores...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguardando resposta do servidor MQTT',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeederSelectionView(
    BuildContext context,
    ThemeData theme,
    ThemeController themeController,
    HomeController homeController,
    FeederController feederController,
  ) {
    final feeders = feederController.feeders;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: themeController.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeController.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeController.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.router,
                    color: themeController.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meus Alimentadores',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: themeController.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${feeders.length} alimentador(es) cadastrado(s)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => feederController.rediscoverFeeders(),
                  tooltip: 'Verificar novamente',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de feeders
          Expanded(
            child: feeders.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum alimentador cadastrado.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: feeders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final feeder = feeders[index];
                      final isSelected =
                          feederController.selectedFeeder?.id == feeder.id;
                      return _buildFeederCard(
                        feeder,
                        isSelected,
                        () {
                          feederController.selectFeeder(feeder);
                        },
                        () {
                          _showRemoveFeederDialog(feederController, feeder);
                        },
                        theme,
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Botões de ação
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProvisioningScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('CONFIGURAR NOVO ALIMENTADOR'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: themeController.primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeederCard(
    FeederModel feeder,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback onRemove,
    ThemeData theme,
  ) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (feeder.status) {
      case FeederStatus.online:
        statusColor = Colors.green;
        statusIcon = Icons.wifi_tethering;
        statusLabel = 'Online';
        break;
      case FeederStatus.offline:
        statusColor = Colors.red;
        statusIcon = Icons.wifi_off;
        statusLabel = 'Offline';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.sync;
        statusLabel = 'Verificando...';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.08)
              : theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? statusColor.withValues(alpha: 0.5)
                : statusColor.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Status indicator circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        feeder.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, size: 16, color: statusColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${feeder.id} • $statusLabel',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Visto: ${feeder.lastSeen}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            // Remove button (only for non-default)

            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: statusColor.withValues(alpha: 0.6), size: 20),
              onPressed: onRemove,
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFeederDialog(
    FeederController controller,
    FeederModel feeder,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover Alimentador'),
        content: Text('Deseja remover "${feeder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeFeeder(feeder);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFeedView(
    BuildContext context,
    ThemeData theme,
    ThemeController themeController,
    HomeController homeController,
    FeederController feederController,
  ) {
    final selectedFeeder = feederController.selectedFeeder!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connected status with selected feeder
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_tethering,
                        color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conectado',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          selectedFeeder.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão de voltar
                  TextButton.icon(
                    onPressed: () {
                      feederController.deselectFeeder();
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Trocar'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Manual feeding
            Text(
              'Alimentação Manual',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeController.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _gramsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade (gramas)',
                hintText: 'Ex: 50',
                suffixText: 'g',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_isLoading
                    ? () => _performManualFeed(homeController)
                    : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isLoading ? 'ENVIANDO...' : 'ALIMENTAR AGORA'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: themeController.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
