import 'package:flutter/material.dart';

class FinanceTransaction {
  final String id;
  final String accountId;
  final double amount;
  final String date;
  final String name;
  final String? category;
  final bool pending;

  FinanceTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.name,
    this.category,
    this.pending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'date': date,
      'name': name,
      'category': category,
      'pending': pending ? 1 : 0,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'],
      accountId: map['accountId'],
      amount: map['amount'],
      date: map['date'],
      name: map['name'],
      category: map['category'],
      pending: map['pending'] == 1,
    );
  }

  // --- Helper Getters for UI ---

  String get primaryCategory => category ?? 'Other';

  IconData get icon {
    final cat = primaryCategory.toLowerCase();
    if (cat.contains('food') || cat.contains('drink') || cat.contains('dining') || cat.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('travel') || cat.contains('transport') || cat.contains('taxi') || cat.contains('uber')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('transfer') || cat.contains('payment') || cat.contains('bill')) {
      return Icons.swap_horiz_rounded;
    }
    if (cat.contains('health') || cat.contains('medical') || cat.contains('pharmacy')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('recreation') || cat.contains('entertainment') || cat.contains('gym') || cat.contains('sport')) {
      return Icons.confirmation_number_rounded;
    }
    if (cat.contains('shop') || cat.contains('department') || cat.contains('clothing')) {
      return Icons.shopping_bag_rounded;
    }
    if (cat.contains('rent') || cat.contains('utilities') || cat.contains('service') || cat.contains('home')) {
      return Icons.home_work_rounded;
    }
    return Icons.attach_money_rounded;
  }

  Color get color {
    final cat = primaryCategory.toLowerCase();
    if (cat.contains('food') || cat.contains('dining')) return Colors.orangeAccent;
    if (cat.contains('travel') || cat.contains('transport')) return Colors.blueAccent;
    if (cat.contains('health')) return Colors.redAccent;
    if (cat.contains('recreation') || cat.contains('entertainment')) return Colors.purpleAccent;
    if (cat.contains('shop')) return Colors.pinkAccent;
    if (cat.contains('rent') || cat.contains('utilities')) return Colors.tealAccent;
    if (cat.contains('transfer')) return Colors.grey;
    return Colors.greenAccent;
  }
}
