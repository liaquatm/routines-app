import 'database_service.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  final dbService = DatabaseService.instance;
  final notificationService = NotificationService();

  Future<List<Reminder>> loadReminders() async {
    final db = await dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }

  int _getNotificationId(String stringId) {
    // Safely convert the string ID to an integer for notifications
    try {
      if (stringId.length > 8) {
        return int.parse(stringId.substring(stringId.length - 8));
      }
      return int.parse(stringId);
    } catch (e) {
      return stringId.hashCode;
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    final db = await dbService.database;
    await db.insert('reminders', reminder.toMap());
    
    // Schedule notification
    await notificationService.scheduleNotification(
      id: _getNotificationId(reminder.id),
      title: 'Reminder',
      body: reminder.title,
      scheduledDate: reminder.dateTime,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await dbService.database;
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    final notificationId = _getNotificationId(reminder.id);
    await notificationService.cancelNotification(notificationId);

    if (!reminder.isCompleted && reminder.dateTime.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: notificationId,
        title: 'Reminder',
        body: reminder.title,
        scheduledDate: reminder.dateTime,
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    final db = await dbService.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);

    final notificationId = _getNotificationId(id);
    await notificationService.cancelNotification(notificationId);
  }
}
