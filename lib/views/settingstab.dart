// lib/views/settingstab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
// Removi o import 'appcolors.dart' que não estava sendo usado

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _performFactoryReset(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Aplicativo?'),
        content: const Text(
            'Isso apagará todos os alarmes, histórico e configurações de tema.\n\nEssa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESETAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Provider.of<ThemeController>(context, listen: false).resetToDefaults();
      // Agora este método existe no AlarmController!
      Provider.of<AlarmController>(context, listen: false).resetToDefaults();
      Provider.of<HistoryController>(context, listen: false).resetToDefaults();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplicativo restaurado para as configurações de fábrica.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Personalização',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),

        // 1. MODO ESCURO / CLARO
        SwitchListTile(
          title: Text('Modo Escuro', style: theme.textTheme.titleMedium),
          value: themeController.isDarkMode,
          onChanged: (val) => themeController.toggleTheme(val),
          // CORREÇÃO: Removido activeColor obsoleto. O switch usará a cor do tema.
          // Se quiser forçar a cor, use activeTrackColor ou activeThumbColor.
          // Mas deixar padrão é mais seguro e bonito.
          secondary: Icon(
            themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: themeController.primaryColor,
          ),
        ),

        // 2. COR DO TEMA
        ListTile(
          leading: Icon(Icons.color_lens, color: theme.primaryColor),
          title: Text('Cor Principal', style: theme.textTheme.titleMedium),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: themeController.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 1),
            ),
          ),
          onTap: () => _showColorPickerDialog(context, themeController),
        ),

        // 3. TAMANHO DA FONTE
        ListTile(
          leading: Icon(Icons.text_fields, color: theme.primaryColor),
          title: Text('Tamanho do Texto', style: theme.textTheme.titleMedium),
          subtitle: Slider(
            value: themeController.fontSizeFactor,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: themeController.fontSizeFactor.toStringAsFixed(1),
            onChanged: (double value) {
              themeController.setFontSizeFactor(value);
            },
            activeColor: theme.primaryColor,
          ),
        ),

        const SizedBox(height: 30),

        // --- ZONA DE PERIGO (RESET) ---
        Text(
          'Gerenciamento',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),

        ListTile(
          leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
          title: Text(
            'Resetar Dados de Fábrica',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold
            ),
          ),
          subtitle: Text(
            'Apaga alarmes, histórico e configurações.',
            style: theme.textTheme.bodySmall,
          ),
          onTap: () => _performFactoryReset(context),
        ),
      ],
    );
  }

  void _showColorPickerDialog(BuildContext context, ThemeController controller) {
    Color pickerColor = controller.primaryColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione a Cor'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('SALVAR'),
            onPressed: () {
              controller.setPrimaryColor(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}