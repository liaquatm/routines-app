import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_habits_screen.dart';
import 'manage_reminders_screen.dart';

class ManageResourcesScreen extends StatelessWidget {
  const ManageResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Manage',
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Habits'),
              Tab(text: 'Reminders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ManageHabitsView(),
            ManageRemindersView(),
          ],
        ),
      ),
    );
  }
}

class ManageHabitsView extends StatefulWidget {
  const ManageHabitsView({super.key});

  @override
  State<ManageHabitsView> createState() => _ManageHabitsViewState();
}

class _ManageHabitsViewState extends State<ManageHabitsView> {
  // We can pull the logic from ManageHabitsScreen here, 
  // but it's cleaner to keep them separate.
  // For now I'll just use the existing screens but modified to be Views.
  @override
  Widget build(BuildContext context) {
    return const ManageHabitsScreen(isViewOnly: true);
  }
}

class ManageRemindersView extends StatefulWidget {
  const ManageRemindersView({super.key});

  @override
  State<ManageRemindersView> createState() => _ManageRemindersViewState();
}

class _ManageRemindersViewState extends State<ManageRemindersView> {
  @override
  Widget build(BuildContext context) {
    return const ManageRemindersScreen(isViewOnly: true);
  }
}
