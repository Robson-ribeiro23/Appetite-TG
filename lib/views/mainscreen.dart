// lib/views/main_screen.dart
import 'package:flutter/material.dart';
import 'package:appetite/views/widgets/bottomnavbar.dart';
import 'hometab.dart';
import 'historytab.dart';
import 'settingstab.dart';
import 'alarmtab/alarmlistview.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Começa na aba 'Alarmes' (índice 1)

  // Lista dos widgets de cada aba
  final List<Widget> _tabs = [
    const HomeTab(), // 0: Home (Conexão ESP32)
    const AlarmListView(), // 1: Alarmes
    const HistoryTab(), // 2: Histórico
    const SettingsTab(), // 3: Configurações
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAppBarTitle(int index) {
    final theme = Theme.of(context);

    switch (index) {
      case 0: // Conexão
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Appetite',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      case 1: // Alarmes
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_on, size: 20),
            const SizedBox(width: 8),
            Text(
              'Alarmes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      case 2: // Histórico
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 20),
            const SizedBox(width: 8),
            Text(
              'Histórico',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      case 3: // Configurações
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, size: 20),
            const SizedBox(width: 8),
            Text(
              'Configurações',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      default:
        return const Text('Appetite');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elevation = _selectedIndex == 0 ? 2.0 : 0.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: AppBar(
            title: _buildAppBarTitle(_selectedIndex),
            centerTitle: true,
            elevation: elevation,
            shadowColor: theme.primaryColor.withValues(alpha: 0.3),
            surfaceTintColor: Colors.transparent,
          ),
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),

      // A barra de navegação inferior
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
