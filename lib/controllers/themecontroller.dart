// lib/controllers/themecontroller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  Color _primaryColor = Colors.blue;
  double _fontSizeFactor = 1.0;
  
  // Novo controle de Tema
  ThemeMode _themeMode = ThemeMode.dark; // Começa escuro por padrão

  ThemeController() {
    _loadSettings(); // Carrega as configurações assim que o controller é criado
  }

  Color get primaryColor => _primaryColor;
  double get fontSizeFactor => _fontSizeFactor;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // --- MÉTODOS DE PERSISTÊNCIA ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Carregar Tamanho da Fonte
    _fontSizeFactor = 1.0; // prefs.getDouble('fontSizeFactor') ?? 1.0;

    // 2. Carregar Tema (Claro/Escuro)
    bool isDark = prefs.getBool('isDark') ?? true; // Padrão é true (escuro)
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // 3. Carregar Cor Principal (Salvo como inteiro ARGB)
    int? colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    
    notifyListeners(); // Atualiza a UI com os valores carregados
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeFactor', _fontSizeFactor);
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    await prefs.setInt('primaryColor', _primaryColor.toARGB32());
  }

  // --- MÉTODOS DE AÇÃO (Atualizam e Salvam) ---

  void setPrimaryColor(Color newColor) {
    _primaryColor = newColor;
    _saveSettings(); // Salva no disco
    notifyListeners();
  }
  
  void setFontSizeFactor(double newFactor) {
    _fontSizeFactor = newFactor;
    _saveSettings(); // Salva no disco
    notifyListeners();
  }

  // Alternar entre Claro e Escuro
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveSettings(); // Salva no disco
    notifyListeners();
  }

  void resetToDefaults() {
    _primaryColor = Colors.blue;
    _fontSizeFactor = 1.0;
    _themeMode = ThemeMode.dark;
    notifyListeners(); // Atualiza a tela imediatamente
  }
  
}