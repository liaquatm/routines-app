import 'package:flutter/material.dart';
import '../../../models/habit.dart';
import '../../../services/habit_service.dart';
import 'add_habit_screen.dart';

/// The main dashboard for tracking habits.
/// This screen displays the list of habits and allows the user to toggle completion.
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  // Connection to our persistence service.
  final HabitService _habitService = HabitService();
  
  // The actual list of habits we are displaying.
  List<Habit> _habits = [];
  
  // Used to show a loading spinner while data is being fetched.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits(); // Load saved habits as soon as the screen starts.
  }

  /// Fetches saved habits from the phone's memory.
  Future<void> _loadHabits() async {
    final habits = await _habitService.loadHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  // Marks a habit as done for today and saves the change.
  void _toggleHabit(int index) async {
    final habit = _habits[index];
    final isCurrentlyCompleted = habit.isCompletedToday();
    final today = DateTime.now();

    setState(() {
      habit.toggleToday();
    });

    // Surgical Database Update:
    if (isCurrentlyCompleted) {
      // If it was already done, we remove just that one date log.
      await _habitService.removeCompletion(habit.id, today);
    } else {
      // If it's new, we just insert one new date log row.
      await _habitService.logCompletion(habit.id, today);
    }
    print("Database surgically updated!");
  }

  /// Opens the "Add Habit" overlay and waits for the user to finish.
  Future<void> _navigateToAddHabit() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => const AddHabitScreen(),
    );

    if (result != null && result is Habit) {
      setState(() {
        _habits.add(result);
      });
      // Save ONLY the new habit definition to the database.
      await _habitService.addHabit(result);
      print("New habit definition saved to SQL!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      
      // Show a spinner if loading, a message if empty, or the list of habits.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(child: Text('No habits yet. Tap + to start!'))
              : ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final isCompleted = habit.isCompletedToday();

                    return ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: Color(habit.colorValue),
                      ),
                      title: Text(
                        habit.name,
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: isCompleted ? Colors.grey : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: habit.description != null && habit.description!.isNotEmpty
                          ? Text(habit.description!)
                          : null,
                      trailing: Checkbox(
                        value: isCompleted,
                        onChanged: (bool? value) => _toggleHabit(index),
                      ),
                      onTap: () => _toggleHabit(index),
                    );
                  },
                ),
                
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabit,
        tooltip: 'Add Habit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
