import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/call_recording_model.dart';
import '../providers/call_recording_provider.dart';
import '../services/backend_api_service.dart';

class AnalysisReportsScreen extends ConsumerStatefulWidget {
  const AnalysisReportsScreen({super.key});

  @override
  ConsumerState<AnalysisReportsScreen> createState() => _AnalysisReportsScreenState();
}

class _AnalysisReportsScreenState extends ConsumerState<AnalysisReportsScreen> {
  bool _isLoadingServerData = false;

  @override
  Widget build(BuildContext context) {
    final recordingsAsync = ref.watch(callRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Reports',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _checkServerHealth,
            icon: const Icon(Icons.health_and_safety),
            tooltip: 'Check server health',
          ),
          IconButton(
            onPressed: _loadServerAnalysisHistory,
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Load server data',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: recordingsAsync.when(
        data: (recordings) => _buildAnalysisContent(recordings),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildAnalysisContent(List<CallRecording> recordings) {
    final analyzedRecordings = recordings.where((r) => r.analysisResult != null).toList();
    final scamRecordings = analyzedRecordings.where((r) => r.analysisResult!.isScam).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(recordings, analyzedRecordings, scamRecordings),
          const SizedBox(height: 24),
          _buildRecentAnalysis(analyzedRecordings),
          const SizedBox(height: 24),
          _buildScamTrends(scamRecordings),
          if (_isLoadingServerData) ...[
            const SizedBox(height: 24),
            _buildLoadingServerData(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    List<CallRecording> allRecordings,
    List<CallRecording> analyzedRecordings,
    List<CallRecording> scamRecordings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Calls',
                value: allRecordings.length.toString(),
                icon: Icons.phone,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Analyzed',
                value: analyzedRecordings.length.toString(),
                icon: Icons.analytics,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Scam Detected',
                value: scamRecordings.length.toString(),
                icon: Icons.warning,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Safe Calls',
                value: (analyzedRecordings.length - scamRecordings.length).toString(),
                icon: Icons.verified,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentAnalysis(List<CallRecording> analyzedRecordings) {
    final recentAnalysis = analyzedRecordings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to call history with analysis filter
                // TODO: Implement navigation
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentAnalysis.isEmpty)
          _buildEmptyAnalysis()
        else
          ...recentAnalysis.asMap().entries.map((entry) {
            final index = entry.key;
            final recording = entry.value;
            return _buildAnalysisItem(recording, index);
          }),
      ],
    );
  }

  Widget _buildAnalysisItem(CallRecording recording, int index) {
    final result = recording.analysisResult!;
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isScam ? AppTheme.errorColor.withOpacity(0.3) : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: result.isScam ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              result.isScam ? Icons.warning : Icons.verified,
              color: result.isScam ? AppTheme.errorColor : AppTheme.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.phoneNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.scamTypeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: result.isScam ? AppTheme.errorColor : AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: result.isScam ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.confidenceScore.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: result.isScam ? AppTheme.errorColor : AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(recording.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 600.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildScamTrends(List<CallRecording> scamRecordings) {
    final scamTypes = <String, int>{};
    for (final recording in scamRecordings) {
      final type = recording.analysisResult!.scamType;
      scamTypes[type] = (scamTypes[type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scam Types Detected',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (scamTypes.isEmpty)
          _buildNoScamsDetected()
        else
          ...scamTypes.entries.map((entry) => _buildScamTypeItem(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildScamTypeItem(String scamType, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getScamTypeDisplayName(scamType),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysis() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No analysis data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyze your call recordings to see insights here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoScamsDetected() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified,
            size: 48,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No scams detected!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your analyzed calls appear to be legitimate',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.successColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading analysis data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analysis data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(callRecordingProvider.notifier).loadRecordings();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingServerData() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Loading data from server...',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getScamTypeDisplayName(String scamType) {
    switch (scamType.toUpperCase()) {
      case 'ROBOCALL':
        return 'Robocall';
      case 'PHISHING':
        return 'Phishing';
      case 'TECH_SUPPORT':
        return 'Tech Support Scam';
      case 'IRS_SCAM':
        return 'IRS Scam';
      case 'LOTTERY_SCAM':
        return 'Lottery Scam';
      case 'ROMANCE_SCAM':
        return 'Romance Scam';
      case 'INVESTMENT_FRAUD':
        return 'Investment Fraud';
      case 'CHARITY_SCAM':
        return 'Charity Scam';
      default:
        return scamType;
    }
  }

  Future<void> _checkServerHealth() async {
    try {
      final isHealthy = await BackendApiService.instance.checkServerHealth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHealthy ? 'Server is healthy' : 'Server is not responding'),
            backgroundColor: isHealthy ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking server: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadServerAnalysisHistory() async {
    setState(() {
      _isLoadingServerData = true;
    });

    try {
      final serverHistory = await BackendApiService.instance.getAnalysisHistory(limit: 10);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${serverHistory.length} analysis records from server'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading server data: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServerData = false;
        });
      }
    }
  }
}
