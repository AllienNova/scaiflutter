import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/live_analysis_models.dart';

/// Reusable widget for displaying scam analysis results
/// Fixed height, no scrolling, works in both live and historical contexts
class AnalysisDisplayWidget extends StatelessWidget {
  final LiveAnalysisSession? session;
  final ChunkAnalysisResult? latestResult;
  final bool isLiveMode;
  final bool showProgress;
  final VoidCallback? onTap;

  const AnalysisDisplayWidget({
    super.key,
    this.session,
    this.latestResult,
    this.isLiveMode = false,
    this.showProgress = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280, // Fixed height to prevent layout shifts
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getThreatColor().withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getThreatColor().withOpacity(0.1),
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
            _buildThreatIndicator(),
            const SizedBox(height: 16),
            _buildPatterns(),
            const Spacer(),
            if (showProgress) _buildProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          isLiveMode ? Icons.radio_button_checked : Icons.analytics,
          color: _getThreatColor(),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          isLiveMode ? 'Live Analysis' : 'Analysis Results',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (isLiveMode && session?.isActive == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2.seconds),
      ],
    );
  }

  Widget _buildThreatIndicator() {
    final scamProbability = _getScamProbability();
    final threatLevel = ThreatLevel.fromPercentage(scamProbability);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: threatLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: threatLevel.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getThreatIcon(threatLevel),
                color: threatLevel.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                threatLevel.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: threatLevel.color,
                ),
              ),
              const Spacer(),
              Text(
                '${scamProbability.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: threatLevel.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: scamProbability / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(threatLevel.color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildPatterns() {
    final patterns = _getDetectedPatterns();
    
    if (patterns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'No suspicious patterns detected',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected Patterns:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...patterns.take(3).map((pattern) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pattern.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(pattern.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        )),
        if (patterns.length > 3)
          Text(
            '+${patterns.length - 3} more patterns',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildProgress() {
    if (!isLiveMode || session == null) {
      return const SizedBox.shrink();
    }

    final progress = session!.progress;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                progress.progressText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.progressPercentage,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  double _getScamProbability() {
    if (session != null) {
      return session!.overallScamProbability;
    }
    if (latestResult != null) {
      return latestResult!.scamProbability;
    }
    return 0.0;
  }

  List<ScamPattern> _getDetectedPatterns() {
    if (session != null) {
      return session!.allDetectedPatterns;
    }
    if (latestResult != null) {
      return latestResult!.detectedPatterns;
    }
    return [];
  }

  Color _getThreatColor() {
    final scamProbability = _getScamProbability();
    return ThreatLevel.fromPercentage(scamProbability).color;
  }

  IconData _getThreatIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Icons.check_circle;
      case ThreatLevel.medium:
        return Icons.warning;
      case ThreatLevel.high:
        return Icons.error;
      case ThreatLevel.critical:
        return Icons.dangerous;
    }
  }
}

/// Compact version of the analysis display for smaller spaces
class CompactAnalysisDisplayWidget extends StatelessWidget {
  final LiveAnalysisSession? session;
  final ChunkAnalysisResult? latestResult;
  final bool isLiveMode;

  const CompactAnalysisDisplayWidget({
    super.key,
    this.session,
    this.latestResult,
    this.isLiveMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final scamProbability = _getScamProbability();
    final threatLevel = ThreatLevel.fromPercentage(scamProbability);
    
    return Container(
      height: 60, // Fixed compact height
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: threatLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: threatLevel.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getThreatIcon(threatLevel),
            color: threatLevel.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  threatLevel.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: threatLevel.color,
                  ),
                ),
                if (isLiveMode && session?.progress != null)
                  Text(
                    session!.progress.status,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${scamProbability.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: threatLevel.color,
            ),
          ),
        ],
      ),
    );
  }

  double _getScamProbability() {
    if (session != null) {
      return session!.overallScamProbability;
    }
    if (latestResult != null) {
      return latestResult!.scamProbability;
    }
    return 0.0;
  }

  IconData _getThreatIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Icons.check_circle;
      case ThreatLevel.medium:
        return Icons.warning;
      case ThreatLevel.high:
        return Icons.error;
      case ThreatLevel.critical:
        return Icons.dangerous;
    }
  }
}
