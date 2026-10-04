import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'models/app_notification.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/splash_screen.dart';
import 'services/calibration_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

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
  await SettingsService.init();
  await NotificationService.init();
  await CalibrationService.init();
  await ConnectivityService.init();
  await _removeDemoHistory();
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
      home: const SplashScreen(),
    );
  }
}

/// One-time removal of the demo results from before the server update.
Future<void> _removeDemoHistory() async {
  try {
    final removed = await StorageService.removeDemoHistory();
    if (removed > 0) {
      await NotificationService.add(
        type: AppNotificationType.info,
        title: 'Demo results removed',
        message: '$removed demo result${removed == 1 ? '' : 's'} from an '
            'earlier version were removed. New gradings come from the '
            'GemEye server.',
      );
    }
  } catch (e) {
    debugPrint('Demo history removal failed: $e');
  }
}
