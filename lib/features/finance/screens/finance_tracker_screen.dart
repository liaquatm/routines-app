import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_service.dart';
import '../../../models/finance_transaction.dart';
import '../widgets/spending_breakdown_chart.dart';
import '../widgets/cash_flow_chart.dart';

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
  List<Map<String, dynamic>> _connections = [];

  int _syncDays = 90;
  bool _isSyncing = false;

  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
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
    List<Map<String, dynamic>> connections = [];

    if (connected) {
      weeklyTotal = await FinanceService.instance.getWeeklySpending();
      // Increase limit to 200 to ensure user sees history beyond 30 days if it exists
      transactions = await FinanceService.instance.getRecentTransactions(limit: 200);
      connections = await FinanceService.instance.getConnections();
    }

    if (mounted) {
      setState(() {
        _isConnected = connected;
        _weeklySpending = weeklyTotal;
        _recentTransactions = transactions;
        _connections = connections;
        _isLoading = false;
      });
    }
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
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              onPressed: () => FinanceService.instance.openPlaidLink(),
              tooltip: 'Add another bank',
            ),
        ],
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
            child: const Icon(Icons.account_balance_wallet_rounded, size: 64, color: Colors.greenAccent),
          ),
          const SizedBox(height: 24),
          Text('Connect Your Bank', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Securely connect your accounts to see a unified summary of your spending.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(fontSize: 14, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => FinanceService.instance.openPlaidLink(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Get Started', style: GoogleFonts.lexend(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      await FinanceService.instance.syncData(days: _syncDays);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildConnectedUI() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAnalysisCard(),
        const SizedBox(height: 24),
        SpendingBreakdownChart(transactions: _recentTransactions),
        const SizedBox(height: 32),
        CashFlowChart(transactions: _recentTransactions),
        const SizedBox(height: 24),
        _buildConnectionsSection(),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                DropdownButton<int>(
                  value: _syncDays,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: const SizedBox(),
                  style: GoogleFonts.lexend(color: Colors.blueAccent, fontSize: 12),
                  items: [30, 90, 180, 365].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value days'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _syncDays = newValue);
                      _handleSync();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _isSyncing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                  : TextButton(
                      onPressed: _handleSync,
                      child: Text('Sync All', style: GoogleFonts.lexend(color: Colors.blueAccent)),
                    ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          _buildEmptyState()
        else
          ..._recentTransactions.map((tx) => _buildTransactionTile(tx)),
        const SizedBox(height: 40),
        Center(
          child: TextButton(
            onPressed: () => FinanceService.instance.disconnectAll(),
            child: Text('Disconnect All Banks', style: GoogleFonts.lexend(color: Colors.redAccent.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Linked Institutions', style: GoogleFonts.lexend(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _connections.length,
            itemBuilder: (context, index) {
              final conn = _connections[index];
              return GestureDetector(
                onLongPress: () => _confirmDeletion(conn['id'], conn['institutionName']),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        conn['institutionName'],
                        style: GoogleFonts.lexend(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmDeletion(conn['id'], conn['institutionName']),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeletion(String itemId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Remove Bank?', style: GoogleFonts.lexend(color: Colors.white)),
        content: Text('This will delete all accounts and transactions from $name. This cannot be undone.', style: GoogleFonts.lexend(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.lexend(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              FinanceService.instance.removeConnection(itemId);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.lexend(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(FinanceTransaction tx) {
    final isOutbound = tx.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.icon,
              color: tx.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                Text(tx.primaryCategory, style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currencyFormat.format(tx.amount.abs()), style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text(tx.date, style: GoogleFonts.lexend(color: Colors.white24, fontSize: 11)),
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
        gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unified Weekly Outbound', style: GoogleFonts.lexend(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          Text(_currencyFormat.format(_weeklySpending), style: GoogleFonts.lexend(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text('${_connections.length} Banks Connected', style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(24)), child: Center(child: Text('No transactions found.', style: GoogleFonts.lexend(color: Colors.white38))));
  }
}
