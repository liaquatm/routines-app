import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/finance_transaction.dart';
import '../../../services/finance_analysis_service.dart';

class CashFlowChart extends StatelessWidget {
  final List<FinanceTransaction> transactions;

  const CashFlowChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final analysis = FinanceAnalysisService(transactions);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final inbound = analysis.totalInbound;
    final outbound = analysis.totalOutbound;

    if (inbound == 0 && outbound == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Flow',
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
              AspectRatio(
                aspectRatio: 1.7,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (inbound > outbound ? inbound : outbound) * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Inbound', style: GoogleFonts.lexend(color: Colors.white60, fontSize: 12)),
                                );
                              case 1:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Outbound', style: GoogleFonts.lexend(color: Colors.white60, fontSize: 12)),
                                );
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: inbound,
                            color: Colors.greenAccent,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: outbound,
                            color: Colors.redAccent,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('In', inbound, Colors.greenAccent, currencyFormat),
                  _buildSummaryItem('Out', outbound, Colors.redAccent, currencyFormat),
                  _buildSummaryItem('Net', analysis.netCashFlow, Colors.blueAccent, currencyFormat),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12)),
        Text(
          format.format(amount),
          style: GoogleFonts.lexend(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
