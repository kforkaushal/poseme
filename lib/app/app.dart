import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/camera/camera_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import 'theme.dart';

class PoseMeApp extends ConsumerStatefulWidget {
  const PoseMeApp({super.key});

  @override
  ConsumerState<PoseMeApp> createState() => _PoseMeAppState();
}

class _PoseMeAppState extends ConsumerState<PoseMeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Pose Me!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const CameraScreen(),
    );
  }
}
