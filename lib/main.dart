// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/services/notification_service.dart';
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';
import 'package:appetite/controllers/feedercontroller.dart';
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
        ChangeNotifierProvider(create: (_) => HistoryController()),
        ChangeNotifierProvider(create: (_) => FeederController()),

        // 2. HomeController depende de FeederController e HistoryController
        ChangeNotifierProxyProvider2<FeederController, HistoryController, HomeController>(
          create: (context) => HomeController(
            feederController: Provider.of<FeederController>(context, listen: false),
            historyController: Provider.of<HistoryController>(context, listen: false),
          ),
          update: (context, feederCtrl, historyCtrl, previousHomeCtrl) {
            return previousHomeCtrl ?? HomeController(
              feederController: feederCtrl,
              historyController: historyCtrl,
            );
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

        // 4. ProvisioningController depende de FeederController
        ChangeNotifierProxyProvider<FeederController, ProvisioningController>(
          create: (context) => ProvisioningController(
            feederController: Provider.of<FeederController>(context, listen: false),
          ),
          update: (context, feederCtrl, previousProvCtrl) {
            return previousProvCtrl ?? ProvisioningController(feederController: feederCtrl);
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

      theme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.light,
      ),

      darkTheme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.dark,
      ),

      themeMode: themeController.themeMode,

      home: const MainScreen(),
    );
  }
}
