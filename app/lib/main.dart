import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/maintenance_screen.dart';
import 'screens/splash_screen.dart';
import 'services/calibration_service.dart';
import 'services/connectivity_service.dart';
import 'services/device_id_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'services/settings_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'widgets/calibration_reset_prompt.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppSystemUi.darkIcons);
  await AppConfig.load();
  await DeviceIdService.init();
  await SettingsService.init();
  await NotificationService.init();
  await CalibrationService.init();
  await ConnectivityService.init();
  ApiClient.sessionLostHandler = AuthService.handleDeadSession;
  CalibrationResetPrompt.watchResume();
  unawaited(RemoteConfigService.refresh());
  FlutterNativeSplash.remove();
  runApp(const GemEyeApp());
}

class GemEyeApp extends StatelessWidget {
  const GemEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GemEye',
      debugShowCheckedModeBanner: false,
      theme: GemEyeTheme.lightTheme,
      navigatorKey: AppRoutes.navigatorKey,
      navigatorObservers: [AppRoutes.routeObserver],
      // Remote config maintenance.enabled covers every screen.
      builder: (context, child) =>
          MaintenanceGate(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}
