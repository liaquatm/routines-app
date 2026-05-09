import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/google_drive_service.dart';
import 'manage_habits_screen.dart';
import 'manage_reminders_screen.dart';

class ManageResourcesScreen extends StatelessWidget {
  final int initialIndex;
  const ManageResourcesScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Manage',
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Habits'),
              Tab(text: 'Reminders'),
              Tab(text: 'Sync'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ManageHabitsView(),
            ManageRemindersView(),
            SyncSettingsView(),
          ],
        ),
      ),
    );
  }
}

class SyncSettingsView extends StatefulWidget {
  const SyncSettingsView({super.key});

  @override
  State<SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<SyncSettingsView> {
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  bool _isSyncing = false;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    try {
      // attempt silent sign in
      final success = await _driveService.signIn(); 
      if (mounted) {
        setState(() {
          _isSignedIn = success;
        });
      }
    } catch (e) {
      debugPrint('Initial sign-in check failed: $e');
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSyncing = true);
    try {
      final success = await _driveService.signIn();
      setState(() {
        _isSignedIn = success;
        _isSyncing = false;
      });
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Check your internet and Google Console settings.')),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isSyncing = true);
    final success = await _driveService.uploadBackup();
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Backup successful!' : 'Backup failed.')),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will replace your current local data with the backup from Google Drive. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSyncing = true);
    final success = await _driveService.downloadBackup();
    setState(() => _isSyncing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore successful! Restarting data...')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google Drive Backup',
            style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your habits and reminders safe in the cloud.',
            style: GoogleFonts.lexend(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 32),
          if (!_isSignedIn)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSyncing ? null : _handleSignIn,
              ),
            )
          else
            Column(
              children: [
                _buildSyncButton(
                  title: 'Backup to Cloud',
                  subtitle: 'Upload local data to Drive',
                  icon: Icons.cloud_upload_rounded,
                  onTap: _handleBackup,
                ),
                const SizedBox(height: 16),
                _buildSyncButton(
                  title: 'Restore from Cloud',
                  subtitle: 'Download data from Drive',
                  icon: Icons.cloud_download_rounded,
                  onTap: _handleRestore,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () async {
                    await _driveService.signOut();
                    setState(() => _isSignedIn = false);
                  },
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncButton({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: _isSyncing ? null : onTap,
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
    );
  }
}

class ManageHabitsView extends StatefulWidget {
  const ManageHabitsView({super.key});

  @override
  State<ManageHabitsView> createState() => _ManageHabitsViewState();
}

class _ManageHabitsViewState extends State<ManageHabitsView> {
  // We can pull the logic from ManageHabitsScreen here, 
  // but it's cleaner to keep them separate.
  // For now I'll just use the existing screens but modified to be Views.
  @override
  Widget build(BuildContext context) {
    return const ManageHabitsScreen(isViewOnly: true);
  }
}

class ManageRemindersView extends StatefulWidget {
  const ManageRemindersView({super.key});

  @override
  State<ManageRemindersView> createState() => _ManageRemindersViewState();
}

class _ManageRemindersViewState extends State<ManageRemindersView> {
  @override
  Widget build(BuildContext context) {
    return const ManageRemindersScreen(isViewOnly: true);
  }
}
