import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/constants.dart';
import 'services/permission_service.dart';
import 'services/background_service.dart';
import 'services/call_service.dart';
import 'services/audio_service.dart';
import 'services/call_recording_service.dart';
import 'services/recording_mode_service.dart';
import 'providers/app_state_provider.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'callMonitoring':
        await BackgroundService.instance.monitorCalls();
        break;
      case 'audioProcessing':
        await BackgroundService.instance.processAudioChunk(inputData?['audioPath']);
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  await PermissionService.instance.requestAllPermissions();
  
  await CallService.instance.initialize();
  await AudioService.instance.initialize();
  await CallRecordingService.instance.initialize();

  // Initialize recording mode service
  await RecordingModeService.instance.setMode(RecordingMode.manual);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    ProviderScope(
      child: SCAIApp(),
    ),
  );
}

class SCAIApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}