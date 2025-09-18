import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/call_recording_model.dart';

class CallRecordingItem extends StatelessWidget {
  final CallRecording recording;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onAnalyze;

  const CallRecordingItem({
    super.key,
    required this.recording,
    this.onTap,
    this.onPlay,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildDetails(),
                if (recording.analysisResult != null) ...[
                  const SizedBox(height: 12),
                  _buildAnalysisResult(),
                ],
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: recording.isIncoming ? AppTheme.successColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            recording.isIncoming ? Icons.call_received : Icons.call_made,
            color: recording.isIncoming ? AppTheme.successColor : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recording.contactName ?? recording.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (recording.contactName != null) ...[
                const SizedBox(height: 2),
                Text(
                  recording.phoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (recording.isAnalyzing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.warningColor),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Analyzing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1.5.seconds),
      ],
    );
  }

  Widget _buildDetails() {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Row(
      children: [
        _buildDetailChip(
          icon: Icons.access_time,
          label: recording.formattedDuration,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        _buildDetailChip(
          icon: Icons.calendar_today,
          label: dateFormat.format(recording.timestamp),
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        _buildDetailChip(
          icon: Icons.storage,
          label: recording.formattedFileSize,
          color: AppTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final result = recording.analysisResult!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAnalysisBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getAnalysisColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getAnalysisIcon(),
                color: _getAnalysisColor(),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                result.scamTypeText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _getAnalysisColor(),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getAnalysisColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.confidenceScore.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getAnalysisColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.riskLevelText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _getAnalysisColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Play'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: recording.isAnalyzing ? null : onAnalyze,
            icon: Icon(
              recording.analysisResult != null ? Icons.refresh : Icons.analytics,
              size: 18,
            ),
            label: Text(recording.analysisResult != null ? 'Re-analyze' : 'Analyze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (recording.analysisResult?.isScam == true) {
      return AppTheme.errorColor.withOpacity(0.3);
    }
    return AppTheme.borderColor;
  }

  Color _getAnalysisColor() {
    final result = recording.analysisResult!;
    if (result.isScam) {
      switch (result.riskLevel.toUpperCase()) {
        case 'CRITICAL':
          return AppTheme.errorColor;
        case 'HIGH':
          return Colors.deepOrange;
        case 'MEDIUM':
          return AppTheme.warningColor;
        default:
          return Colors.orange;
      }
    }
    return AppTheme.successColor;
  }

  Color _getAnalysisBackgroundColor() {
    return _getAnalysisColor().withOpacity(0.1);
  }

  IconData _getAnalysisIcon() {
    final result = recording.analysisResult!;
    if (result.isScam) {
      switch (result.riskLevel.toUpperCase()) {
        case 'CRITICAL':
          return Icons.dangerous;
        case 'HIGH':
          return Icons.warning;
        case 'MEDIUM':
          return Icons.info;
        default:
          return Icons.help_outline;
      }
    }
    return Icons.verified;
  }
}
