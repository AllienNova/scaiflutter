import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/call_model.dart';

class AnalysisIndicatorWidget extends StatelessWidget {
  final List<AnalysisResult> analysisResults;
  
  const AnalysisIndicatorWidget({
    super.key,
    required this.analysisResults,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live Analysis',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: analysisResults.isNotEmpty ? AppTheme.successColor : AppTheme.textTertiary,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 1.seconds)
                .then()
                .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisGrid(context),
        ],
      ),
    );
  }
  
  Widget _buildAnalysisGrid(BuildContext context) {
    final analysisTypes = [
      AnalysisType.deepfakeDetection,
      AnalysisType.sentimentAnalysis,
      AnalysisType.scamPatternDetection,
      AnalysisType.voiceAuthentication,
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: analysisTypes.length,
      itemBuilder: (context, index) {
        final type = analysisTypes[index];
        final result = analysisResults
            .where((r) => r.type == type)
            .fold<AnalysisResult?>(null, (prev, curr) {
          if (prev == null) return curr;
          return curr.timestamp.isAfter(prev.timestamp) ? curr : prev;
        });
        
        return _buildAnalysisItem(context, type, result);
      },
    );
  }
  
  Widget _buildAnalysisItem(BuildContext context, AnalysisType type, AnalysisResult? result) {
    final hasResult = result != null;
    final isScamIndicator = hasResult && result.isScamIndicator;
    
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String label;
    
    switch (type) {
      case AnalysisType.deepfakeDetection:
        icon = Icons.face_retouching_natural;
        label = 'Deepfake';
        break;
      case AnalysisType.sentimentAnalysis:
        icon = Icons.sentiment_satisfied_alt;
        label = 'Sentiment';
        break;
      case AnalysisType.scamPatternDetection:
        icon = Icons.pattern;
        label = 'Patterns';
        break;
      case AnalysisType.voiceAuthentication:
        icon = Icons.verified_user;
        label = 'Auth';
        break;
      default:
        icon = Icons.analytics;
        label = 'Analysis';
    }
    
    if (!hasResult) {
      backgroundColor = AppTheme.textTertiary.withOpacity(0.1);
      textColor = AppTheme.textTertiary;
      iconColor = AppTheme.textTertiary;
    } else if (isScamIndicator) {
      backgroundColor = AppTheme.errorColor.withOpacity(0.1);
      textColor = AppTheme.errorColor;
      iconColor = AppTheme.errorColor;
    } else {
      backgroundColor = AppTheme.successColor.withOpacity(0.1);
      textColor = AppTheme.successColor;
      iconColor = AppTheme.successColor;
    }
    
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasResult) ...[
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isScamIndicator ? AppTheme.errorColor : AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
    
    if (isScamIndicator) {
      child = child.animate(onPlay: (controller) => controller.repeat())
        .shake(duration: 0.5.seconds, delay: 0.5.seconds);
    }
    
    return child;
  }
}