// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/services/notification_service.dart';
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';
import 'package:appetite/core/theme/apptheme.dart';
import 'package:appetite/views/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        // 1. Controllers Independentes
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => HistoryController()), // O Histórico nasce aqui

        // 2. HomeController agora depende de HistoryController
        ChangeNotifierProxyProvider<HistoryController, HomeController>(
          create: (context) => HomeController(
            historyController: Provider.of<HistoryController>(context, listen: false),
          ),
          update: (context, historyCtrl, previousHomeCtrl) {
            // Se já existir, mantemos; se não, cria um novo passando o histórico
            return previousHomeCtrl ?? HomeController(historyController: historyCtrl);
          },
        ),

        // 3. AlarmController depende de Home e History
        ChangeNotifierProxyProvider2<HomeController, HistoryController, AlarmController>(
          create: (context) => AlarmController(
            homeController: Provider.of<HomeController>(context, listen: false),
            historyController: Provider.of<HistoryController>(context, listen: false),
          ),
          update: (context, homeCtrl, historyCtrl, previousAlarmCtrl) {
            return previousAlarmCtrl ?? AlarmController(
              homeController: homeCtrl,
              historyController: historyCtrl,
            );
          },
        ),

        // 4. ProvisioningController depende de Home
        ChangeNotifierProxyProvider<HomeController, ProvisioningController>(
          create: (context) => ProvisioningController(
            homeController: Provider.of<HomeController>(context, listen: false),
          ),
          update: (context, homeCtrl, previousProvCtrl) {
            return previousProvCtrl ?? ProvisioningController(homeController: homeCtrl);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    
    return MaterialApp(
      title: 'Appetite',
      debugShowCheckedModeBanner: false,
      
      // Tema Claro
      theme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.light,
      ),
      
      // Tema Escuro
      darkTheme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.dark,
      ),
      
      // O controlador decide qual usar
      themeMode: themeController.themeMode,
      
      home: const MainScreen(),
    );
  }
}