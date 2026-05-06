import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/habit.dart';
import '../../../services/habit_service.dart';
import 'add_habit_screen.dart';

class ManageHabitsScreen extends StatefulWidget {
  const ManageHabitsScreen({super.key});

  @override
  State<ManageHabitsScreen> createState() => _ManageHabitsScreenState();
}

class _ManageHabitsScreenState extends State<ManageHabitsScreen> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.loadHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  void _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('Are you sure you want to delete "${habit.name}"? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _habitService.deleteHabit(habit.id);
      setState(() {
        _habits.removeWhere((h) => h.id == habit.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${habit.name} deleted')),
        );
      }
    }
  }

  void _editHabit(Habit habit) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitScreen(habitToEdit: habit),
    );

    if (result != null && result is Habit) {
      await _habitService.updateHabit(result);
      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Manage Habits', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(child: Text('No habits to manage.', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(habit.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(habit.name, style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          habit.frequencyType == FrequencyType.fixed
                              ? 'Fixed Days'
                              : 'Flexible: ${habit.flexibleCount}x / week',
                          style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                              onPressed: () => _editHabit(habit),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteHabit(habit),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
