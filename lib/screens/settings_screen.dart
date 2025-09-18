import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appStateNotifier = ref.read(appStateProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(
              context,
              'Protection Settings',
              [
                _buildSwitchTile(
                  context,
                  'Auto Recording',
                  'Automatically record calls for analysis',
                  Icons.record_voice_over,
                  appState.autoRecording,
                  (value) => appStateNotifier.setAutoRecording(value),
                ),
                _buildSliderTile(
                  context,
                  'Analysis Sensitivity',
                  'Adjust how sensitive scam detection should be',
                  Icons.tune,
                  appState.analysisSensitivity,
                  (value) => appStateNotifier.setAnalysisSensitivity(value),
                ),
                _buildSwitchTile(
                  context,
                  'Notifications',
                  'Receive alerts about potential scams',
                  Icons.notifications,
                  appState.notificationsEnabled,
                  (value) => appStateNotifier.setNotificationsEnabled(value),
                ),
              ],
            ).animate(delay: 0.1.seconds)
              .fadeIn(duration: 0.6.seconds)
              .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Appearance',
              [
                _buildThemeTile(context, appState, appStateNotifier),
              ],
            ).animate(delay: 0.2.seconds)
              .fadeIn(duration: 0.6.seconds)
              .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Data & Privacy',
              [
                _buildActionTile(
                  context,
                  'Clear Call History',
                  'Remove all stored call records',
                  Icons.delete_outline,
                  () => _showClearHistoryDialog(context),
                ),
                _buildActionTile(
                  context,
                  'Export Data',
                  'Download your call analysis data',
                  Icons.download,
                  () => _showExportDialog(context),
                ),
                _buildActionTile(
                  context,
                  'Privacy Policy',
                  'View our privacy policy',
                  Icons.privacy_tip_outlined,
                  () => _showPrivacyPolicy(context),
                ),
              ],
            ).animate(delay: 0.3.seconds)
              .fadeIn(duration: 0.6.seconds)
              .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'About',
              [
                _buildInfoTile(context, 'Version', '1.0.0'),
                _buildActionTile(
                  context,
                  'Support',
                  'Get help and report issues',
                  Icons.help_outline,
                  () => _showSupportDialog(context),
                ),
              ],
            ).animate(delay: 0.4.seconds)
              .fadeIn(duration: 0.6.seconds)
              .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildSliderTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            divisions: 10,
            label: '${(value * 100).round()}%',
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeTile(
    BuildContext context,
    AppState appState,
    AppStateNotifier appStateNotifier,
  ) {
    return ListTile(
      leading: const Icon(Icons.palette, color: AppTheme.primaryColor),
      title: const Text('Theme'),
      subtitle: Text(_getThemeModeText(appState.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, appState, appStateNotifier),
    );
  }
  
  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
  
  Widget _buildInfoTile(BuildContext context, String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
  
  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  void _showThemeDialog(
    BuildContext context,
    AppState appState,
    AppStateNotifier appStateNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeText(mode)),
              value: mode,
              groupValue: appState.themeMode,
              onChanged: (value) {
                if (value != null) {
                  appStateNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content: const Text('This will permanently delete all call records and analysis data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export your call analysis data as a CSV file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export coming soon')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'SCAI Guard Privacy Policy\n\n'
            'Your privacy is important to us. This app processes audio data locally and securely to provide scam detection services.\n\n'
            '• Call recordings are processed in real-time\n'
            '• Data is encrypted during transmission\n'
            '• No personal data is stored without consent\n'
            '• You can delete your data at any time\n\n'
            'For the full privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text('Need help? Contact our support team or visit our help center.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support contact coming soon')),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}