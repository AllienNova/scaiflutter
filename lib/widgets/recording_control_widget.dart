import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../services/recording_mode_service.dart';
import '../services/live_analysis_service.dart';
import '../models/live_analysis_models.dart';

class RecordingControlWidget extends ConsumerStatefulWidget {
  const RecordingControlWidget({super.key});

  @override
  ConsumerState<RecordingControlWidget> createState() => _RecordingControlWidgetState();
}

class _RecordingControlWidgetState extends ConsumerState<RecordingControlWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRecordingModeSelector(),
          const SizedBox(height: 16),
          _buildStatusIndicator(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.mic,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Recording Control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/recording-control'),
          icon: const Icon(Icons.settings),
          iconSize: 20,
          tooltip: 'Advanced Settings',
        ),
      ],
    );
  }

  Widget _buildRecordingModeSelector() {
    return StreamBuilder<RecordingMode>(
      stream: RecordingModeService.instance.modeStream,
      builder: (context, snapshot) {
        final currentMode = snapshot.data ?? RecordingMode.manual;
        
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: RecordingMode.values.map((mode) {
              final isSelected = mode == currentMode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _changeRecordingMode(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getModeLabel(mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator() {
    return StreamBuilder<String>(
      stream: RecordingModeService.instance.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'Ready';
        final isRecording = status.contains('recording') || status.contains('Recording');
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRecording 
                ? Colors.red.withOpacity(0.1)
                : AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRecording 
                  ? Colors.red.withOpacity(0.3)
                  : AppTheme.successColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isRecording
                    ? Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 16,
                        key: const ValueKey('recording'),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .scale(duration: 1.seconds, begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2))
                        .then()
                        .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0))
                    : Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 16,
                        key: const ValueKey('ready'),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isRecording ? Colors.red : AppTheme.successColor,
                  ),
                ),
              ),
              if (isRecording)
                StreamBuilder<RecordingMode>(
                  stream: RecordingModeService.instance.modeStream,
                  builder: (context, modeSnapshot) {
                    final mode = modeSnapshot.data ?? RecordingMode.manual;
                    return _buildRecordingTimer(mode);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingTimer(RecordingMode mode) {
    // Simple timer display - in real app this would track actual recording time
    return StreamBuilder<String>(
      stream: Stream.periodic(const Duration(seconds: 1), (count) {
        final minutes = count ~/ 60;
        final seconds = count % 60;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            snapshot.data ?? '00:00',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'Live Analysis',
            Icons.radar,
            () => _toggleLiveAnalysis(),
            _buildLiveAnalysisIndicator(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Call History',
            Icons.history,
            () => context.go('/home'), // Navigate to call history tab
            null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap, Widget? trailing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAnalysisIndicator() {
    return StreamBuilder<bool>(
      stream: LiveAnalysisService.instance.analysisStateStream,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isEnabled ? AppTheme.successColor : AppTheme.textSecondary,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _getModeLabel(RecordingMode mode) {
    switch (mode) {
      case RecordingMode.manual:
        return 'Manual';
      case RecordingMode.demo:
        return 'Demo';
      case RecordingMode.automatic:
        return 'Auto';
    }
  }

  void _changeRecordingMode(RecordingMode mode) async {
    try {
      await RecordingModeService.instance.setMode(mode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_getModeLabel(mode)} mode'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error switching mode: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _toggleLiveAnalysis() async {
    try {
      final isEnabled = LiveAnalysisService.instance.isAnalysisEnabled;
      
      if (isEnabled) {
        await LiveAnalysisService.instance.disableLiveAnalysis();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live analysis disabled'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      } else {
        await LiveAnalysisService.instance.enableLiveAnalysis();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live analysis enabled'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling live analysis: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
