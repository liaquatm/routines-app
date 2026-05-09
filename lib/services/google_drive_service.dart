import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (error) {
      debugPrint('Google Drive Sign-In Error: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<http.Client?> _getAuthenticatedClient() async {
    final GoogleSignInAccount? account = _currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    final Map<String, String> headers = await account.authHeaders;
    return _AuthenticatedClient(headers);
  }

  /// Backs up the local database to Google Drive.
  Future<bool> uploadBackup() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);
      
      // 1. Get local database path
      final dbPath = await getDatabasesPath();
      final localFile = File(join(dbPath, 'my_data.db'));
      if (!await localFile.exists()) return false;

      // 2. Search for existing backup file
      final fileList = await driveApi.files.list(
        q: "name = 'my_habit_tracker_backup.db' and trashed = false",
        spaces: 'drive',
      );

      final drive.File driveFile = drive.File();
      driveFile.name = 'my_habit_tracker_backup.db';

      final media = drive.Media(localFile.openRead(), localFile.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
        debugPrint('Backup updated on Google Drive.');
      } else {
        // Create new file
        await driveApi.files.create(driveFile, uploadMedia: media);
        debugPrint('New backup created on Google Drive.');
      }
      return true;
    } catch (e) {
      debugPrint('Upload to Google Drive failed: $e');
      return false;
    }
  }

  /// Downloads the backup from Google Drive and replaces the local database.
  Future<bool> downloadBackup() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);

      // 1. Search for existing backup file
      final fileList = await driveApi.files.list(
        q: "name = 'my_habit_tracker_backup.db' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('No backup found on Google Drive.');
        return false;
      }

      final fileId = fileList.files!.first.id!;
      
      // 2. Download file content
      final drive.Media response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await getDatabasesPath();
      final localFile = File(join(dbPath, 'my_data.db'));

      // Ensure directory exists
      if (!await localFile.parent.exists()) {
        await localFile.parent.create(recursive: true);
      }

      // Close database before overwriting
      await DatabaseService.instance.close();

      final List<int> dataStore = [];
      await for (final data in response.stream) {
        dataStore.addAll(data);
      }
      await localFile.writeAsBytes(dataStore);

      debugPrint('Backup downloaded and restored.');
      return true;
    } catch (e) {
      debugPrint('Download from Google Drive failed: $e');
      return false;
    }
  }

  /// Checks if a local database exists.
  Future<bool> localDatabaseExists() async {
    final dbPath = await getDatabasesPath();
    return await File(join(dbPath, 'my_data.db')).exists();
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
