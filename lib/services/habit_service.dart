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
    
    // 2. Get ALL logs in one go to avoid N+1 query problem
    final List<Map<String, dynamic>> allLogMaps = await db.query('habit_logs');

    // Group logs by habitId
    Map<String, List<DateTime>> logsByHabit = {};
    for (var log in allLogMaps) {
      final habitId = log['habitId'] as String;
      final date = DateTime.parse(log['date'] as String);
      logsByHabit.putIfAbsent(habitId, () => []).add(date);
    }

    List<Habit> habits = [];

    for (var habitMap in habitMaps) {
      final habitId = habitMap['id'] as String;
      final completedDays = logsByHabit[habitId] ?? [];

      habits.add(Habit(
        id: habitId,
        name: habitMap['name'],
        description: habitMap['description'],
        iconName: habitMap['iconName'] ?? 'star',
        colorValue: habitMap['colorValue'],
        frequencyType: FrequencyType.values[habitMap['frequencyType'] ?? 0],
        flexibleCount: habitMap['flexibleCount'],
        fixedDays: habitMap['fixedDays'] != null && habitMap['fixedDays'].toString().isNotEmpty
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
