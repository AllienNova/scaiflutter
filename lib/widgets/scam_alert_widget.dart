import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/call_model.dart';

class ScamAlertWidget extends StatelessWidget {
  final double confidence;
  final List<AnalysisResult> analysisResults;
  
  const ScamAlertWidget({
    super.key,
    required this.confidence,
    required this.analysisResults,
  });
  
  @override
  Widget build(BuildContext context) {
    final scamIndicators = analysisResults
        .where((result) => result.isScamIndicator)
        .toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .shake(duration: 0.5.seconds)
                .then(delay: 1.seconds),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCAM ALERT',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Potential scam detected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confidence * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (scamIndicators.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Threats:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...scamIndicators.take(3).map((indicator) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getIndicatorDescription(indicator),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle block caller
                  },
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Block'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.errorColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle report scam
                  },
                  icon: const Icon(Icons.report, size: 16),
                  label: const Text('Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
  
  String _getIndicatorDescription(AnalysisResult indicator) {
    switch (indicator.type) {
      case AnalysisType.deepfakeDetection:
        return 'Voice deepfake detected';
      case AnalysisType.sentimentAnalysis:
        return 'High-pressure tactics detected';
      case AnalysisType.scamPatternDetection:
        final patterns = indicator.details['detected_patterns'] as List<dynamic>?;
        if (patterns?.isNotEmpty == true) {
          return 'Scam keyword: "${patterns!.first}"';
        }
        return 'Scam pattern detected';
      case AnalysisType.voiceAuthentication:
        return 'Synthetic voice detected';
      default:
        return 'Suspicious activity detected';
    }
  }
}