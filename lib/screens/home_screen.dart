import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/call_service.dart';
import '../widgets/protection_status_widget.dart';
import '../widgets/quick_actions_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SCAI Guard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 24),
            ProtectionStatusWidget(),
            const SizedBox(height: 24),
            QuickActionsWidget(),
            const SizedBox(height: 24),
            _buildRecordingControlCard(),
            const SizedBox(height: 24),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to SCAI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Powered Call Protection',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your calls are being monitored and analyzed in real-time to protect you from scams and fraudulent activities.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 0.8.seconds)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // Navigate to call history tab
                // This will be handled by the bottom navigation
              },
              icon: const Icon(Icons.history, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityPlaceholder(),
      ],
    );
  }

  Widget _buildRecordingControlCard() {
    return Builder(
      builder: (context) => Card(
        elevation: 4,
        shadowColor: AppTheme.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recording Control',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Test call recording and scam analysis',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/recording-control'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Testing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(duration: 0.6.seconds, delay: 0.6.seconds)
        .slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildActivityPlaceholder() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your call recordings and analysis will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 0.6.seconds, delay: 0.4.seconds)
        .slideY(begin: 0.2, end: 0),
    );
  }



}