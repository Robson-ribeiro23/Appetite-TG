// lib/views/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- CORREÇÃO DE OVERFLOW ---
    // Envolvemos a barra em um MediaQuery para forçar a escala da fonte a ser 1.0 (normal).
    // Isso impede que os rótulos cresçam e quebrem o layout fixo da barra,
    // mesmo que o usuário aumente a fonte nas configurações globais.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0), 
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.router), // Ícone do ESP32/Home
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        currentIndex: selectedIndex,
        
        // Usa as cores do tema atual
        selectedItemColor: Theme.of(context).primaryColor, 
        unselectedItemColor: Colors.grey,
        
        onTap: onItemSelected,
        type: BottomNavigationBarType.fixed, // Garante que todos os itens aparecem
        
        // Ajuste visual: usa a cor de fundo do tema para ficar harmônico (Preto no Dark, Branco no Light)
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black 
            : Colors.white,
        
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}