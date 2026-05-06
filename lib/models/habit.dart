import 'package:flutter/material.dart';

/// Defines whether a habit happens on specific days (Fixed) 
/// or a certain number of times per week (Flexible).
enum FrequencyType { fixed, flexible }

/// The data blueprint for a single Habit.
class Habit {
  final String id;           // Unique identifier for each habit.
  String name;               // The title (e.g., "Drink Water").
  String? description;       // Optional extra details.
  String iconName;           // Name of the icon to display.
  int colorValue;            // The color stored as an integer (e.g., 0xFF...).
  
  // Frequency Settings (HabiCard style)
  FrequencyType frequencyType;
  List<int>? fixedDays;      // e.g., [1, 3, 5] for Mon, Wed, Fri.
  int? flexibleCount;        // e.g., 3 if the goal is 3 times a week.

  // History: A list of every date the user clicked the "complete" button.
  // This is the foundation for heatmaps and streaks.
  List<DateTime> completedDays; 

  Habit({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'star',
    this.colorValue = 0xFF4CAF50,
    this.frequencyType = FrequencyType.fixed,
    this.fixedDays,
    this.flexibleCount,
    List<DateTime>? completedDays,
  }) : completedDays = completedDays ?? [];

  /// Logic: Checks if the habit was completed on a specific date.
  bool isCompletedOn(DateTime date) {
    return completedDays.any((d) => 
      d.year == date.year && 
      d.month == date.month && 
      d.day == date.day
    );
  }

  /// Logic: Checks if the habit was completed today.
  bool isCompletedToday() {
    return isCompletedOn(DateTime.now());
  }

  /// Logic: Adds or removes a completion log for a specific date.
  void toggleOn(DateTime date) {
    DateTime dateStart = DateTime(date.year, date.month, date.day);
    
    if (isCompletedOn(date)) {
      completedDays.removeWhere((d) => 
        d.year == date.year && 
        d.month == date.month && 
        d.day == date.day
      );
    } else {
      completedDays.add(dateStart);
    }
  }

  /// Logic: Adds today to the list if not completed, or removes it if already done.
  void toggleToday() {
    toggleOn(DateTime.now());
  }

  /// Logic: Calculates the current completion streak.
  int calculateStreak() {
    if (completedDays.isEmpty) return 0;

    // Sort dates descending (newest first)
    List<DateTime> sortedDays = List.from(completedDays)..sort((a, b) => b.compareTo(a));
    
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);
    
    int streak = 0;
    
    // If not completed today, start checking from yesterday to see if streak is still alive
    if (!isCompletedToday()) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (var date in sortedDays) {
      if (date.year == checkDate.year && 
          date.month == checkDate.month && 
          date.day == checkDate.day) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }
    return streak;
  }
}
