import 'package:flutter/material.dart';
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
      // The body displays the screen corresponding to the selected index.
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Budget',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
