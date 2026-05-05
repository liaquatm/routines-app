import 'package:flutter/material.dart';
import 'navigation/main_nav_bar.dart';

/// The entry point of the entire application.
void main() {
  runApp(const MyApp());
}

/// MyApp is the root widget of your application.
/// It sets up the high-level configuration like the App Name, Theme, and Home Screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      
      // Hides the "Debug" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
      
      // Theme defines the global look and feel (colors, fonts, etc.)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // Uses the latest Android design standards.
      ),
      
      // The first screen the user sees when they open the app.
      // We point this to our navigation skeleton.
      home: const MainNavigationScreen(),
    );
  }
}
