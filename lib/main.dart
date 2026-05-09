import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navigation/main_nav_bar.dart';
import 'services/notification_service.dart';
import 'services/google_drive_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Only perform the backup if it's the nightly_backup task
    if (task == "nightly_backup") {
      final driveService = GoogleDriveService.instance;
      await driveService.uploadBackup();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Initialize Workmanager for background backups
  await Workmanager().initialize(
    callbackDispatcher,
  );

  // Schedule a periodic nightly backup (once every 24 hours)
  await Workmanager().registerPeriodicTask(
    "1",
    "nightly_backup",
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
