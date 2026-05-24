import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/finance_transaction.dart';
import '../../../services/finance_analysis_service.dart';

class SpendingBreakdownChart extends StatelessWidget {
  final List<FinanceTransaction> transactions;

  const SpendingBreakdownChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Use the central analysis service
    final analysis = FinanceAnalysisService(transactions);
    final summaries = analysis.getCategorySummaries();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Breakdown',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: summaries.map((s) {
                      final sampleTx = transactions.firstWhere((tx) => tx.primaryCategory == s.category);
                      return PieChartSectionData(
                        color: sampleTx.color,
                        value: s.amount,
                        title: '${s.percentage.toStringAsFixed(0)}%',
                        radius: 25,
                        titleStyle: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ...summaries.map((s) => _buildLegendItem(s, transactions, currencyFormat)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(CategorySummary summary, List<FinanceTransaction> allTransactions, NumberFormat format) {
    final sampleTx = allTransactions.firstWhere((tx) => tx.primaryCategory == summary.category);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: sampleTx.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary.category,
              style: GoogleFonts.lexend(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            format.format(summary.amount),
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
