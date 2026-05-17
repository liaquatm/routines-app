import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/finance_account.dart';
import '../models/finance_transaction.dart';

class FinanceService extends ChangeNotifier {
  static final FinanceService instance = FinanceService._();
  
  FinanceService._() {
    PlaidLink.onSuccess.listen(_onPlaidSuccess);
    PlaidLink.onExit.listen(_onPlaidExit);
    PlaidLink.onEvent.listen(_onPlaidEvent);
  }

  // Using standard Firebase Function URLs for better stability
  static const _baseUrl = 'https://us-central1-habitatapp-e519d.cloudfunctions.net';
  
  final _createLinkTokenUrl = '$_baseUrl/createLinkToken';
  final _exchangeTokenUrl = '$_baseUrl/exchangePublicToken';
  final _getDataUrl = '$_baseUrl/getFinanceData';

  final _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  final _dbService = DatabaseService.instance;

  static const String _accessTokenKey = 'plaid_access_token';
  static const String _itemIdKey = 'plaid_item_id';

  /// 1. Initialize Plaid Link
  Future<void> openPlaidLink() async {
    try {
      debugPrint('FinanceService: Fetching link token...');
      final response = await _dio.post(_createLinkTokenUrl);
      final linkToken = response.data['link_token'];
      debugPrint('FinanceService: Received link token: $linkToken');

      final linkTokenConfiguration = LinkTokenConfiguration(token: linkToken);

      await PlaidLink.create(configuration: linkTokenConfiguration);
      debugPrint('FinanceService: Opening Plaid Link UI...');
      PlaidLink.open();
      
    } on DioException catch (e) {
      debugPrint('FinanceService: Dio Error (${e.response?.statusCode}): ${e.response?.data}');
    } catch (e) {
      debugPrint('FinanceService: General Error: $e');
    }
  }

  void _onPlaidSuccess(LinkSuccess success) async {
    debugPrint('FinanceService: Plaid Link Success! Public Token: ${success.publicToken}');
    
    try {
      debugPrint('FinanceService: Exchanging public token...');
      final response = await _dio.post(_exchangeTokenUrl, data: {'public_token': success.publicToken});
      
      final accessToken = response.data['access_token'];
      final itemId = response.data['item_id'];
      
      debugPrint('FinanceService: Saving tokens to secure storage...');
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _itemIdKey, value: itemId);
      
      debugPrint('FinanceService: Tokens saved. Starting initial sync...');
      await syncData();
      
      debugPrint('FinanceService: Sync complete. Notifying UI listeners.');
      notifyListeners(); 
    } catch (e) {
      debugPrint('FinanceService: Error during token exchange: $e');
    }
  }

  void _onPlaidExit(LinkExit exit) {
    debugPrint('FinanceService: Plaid Exit. Error: ${exit.error?.message}');
  }

  void _onPlaidEvent(LinkEvent event) {
    debugPrint('FinanceService: Plaid Event: ${event.name}');
  }

  /// 2. Fetch and Save Data
  Future<void> syncData() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    debugPrint('FinanceService: Syncing data with access token: ${accessToken != null ? "FOUND" : "NOT FOUND"}');
    
    if (accessToken == null) return;

    try {
      final response = await _dio.post(_getDataUrl, data: {'access_token': accessToken});
      final db = await _dbService.database;
      final batch = db.batch();

      debugPrint('FinanceService: Received ${response.data['accounts'].length} accounts and ${response.data['transactions'].length} transactions.');

      // Save Accounts
      for (var acc in response.data['accounts']) {
        final account = FinanceAccount(
          id: acc['account_id'],
          name: acc['name'],
          officialName: acc['official_name'],
          mask: acc['mask'],
          type: acc['type'],
          subtype: acc['subtype'],
          balanceCurrent: (acc['balances']['current'] ?? 0).toDouble(),
          balanceAvailable: (acc['balances']['available'] ?? 0).toDouble(),
        );
        batch.insert('finance_accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Save Transactions
      for (var tx in response.data['transactions']) {
        final transaction = FinanceTransaction(
          id: tx['transaction_id'],
          accountId: tx['account_id'],
          amount: (tx['amount'] ?? 0).toDouble(),
          date: tx['date'],
          name: tx['name'],
          category: (tx['category'] as List?)?.first?.toString(),
          pending: tx['pending'] ?? false,
        );
        batch.insert('finance_transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint('FinanceService: Data successfully saved to SQLite.');
      notifyListeners();
    } catch (e) {
      debugPrint('FinanceService: Sync Error: $e');
    }
  }

  /// 3. Data Retrieval for UI
  Future<List<FinanceTransaction>> getRecentTransactions({int limit = 10}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'finance_transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => FinanceTransaction.fromMap(maps[i]));
  }

  Future<double> getWeeklySpending() async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM finance_transactions WHERE amount > 0 AND date >= ?',
      [sevenDaysAgo],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<bool> isBankConnected() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    debugPrint('FinanceService: Checking connection. Token exists: ${token != null}');
    return token != null;
  }
  
  Future<void> disconnect() async {
    debugPrint('FinanceService: Disconnecting bank and clearing storage...');
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _itemIdKey);
    final db = await _dbService.database;
    await db.delete('finance_accounts');
    await db.delete('finance_transactions');
    notifyListeners();
  }
}
