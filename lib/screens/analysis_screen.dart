import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/live_analysis_models.dart';
import '../models/call_recording_model.dart';
import '../providers/call_recording_provider.dart';
import '../services/live_analysis_service.dart';
import '../widgets/analysis_display_widget.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;
  ThreatLevel? _threatLevelFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Center',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Results',
          ),
          IconButton(
            onPressed: _exportAnalysis,
            icon: const Icon(Icons.download),
            tooltip: 'Export Analysis',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.radar),
              text: 'Live Analysis',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historical',
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveAnalysisTab(),
          _buildHistoricalAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildLiveAnalysisTab() {
    return StreamBuilder<LiveAnalysisSession>(
      stream: LiveAnalysisService.instance.sessionStream,
      builder: (context, snapshot) {
        final currentSession = snapshot.data;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveAnalysisStatus(),
              const SizedBox(height: 24),
              if (currentSession != null) ...[
                _buildCurrentSessionCard(currentSession),
                const SizedBox(height: 24),
                _buildRealTimeMetrics(currentSession),
                const SizedBox(height: 24),
                _buildLiveChunkResults(currentSession),
              ] else
                _buildNoActiveSessionCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveAnalysisStatus() {
    return StreamBuilder<bool>(
      stream: LiveAnalysisService.instance.analysisStateStream,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled 
                  ? AppTheme.successColor.withOpacity(0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.radar : Icons.radar_outlined,
                  color: isEnabled ? AppTheme.successColor : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnabled ? 'Live Analysis Active' : 'Live Analysis Inactive',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? AppTheme.successColor : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled 
                          ? 'Real-time scam detection is monitoring your calls'
                          : 'Enable live analysis to monitor incoming calls',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentSessionCard(LiveAnalysisSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThreatLevel.fromPercentage(session.overallScamProbability).color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.isIncoming ? Icons.call_received : Icons.call_made,
                color: session.isIncoming ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                session.phoneNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (session.isActive)
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 1.5.seconds),
            ],
          ),
          const SizedBox(height: 16),
          AnalysisDisplayWidget(
            session: session,
            isLiveMode: true,
            showProgress: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics(LiveAnalysisSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-Time Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Chunks Processed',
                  '${session.chunkResults.length}',
                  Icons.analytics,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Avg Threat Level',
                  '${session.overallScamProbability.toStringAsFixed(1)}%',
                  Icons.security,
                  ThreatLevel.fromPercentage(session.overallScamProbability).color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Patterns Detected',
                  '${session.allDetectedPatterns.length}',
                  Icons.pattern,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Session Duration',
                  _formatDuration(_getSessionDuration(session)),
                  Icons.timer,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChunkResults(LiveAnalysisSession session) {
    if (session.chunkResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No chunk analysis results yet',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Live Chunk Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ...session.chunkResults.reversed.take(5).map((chunk) => 
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThreatLevel.fromPercentage(chunk.scamProbability).color.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ThreatLevel.fromPercentage(chunk.scamProbability).color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${chunk.chunkNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ThreatLevel.fromPercentage(chunk.scamProbability).color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chunk ${chunk.chunkNumber} • ${DateFormat('HH:mm:ss').format(chunk.analyzedAt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (chunk.detectedPatterns.isNotEmpty)
                          Text(
                            chunk.detectedPatterns.map((p) => p.name).join(', '),
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
                    '${chunk.scamProbability.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThreatLevel.fromPercentage(chunk.scamProbability).color,
                    ),
                  ),
                ],
              ),
            ).animate(delay: (100).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2, end: 0),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNoActiveSessionCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.radar_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Analysis Session',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a call or enable live analysis to see real-time scam detection results',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalAnalysisTab() {
    final recordingsAsync = ref.watch(callRecordingProvider);

    return recordingsAsync.when(
      data: (recordings) {
        final filteredRecordings = _filterRecordings(recordings);
        return Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: filteredRecordings.isEmpty
                  ? _buildEmptyHistoryState()
                  : _buildHistoricalList(filteredRecordings),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading recordings: $error'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedFilter == 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('High Risk', _selectedFilter == 'High Risk'),
            const SizedBox(width: 8),
            _buildFilterChip('Medium Risk', _selectedFilter == 'Medium Risk'),
            const SizedBox(width: 8),
            _buildFilterChip('Low Risk', _selectedFilter == 'Low Risk'),
            const SizedBox(width: 8),
            _buildFilterChip('Incoming', _selectedFilter == 'Incoming'),
            const SizedBox(width: 8),
            _buildFilterChip('Outgoing', _selectedFilter == 'Outgoing'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? label : 'All';
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record some calls to see analysis results here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalList(List<CallRecording> recordings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        final recording = recordings[index];
        return _buildHistoricalAnalysisCard(recording, index);
      },
    );
  }

  Widget _buildHistoricalAnalysisCard(CallRecording recording, int index) {
    // Mock analysis data - in real app this would come from the recording
    final mockScamProbability = (recording.phoneNumber.hashCode % 100).toDouble();
    final threatLevel = ThreatLevel.fromPercentage(mockScamProbability);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: threatLevel.color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailedAnalysis(recording),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      recording.isIncoming ? Icons.call_received : Icons.call_made,
                      color: recording.isIncoming ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recording.phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: threatLevel.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        threatLevel.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: threatLevel.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(recording.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${recording.formattedDuration}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${mockScamProbability.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: threatLevel.color,
                          ),
                        ),
                        const Text(
                          'Scam Risk',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms)
      .fadeIn(duration: 300.ms)
      .slideX(begin: 0.2, end: 0);
  }

  List<CallRecording> _filterRecordings(List<CallRecording> recordings) {
    var filtered = recordings;

    // Apply filter
    switch (_selectedFilter) {
      case 'High Risk':
        filtered = filtered.where((r) =>
          (r.phoneNumber.hashCode % 100) > 70).toList();
        break;
      case 'Medium Risk':
        filtered = filtered.where((r) {
          final risk = r.phoneNumber.hashCode % 100;
          return risk >= 30 && risk <= 70;
        }).toList();
        break;
      case 'Low Risk':
        filtered = filtered.where((r) =>
          (r.phoneNumber.hashCode % 100) < 30).toList();
        break;
      case 'Incoming':
        filtered = filtered.where((r) => r.isIncoming).toList();
        break;
      case 'Outgoing':
        filtered = filtered.where((r) => !r.isIncoming).toList();
        break;
    }

    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered.where((r) =>
        r.timestamp.isAfter(_dateRange!.start) &&
        r.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date Range'),
              subtitle: Text(_dateRange == null
                  ? 'All dates'
                  : '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}'),
              trailing: const Icon(Icons.date_range),
              onTap: _selectDateRange,
            ),
            const Divider(),
            const Text('Threat Level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ThreatLevel.values.map((level) =>
                FilterChip(
                  label: Text(level.label),
                  selected: _threatLevelFilter == level,
                  onSelected: (selected) {
                    setState(() {
                      _threatLevelFilter = selected ? level : null;
                    });
                  },
                  selectedColor: level.color.withOpacity(0.2),
                  checkmarkColor: level.color,
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = null;
                _threatLevelFilter = null;
                _selectedFilter = 'All';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showDetailedAnalysis(CallRecording recording) {
    // This would show the detailed analysis modal from call_history_screen.dart
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analysis Details'),
        content: Text('Detailed analysis for ${recording.phoneNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Duration _getSessionDuration(LiveAnalysisSession session) {
    final endTime = session.endedAt ?? DateTime.now();
    return endTime.difference(session.startedAt);
  }
}
