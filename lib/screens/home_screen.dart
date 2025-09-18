import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../providers/call_recording_provider.dart';
import '../services/call_service.dart';
import '../services/recording_mode_service.dart';
import '../services/live_analysis_service.dart';
import '../widgets/protection_status_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/recording_control_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ScamShieldAI',
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
            RecordingControlWidget(),
            const SizedBox(height: 24),
            ProtectionStatusWidget(),
            const SizedBox(height: 24),
            QuickActionsWidget(),
            const SizedBox(height: 24), // Add bottom padding to prevent overflow
          ],
        ),
      ),
      floatingActionButton: _buildRecordingFAB(),
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
                      'Welcome to ScamShieldAI',
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
  Widget _buildRecordingFAB() {
    return StreamBuilder<RecordingMode>(
      stream: RecordingModeService.instance.modeStream,
      builder: (context, modeSnapshot) {
        return StreamBuilder<String>(
          stream: RecordingModeService.instance.statusStream,
          builder: (context, statusSnapshot) {
            final currentMode = modeSnapshot.data ?? RecordingMode.manual;
            final status = statusSnapshot.data ?? 'Ready';
            final isRecording = status.contains('recording') || status.contains('Recording');

            return FloatingActionButton.extended(
              onPressed: () => _handleFABPress(currentMode, isRecording),
              backgroundColor: isRecording ? Colors.red : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isRecording
                    ? const Icon(Icons.stop, key: ValueKey('stop'))
                    : const Icon(Icons.mic, key: ValueKey('mic')),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isRecording ? 'Stop Recording' : 'Start Recording',
                  key: ValueKey(isRecording ? 'stop' : 'start'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleFABPress(RecordingMode currentMode, bool isRecording) async {
    try {
      if (isRecording) {
        // Stop recording
        switch (currentMode) {
          case RecordingMode.manual:
            await RecordingModeService.instance.stopManualRecording();
            break;
          case RecordingMode.demo:
            await RecordingModeService.instance.stopDemo();
            break;
          case RecordingMode.automatic:
            // Automatic recording stops automatically
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Automatic recording will stop when call ends'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
            return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording stopped'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        // Start recording
        switch (currentMode) {
          case RecordingMode.manual:
            await RecordingModeService.instance.startManualRecording(
              phoneNumber: '+1234567890',
              contactName: 'Test Contact',
              isIncoming: true,
            );
            break;
          case RecordingMode.demo:
            await RecordingModeService.instance.startDemo(DemoScenario.techSupportScam);
            break;
          case RecordingMode.automatic:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Automatic recording starts when calls are detected'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
            return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }






}