import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/reminder.dart';
import '../../../services/reminder_service.dart';
import 'add_reminder_screen.dart';

class ManageRemindersScreen extends StatefulWidget {
  final bool isViewOnly;
  const ManageRemindersScreen({super.key, this.isViewOnly = false});

  @override
  State<ManageRemindersScreen> createState() => _ManageRemindersScreenState();
}

class _ManageRemindersScreenState extends State<ManageRemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _reminderService.loadReminders();
      // Sort reminders by date (newest first)
      reminders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Delete Reminder?', style: GoogleFonts.lexend(color: Colors.white)),
        content: Text('Are you sure you want to delete "${reminder.title}"?',
            style: GoogleFonts.lexend(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lexend(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _reminderService.deleteReminder(reminder.id);
      _loadReminders();
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
      _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
        : _reminders.isEmpty
            ? Center(
                child: Text(
                  'No reminders found.',
                  style: GoogleFonts.lexend(color: Colors.white24, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  final isPast = reminder.dateTime.isBefore(DateTime.now());
                  final statusColor = isPast ? Colors.orangeAccent : Colors.greenAccent;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reminder.isCompleted ? statusColor.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _editReminder(reminder),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_rounded, color: statusColor, size: 20),
                      ),
                      title: Text(
                        reminder.title,
                        style: GoogleFonts.lexend(
                          color: reminder.isCompleted ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormat('MMM d, h:mm a').format(reminder.dateTime)} • ${isPast ? "Past" : "Upcoming"}',
                        style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        onPressed: () => _deleteReminder(reminder),
                      ),
                    ),
                  );
                },
              );

    if (widget.isViewOnly) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Manage Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: content,
    );
  }
}
