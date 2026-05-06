import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/habits/screens/habit_tracker_screen.dart';
import '../features/workouts/screens/workout_planning_screen.dart';
import '../features/budget/screens/budget_tracker_screen.dart';

/// The MainNavigationScreen is the "Skeleton" of the app.
/// It holds the Bottom Navigation Bar and decides which screen to show.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Tracks which tab is currently selected (0, 1, or 2).
  int _selectedIndex = 0;

  // A list of the different pages in our app.
  final List<Widget> _screens = [
    const HabitTrackerScreen(),
    const WorkoutPlanningScreen(),
    const BudgetTrackerScreen(),
  ];

  /// Changes the visible screen when a user taps a navigation icon.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_rounded),
              activeIcon: Icon(Icons.check_circle_rounded),
              label: 'Habits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              activeIcon: Icon(Icons.fitness_center_rounded),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Budget',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
