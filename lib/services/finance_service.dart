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

  static const _baseUrl = 'https://us-central1-habitatapp-e519d.cloudfunctions.net';
  static const _backendApiKey = 'habit-tracker-secure-829374';

  final _createLinkTokenUrl = '$_baseUrl/createLinkToken';
  final _exchangeTokenUrl = '$_baseUrl/exchangePublicToken';
  final _getDataUrl = '$_baseUrl/getFinanceData';

  final _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  final _dbService = DatabaseService.instance;

  static const String _tokenPrefix = 'plaid_token_';

  /// Helper to get request options with the API Key
  Options get _options => Options(headers: {'x-api-key': _backendApiKey});

  /// 1. Initialize Plaid Link
  Future<void> openPlaidLink() async {
    try {
      final response = await _dio.post(_createLinkTokenUrl, options: _options);
      final linkToken = response.data['link_token'];
      final linkTokenConfiguration = LinkTokenConfiguration(token: linkToken);

      await PlaidLink.create(configuration: linkTokenConfiguration);
      PlaidLink.open();
    } catch (e) {
      debugPrint('FinanceService Link Error: $e');
    }
  }

  void _onPlaidSuccess(LinkSuccess success) async {
    try {
      final response = await _dio.post(
        _exchangeTokenUrl, 
        data: {'public_token': success.publicToken},
        options: _options,
      );
      
      final accessToken = response.data['access_token'];
      final itemId = response.data['item_id'];
      final institutionName = success.metadata.institution?.name ?? 'Linked Bank';

      final db = await _dbService.database;
      await db.insert('finance_connections', {
        'id': itemId,
        'institutionName': institutionName,
        'lastSynced': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await _secureStorage.write(key: '$_tokenPrefix$itemId', value: accessToken);
      await syncData();
    } catch (e) {
      debugPrint('Token Exchange Error: $e');
    }
  }

  void _onPlaidExit(LinkExit exit) => debugPrint('Plaid Exit');
  void _onPlaidEvent(LinkEvent event) => debugPrint('Plaid Event: ${event.name}');

  /// 2. Fetch and Save Data for ALL connected banks
  Future<void> syncData({int days = 90}) async {
    final db = await _dbService.database;
    final connections = await db.query('finance_connections');
    if (connections.isEmpty) return;

    for (var conn in connections) {
      final itemId = conn['id'] as String;
      final accessToken = await _secureStorage.read(key: '$_tokenPrefix$itemId');
      if (accessToken != null) {
        await _syncSingleConnection(itemId, accessToken, days);
      }
    }
    notifyListeners();
  }

  Future<void> _syncSingleConnection(String itemId, String accessToken, int days) async {
    try {
      final response = await _dio.post(
        _getDataUrl, 
        data: {
          'access_token': accessToken,
          'days': days,
        },
        options: _options,
      );
      
      final db = await _dbService.database;
      final batch = db.batch();

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
        var accountMap = account.toMap();
        accountMap['connectionId'] = itemId; 
        batch.insert('finance_accounts', accountMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (var tx in response.data['transactions']) {
        final List? categoryList = tx['category'] as List?;
        final primaryCategory = categoryList?.isNotEmpty == true ? categoryList!.first.toString() : 'Other';
        
        final transaction = FinanceTransaction(
          id: tx['transaction_id'],
          accountId: tx['account_id'],
          amount: (tx['amount'] ?? 0).toDouble(),
          date: tx['date'],
          name: tx['name'],
          category: primaryCategory,
          pending: tx['pending'] ?? false,
        );
        batch.insert('finance_transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      batch.update('finance_connections', 
        {'lastSynced': DateTime.now().toIso8601String()}, 
        where: 'id = ?', 
        whereArgs: [itemId]
      );

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Sync Error for $itemId: $e');
    }
  }

  /// 3. Data Retrieval
  Future<List<FinanceTransaction>> getRecentTransactions({int limit = 200}) async {
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
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM finance_transactions WHERE amount > 0 AND date >= ?',
      [sevenDaysAgo],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getConnections() async {
    final db = await _dbService.database;
    return await db.query('finance_connections');
  }

  Future<bool> isBankConnected() async {
    final db = await _dbService.database;
    final connections = await db.query('finance_connections');
    return connections.isNotEmpty;
  }
  
  Future<void> disconnectAll() async {
    await _secureStorage.deleteAll();
    final db = await _dbService.database;
    await db.delete('finance_connections');
    notifyListeners();
  }

  Future<void> removeConnection(String itemId) async {
    await _secureStorage.delete(key: '$_tokenPrefix$itemId');
    final db = await _dbService.database;
    await db.delete('finance_connections', where: 'id = ?', whereArgs: [itemId]);
    notifyListeners();
  }
}
