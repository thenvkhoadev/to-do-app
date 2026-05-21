import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexus AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: NexusColors.primary,
          onPrimary: NexusColors.onPrimary,
          primaryContainer: NexusColors.primaryContainer,
          secondary: NexusColors.secondary,
          secondaryContainer: NexusColors.secondaryContainer,
          tertiary: NexusColors.tertiary,
          surface: NexusColors.surface,
          onSurface: NexusColors.onSurface,
          surfaceContainerHighest: NexusColors.surfaceContainerHighest,
          outline: NexusColors.outline,
        ),
        scaffoldBackgroundColor: NexusColors.background,
        fontFamily: 'Inter',
      ),
      home: const Home(),
    );
  }
}
