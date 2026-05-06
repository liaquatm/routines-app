import 'dart:convert';
import 'database_service.dart';
import '../models/habit.dart';

/// The HabitService is the "Librarian."
/// It translates our Dart Habit objects into SQL commands for the DatabaseService.
class HabitService {
  final dbService = DatabaseService.instance;

  /// Loads all habits and their full completion history from the database.
  Future<List<Habit>> loadHabits() async {
    final db = await dbService.database;

    // 1. Get all habit definitions
    final List<Map<String, dynamic>> habitMaps = await db.query('habit_definitions');

    List<Habit> habits = [];

    for (var habitMap in habitMaps) {
      final habitId = habitMap['id'] as String;

      // 2. Get all completion logs for this specific habit
      final List<Map<String, dynamic>> logMaps = await db.query(
        'habit_logs',
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      // 3. Convert those log rows into a list of DateTime objects
      List<DateTime> completedDays = logMaps.map((log) {
        return DateTime.parse(log['date'] as String);
      }).toList();

      // 4. Create the Habit object and add it to our list
      // We convert the 'fixedDays' string back into a List<int>
      habits.add(Habit(
        id: habitId,
        name: habitMap['name'],
        description: habitMap['description'],
        iconName: habitMap['iconName'] ?? 'star',
        colorValue: habitMap['colorValue'],
        frequencyType: FrequencyType.values[habitMap['frequencyType']],
        flexibleCount: habitMap['flexibleCount'],
        fixedDays: habitMap['fixedDays'] != null && habitMap['fixedDays'].isNotEmpty
            ? (habitMap['fixedDays'] as String).split(',').map(int.parse).toList()
            : null,
        completedDays: completedDays,
      ));
    }

    return habits;
  }

  /// Saves a new habit definition to the database.
  Future<void> addHabit(Habit habit) async {
    final db = await dbService.database;
    
    await db.insert(
      'habit_definitions',
      {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'iconName': habit.iconName,
        'colorValue': habit.colorValue,
        'frequencyType': habit.frequencyType.index,
        'flexibleCount': habit.flexibleCount,
        'fixedDays': habit.fixedDays?.join(','), // Convert list [1,2] to string "1,2"
      },
    );
  }

  /// Updates an existing habit definition.
  Future<void> updateHabit(Habit habit) async {
    final db = await dbService.database;
    await db.update(
      'habit_definitions',
      {
        'name': habit.name,
        'description': habit.description,
        'iconName': habit.iconName,
        'colorValue': habit.colorValue,
        'frequencyType': habit.frequencyType.index,
        'flexibleCount': habit.flexibleCount,
        'fixedDays': habit.fixedDays?.join(','),
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Logs a completion for a specific habit.
  Future<void> logCompletion(String habitId, DateTime date) async {
    final db = await dbService.database;
    await db.insert('habit_logs', {
      'habitId': habitId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    });
  }

  /// Removes a completion log (unchecking a habit).
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final db = await dbService.database;
    final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
    
    await db.delete(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateString],
    );
  }

  /// Deletes a habit and all its history.
  Future<void> deleteHabit(String habitId) async {
    final db = await dbService.database;
    // Foreign key with ON DELETE CASCADE will automatically handle the logs!
    await db.delete('habit_definitions', where: 'id = ?', whereArgs: [habitId]);
  }
}
