import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/habit.dart';
import '../../../services/habit_service.dart';
import 'add_habit_screen.dart';
import 'add_reminder_screen.dart';
import 'manage_resources_screen.dart';
import '../../../models/reminder.dart';
import '../../../services/reminder_service.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final HabitService _habitService = HabitService();
  final ReminderService _reminderService = ReminderService();
  List<Habit> _habits = [];
  List<Reminder> _reminders = [];
  Map<String, List<Reminder>> _remindersByDate = {};
  bool _isLoading = true;
  late DateTime _today;

  // Track the selected date for horizontal navigation
  late PageController _pageController;
  final int _initialPage = 1000;
  int _currentPage = 1000;
  bool _isCalendarVisible = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _initialPage);
    _loadHabits();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _habitService.loadHabits();
      final reminders = await _reminderService.loadReminders();
      
      // Index reminders by date string "YYYY-MM-DD" for O(1) lookup
      final Map<String, List<Reminder>> indexedReminders = {};
      for (var r in reminders) {
        final dateKey = DateFormat('yyyy-MM-dd').format(r.dateTime);
        indexedReminders.putIfAbsent(dateKey, () => []).add(r);
      }

      if (mounted) {
        setState(() {
          _habits = habits;
          _reminders = reminders;
          _remindersByDate = indexedReminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _getDateForPage(int page) {
    return _today.add(Duration(days: page - _initialPage));
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

  Future<void> _navigateToAddReminder() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddReminderScreen(),
    );

    if (result != null && result is Reminder) {
      await _reminderService.addReminder(result);
      await _loadHabits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${DateFormat('MMM d, h:mm a').format(result.dateTime)}'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: Icons.auto_awesome_rounded,
              color: Colors.blueAccent,
              title: 'New Habit',
              subtitle: 'Build a long-term routine',
              onTap: () {
                Navigator.pop(context);
                _navigateToAddHabit();
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.notification_important_rounded,
              color: Colors.orangeAccent,
              title: 'One-time Reminder',
              subtitle: 'Task for a specific time',
              onTap: () {
                Navigator.pop(context);
                _navigateToAddReminder();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white.withValues(alpha: 0.05),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
    );
  }

  void _navigateToManageHabits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageResourcesScreen()),
    );
    _loadHabits();
  }

  void _navigateToSyncTab() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageResourcesScreen(initialIndex: 2)),
    );
    _loadHabits();
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

  void _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Delete Habit?', style: GoogleFonts.lexend(color: Colors.white)),
        content: Text('Are you sure you want to delete "${habit.name}"? All progress will be lost.',
            style: GoogleFonts.lexend(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lexend(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.lexend(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _habitService.deleteHabit(habit.id);
      _loadHabits();
    }
  }

  void _editReminder(Reminder reminder) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReminderScreen(reminderToEdit: reminder),
    );

    if (result != null && result is Reminder) {
      await _reminderService.updateReminder(result);
      _loadHabits();
    }
  }

  void _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Delete Reminder?', style: GoogleFonts.lexend(color: Colors.white)),
        content: Text('Are you sure you want to delete this reminder?',
            style: GoogleFonts.lexend(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lexend(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.lexend(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _reminderService.deleteReminder(reminder.id);
      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark theme
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'HabitTracker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadHabits,
          ),
          IconButton(
            icon: Icon(
              _isCalendarVisible ? Icons.calendar_today : Icons.calendar_month,
              color: _isCalendarVisible ? Colors.blueAccent : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isCalendarVisible = !_isCalendarVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
            onPressed: _navigateToManageHabits,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: _isCalendarVisible ? MediaQuery.of(context).size.height * 0.4 : 0,
                  child: _isCalendarVisible
                      ? Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.blueAccent,
                              onPrimary: Colors.white,
                              surface: Color(0xFF1E1E1E),
                              onSurface: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: CalendarDatePicker(
                              initialDate: _getDateForPage(_currentPage),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              onDateChanged: (date) {
                                final today = DateTime.now();
                                final startOfToday = DateTime(today.year, today.month, today.day);
                                final startOfSelected = DateTime(date.year, date.month, date.day);
                                final daysDifference = startOfSelected.difference(startOfToday).inDays;
                                final targetPage = _initialPage + daysDifference;

                                _pageController.animateToPage(
                                  targetPage,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadHabits,
                    color: Colors.blueAccent,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        final date = _getDateForPage(index);
                        return _buildHabitPage(date);
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<int>(
          offset: const Offset(0, -135),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF252525),
          elevation: 12,
          onSelected: (value) {
            if (value == 1) _navigateToAddHabit();
            if (value == 2) _navigateToAddReminder();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'New Habit',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notification_important_rounded, color: Colors.orangeAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Reminder',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitPage(DateTime date) {
    final weekday = date.weekday;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final filteredHabits = _habits.where((h) {
      if (h.frequencyType == FrequencyType.fixed) {
        return h.fixedDays?.contains(weekday) ?? false;
      }
      return true;
    }).toList();

    final filteredReminders = _remindersByDate[dateKey] ?? [];

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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('EEEE').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Combined List
        Expanded(
          child: filteredHabits.isEmpty && filteredReminders.isEmpty
              ? _buildEmptyState()
              : ListView(
                  key: ValueKey('list_${date.toIso8601String()}_${_reminders.length}'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (filteredHabits.isNotEmpty) ...[
                      _buildSectionHeader('Habits'),
                      ...filteredHabits.map((h) => _buildHabitCard(h, date)),
                    ],
                    if (filteredReminders.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Reminders'),
                      ...filteredReminders.map((r) => _buildReminderCard(r)),
                    ],
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final now = DateTime.now();
    final isPast = reminder.dateTime.isBefore(now);
    final timeColor = isPast ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.isCompleted ? timeColor.withValues(alpha: 0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => _editReminder(reminder),
        onLongPress: () => _deleteReminder(reminder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: timeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notification_important_rounded,
            color: timeColor,
            size: 24,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: reminder.isCompleted ? Colors.white38 : Colors.white,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          DateFormat('h:mm a').format(reminder.dateTime),
          style: TextStyle(color: timeColor, fontSize: 13),
        ),
        trailing: GestureDetector(
          onTap: () async {
            setState(() {
              reminder.isCompleted = !reminder.isCompleted;
            });
            await _reminderService.updateReminder(reminder);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: reminder.isCompleted ? timeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: reminder.isCompleted ? timeColor : Colors.white24,
                width: 2,
              ),
            ),
            child: reminder.isCompleted
                ? const Icon(Icons.check, color: Colors.black, size: 20)
                : null,
          ),
        ),
      ),
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
        onTap: () => _editHabit(habit),
        onLongPress: () => _deleteHabit(habit),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.white38 : Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: isCompleted
            ? Text(
                'Completed!',
                style: TextStyle(color: habitColor, fontSize: 13),
              )
            : Text(
                habit.frequencyType == FrequencyType.fixed ? 'Daily Goal' : 'Flex Goal',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
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
          const Icon(Icons.auto_awesome, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            'A fresh start today!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _navigateToSyncTab,
            icon: const Icon(Icons.cloud_download_outlined, color: Colors.blueAccent),
            label: const Text(
              'Restore data from Google Drive',
              style: TextStyle(color: Colors.blueAccent),
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
