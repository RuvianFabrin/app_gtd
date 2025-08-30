import 'package:awesome_notifications/awesome_notifications.dart'; // NOVO
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'data/repo.dart';
import 'logic/gtd_service.dart';
import 'logic/notif_service.dart';
import 'ui/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MODIFICADO: Inicializa o novo serviço de notificações
  final notificationService = NotificationService();
  await notificationService.init();

  final gtdRepository = GtdRepository();
  final gtdService = GtdService(gtdRepository, notificationService);

  await gtdService.loadAllData();

  runApp(
    ChangeNotifierProvider(
      create: (context) => gtdService,
      child: const GtdApp(),
    ),
  );
}

class GtdApp extends StatelessWidget {
  const GtdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTD+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'),
      ],
    );
  }
}
