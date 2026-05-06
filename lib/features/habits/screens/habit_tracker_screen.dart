import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/habit.dart';
import '../../../services/habit_service.dart';
import 'add_habit_screen.dart';
import 'manage_habits_screen.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;

  // Track the selected date for horizontal navigation
  late PageController _pageController;
  final int _initialPage = 1000;
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadHabits();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.loadHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  DateTime _getDateForPage(int page) {
    return DateTime.now().add(Duration(days: page - _initialPage));
  }

  void _toggleHabit(Habit habit, DateTime date) async {
    final isCurrentlyCompleted = habit.isCompletedOn(date);

    setState(() {
      habit.toggleOn(date);
    });

    if (isCurrentlyCompleted) {
      await _habitService.removeCompletion(habit.id, date);
    } else {
      await _habitService.logCompletion(habit.id, date);
    }
  }

  Future<void> _navigateToAddHabit() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitScreen(),
    );

    if (result != null && result is Habit) {
      await _habitService.addHabit(result);
      _loadHabits();
    }
  }

  void _navigateToManageHabits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageHabitsScreen()),
    );
    _loadHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark theme
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'HabitTracker',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
            onPressed: _navigateToManageHabits,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final date = _getDateForPage(index);
                return _buildHabitPage(date);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabit,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHabitPage(DateTime date) {
    final weekday = date.weekday;
    final filtered = _habits.where((h) {
      if (h.frequencyType == FrequencyType.fixed) {
        return h.fixedDays?.contains(weekday) ?? false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM d').format(date),
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('EEEE').format(date),
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Habit List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildHabitCard(filtered[index], date);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(Habit habit, DateTime date) {
    final isCompleted = habit.isCompletedOn(date);
    final habitColor = Color(habit.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? habitColor.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: habitColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(habit.iconName),
            color: habitColor,
            size: 24,
          ),
        ),
        title: Text(
          habit.name,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.white38 : Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: isCompleted
            ? Text(
                'Completed!',
                style: GoogleFonts.lexend(color: habitColor, fontSize: 13),
              )
            : Text(
                habit.frequencyType == FrequencyType.fixed ? 'Daily Goal' : 'Flex Goal',
                style: GoogleFonts.lexend(color: Colors.white38, fontSize: 13),
              ),
        trailing: GestureDetector(
          onTap: () => _toggleHabit(habit, date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCompleted ? habitColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? habitColor : Colors.white24,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.black, size: 20)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'A fresh start today!',
            style: GoogleFonts.lexend(
              fontSize: 20,
              color: Colors.white24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'water': return Icons.water_drop;
      case 'gym': return Icons.fitness_center;
      case 'book': return Icons.menu_book;
      case 'meditation': return Icons.self_improvement;
      case 'code': return Icons.code;
      default: return Icons.star_rounded;
    }
  }
}
