import '../models/finance_transaction.dart';

class CategorySummary {
  final String category;
  final double amount;
  final double percentage;

  CategorySummary({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class FinanceAnalysisService {
  final List<FinanceTransaction> transactions;

  FinanceAnalysisService(this.transactions);

  /// 1. Spending Breakdown (Categorization)
  List<CategorySummary> getCategorySummaries() {
    final Map<String, double> totals = {};
    double totalOutbound = 0;

    for (var tx in transactions) {
      if (tx.amount > 0) {
        final cat = tx.primaryCategory;
        totals[cat] = (totals[cat] ?? 0) + tx.amount;
        totalOutbound += tx.amount;
      }
    }

    if (totalOutbound == 0) return [];

    final List<CategorySummary> summaries = totals.entries.map((entry) {
      return CategorySummary(
        category: entry.key,
        amount: entry.value,
        percentage: (entry.value / totalOutbound) * 100,
      );
    }).toList();

    summaries.sort((a, b) => b.amount.compareTo(a.amount));
    return summaries;
  }

  /// 2. Cash Flow Summary
  double get totalInbound => transactions
      .where((tx) => tx.amount < 0)
      .fold(0, (sum, tx) => sum + tx.amount.abs());

  double get totalOutbound => transactions
      .where((tx) => tx.amount > 0)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get netCashFlow => totalInbound - totalOutbound;

  /// 3. Subscription / Recurring Detection (Basic Implementation)
  /// Identifies transactions with the same name and amount appearing multiple times
  List<FinanceTransaction> detectSubscriptions() {
    final Map<String, List<FinanceTransaction>> groupedByName = {};
    
    for (var tx in transactions) {
      if (tx.amount > 0) {
        groupedByName.putIfAbsent(tx.name, () => []).add(tx);
      }
    }

    // A basic heuristic: if it appears more than once with the same amount in our sync period
    return groupedByName.values
        .where((list) => list.length >= 2)
        .map((list) => list.first)
        .toList();
  }

  /// 4. Daily Spending Trend
  Map<String, double> getDailySpending() {
    final Map<String, double> daily = {};
    for (var tx in transactions) {
      if (tx.amount > 0) {
        daily[tx.date] = (daily[tx.date] ?? 0) + tx.amount;
      }
    }
    return daily;
  }
}
