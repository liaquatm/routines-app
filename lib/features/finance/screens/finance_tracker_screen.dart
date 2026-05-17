import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_service.dart';
import '../../../models/finance_transaction.dart';

class FinanceTrackerScreen extends StatefulWidget {
  const FinanceTrackerScreen({super.key});

  @override
  State<FinanceTrackerScreen> createState() => _FinanceTrackerScreenState();
}

class _FinanceTrackerScreenState extends State<FinanceTrackerScreen> {
  bool _isConnected = false;
  bool _isLoading = true;
  double _weeklySpending = 0.0;
  List<FinanceTransaction> _recentTransactions = [];

  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    // Start listening to service changes
    FinanceService.instance.addListener(_onServiceUpdate);
    _checkStatusAndLoad();
  }

  @override
  void dispose() {
    FinanceService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    _checkStatusAndLoad();
  }

  Future<void> _checkStatusAndLoad() async {
    final connected = await FinanceService.instance.isBankConnected();
    double weeklyTotal = 0.0;
    List<FinanceTransaction> transactions = [];

    if (connected) {
      weeklyTotal = await FinanceService.instance.getWeeklySpending();
      transactions = await FinanceService.instance.getRecentTransactions();
    }

    if (mounted) {
      setState(() {
        _isConnected = connected;
        _weeklySpending = weeklyTotal;
        _recentTransactions = transactions;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConnect() async {
    await FinanceService.instance.openPlaidLink();
  }

  Future<void> _handleDisconnect() async {
    await FinanceService.instance.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Finance',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: _isConnected 
          ? [IconButton(
              icon: const Icon(Icons.link_off, color: Colors.redAccent),
              onPressed: _handleDisconnect,
            )]
          : null,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
        : _isConnected 
          ? _buildConnectedUI() 
          : _buildDisconnectedUI(),
    );
  }

  Widget _buildDisconnectedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded, 
              size: 64, 
              color: Colors.greenAccent
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connect Your Bank',
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Securely connect your accounts to see a weekly summary of your spending.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Get Started',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUI() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAnalysisCard(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => FinanceService.instance.syncData(),
              child: Text('Sync', style: GoogleFonts.lexend(color: Colors.blueAccent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          _buildEmptyState()
        else
          ..._recentTransactions.map((tx) => _buildTransactionTile(tx)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          'No transactions found for this week.',
          style: GoogleFonts.lexend(color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(FinanceTransaction tx) {
    final isOutbound = tx.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOutbound ? Colors.redAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOutbound ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isOutbound ? Colors.redAccent : Colors.greenAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  tx.category ?? 'Uncategorized',
                  style: GoogleFonts.lexend(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(tx.amount.abs()),
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                tx.date,
                style: GoogleFonts.lexend(
                  color: Colors.white24,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Outbound',
            style: GoogleFonts.lexend(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_weeklySpending),
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 4),
              Text(
                'Data synced from your bank',
                style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
