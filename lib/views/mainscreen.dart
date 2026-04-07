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

  // Título do AppBar para cada aba
  final List<String> _titles = [
    'Appetite - Conexão',
    'Appetite - Alarmes',
    'Appetite - Histórico',
    'Appetite - Configurações',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CORREÇÃO DE OVERFLOW NA APPBAR ---
      // Envolvemos a AppBar em um MediaQuery para travar a escala da fonte em 1.0.
      // Isso impede que o título cresça demais e quebre o layout da barra superior.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: AppBar(
            title: Text(_titles[_selectedIndex]),
            centerTitle: true,
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
