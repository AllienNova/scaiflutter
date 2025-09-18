import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/call_recording_model.dart';
import '../models/live_analysis_models.dart';
import '../providers/call_recording_provider.dart';
import '../services/backend_api_service.dart';
import '../widgets/call_recording_item.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/analysis_display_widget.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  String _selectedFilter = 'all';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Load call recordings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callRecordingProvider.notifier).loadRecordings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordingsAsync = ref.watch(callRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter recordings',
          ),
          IconButton(
            onPressed: () {
              ref.read(callRecordingProvider.notifier).loadRecordings();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: recordingsAsync.when(
        data: (recordings) => _buildRecordingsList(recordings),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildRecordingsList(List<CallRecording> recordings) {
    final filteredRecordings = _filterRecordings(recordings);

    if (filteredRecordings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(callRecordingProvider.notifier).loadRecordings();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecordings.length,
        itemBuilder: (context, index) {
          final recording = filteredRecordings[index];
          return CallRecordingItem(
            recording: recording,
            onTap: () => _showRecordingDetails(recording),
            onPlay: () => _playRecording(recording),
            onAnalyze: () => _analyzeRecording(recording),
          ).animate(delay: (index * 100).ms)
            .fadeIn(duration: 600.ms)
            .slideX(begin: 0.2, end: 0);
        },
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
          Text('Loading call recordings...'),
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
            'Error loading recordings',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_callback_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ).animate()
            .scale(duration: 0.6.seconds, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'No call recordings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ).animate(delay: 0.2.seconds)
            .fadeIn(duration: 0.6.seconds),
          const SizedBox(height: 8),
          Text(
            'Your call recordings will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ).animate(delay: 0.4.seconds)
            .fadeIn(duration: 0.6.seconds),
        ],
      ),
    );
  }

  List<CallRecording> _filterRecordings(List<CallRecording> recordings) {
    var filtered = recordings;

    // Filter by call type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((recording) {
        switch (_selectedFilter) {
          case 'incoming':
            return recording.isIncoming;
          case 'outgoing':
            return !recording.isIncoming;
          case 'scam':
            return recording.analysisResult?.isScam == true;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((recording) {
        return recording.timestamp.isAfter(_selectedDateRange!.start) &&
               recording.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedFilter: _selectedFilter,
        selectedDateRange: _selectedDateRange,
        onFilterChanged: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        onDateRangeChanged: (dateRange) {
          setState(() {
            _selectedDateRange = dateRange;
          });
        },
      ),
    );
  }

  void _showRecordingDetails(CallRecording recording) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecordingAnalysisModal(recording: recording),
    );
  }

  void _playRecording(CallRecording recording) {
    // TODO: Implement audio playback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing recording: ${recording.fileName}')),
    );
  }

  void _analyzeRecording(CallRecording recording) {
    ref.read(callRecordingProvider.notifier).analyzeRecording(recording.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting analysis...')),
    );
  }
}

/// Modal for displaying recording analysis with re-analysis capability
class _RecordingAnalysisModal extends StatefulWidget {
  final CallRecording recording;

  const _RecordingAnalysisModal({required this.recording});

  @override
  State<_RecordingAnalysisModal> createState() => _RecordingAnalysisModalState();
}

class _RecordingAnalysisModalState extends State<_RecordingAnalysisModal> {
  List<ChunkAnalysisResult> _chunkResults = [];
  bool _isAnalyzing = false;
  int _processedChunks = 0;
  int _totalChunks = 0;
  String _analysisStatus = 'Ready to analyze';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Recording Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecordingInfo(),
                    const SizedBox(height: 16),
                    _buildAnalysisSection(),
                    const SizedBox(height: 16),
                    if (_chunkResults.isNotEmpty) _buildChunkResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.recording.isIncoming ? Icons.call_received : Icons.call_made,
                color: widget.recording.isIncoming ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.recording.phoneNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                widget.recording.formattedDuration,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(widget.recording.timestamp),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'File: ${widget.recording.fileName}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chunk Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyze this recording in 10-second chunks for detailed scam detection',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _analysisStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$_processedChunks / $_totalChunks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _totalChunks > 0 ? _processedChunks / _totalChunks : 0.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startReAnalysis,
                icon: const Icon(Icons.analytics),
                label: Text(_chunkResults.isEmpty ? 'Start Analysis' : 'Re-analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChunkResults() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Analysis Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (_chunkResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnalysisDisplayWidget(
                latestResult: _chunkResults.last,
                isLiveMode: false,
                showProgress: false,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Chunk Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._chunkResults.map((chunk) => Container(
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
                          'Chunk ${chunk.chunkNumber} (${chunk.chunkDuration.inSeconds}s)',
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
            )),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _startReAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _chunkResults.clear();
      _processedChunks = 0;
      _totalChunks = 5; // Simulate 5 chunks
      _analysisStatus = 'Starting analysis...';
    });

    try {
      final results = await BackendApiService.instance.reAnalyzeRecording(
        widget.recording.filePath,
        callId: widget.recording.id,
        phoneNumber: widget.recording.phoneNumber,
        isIncoming: widget.recording.isIncoming,
      );

      // Simulate progressive updates
      for (int i = 0; i < results.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _chunkResults.add(results[i]);
            _processedChunks = i + 1;
            _analysisStatus = 'Processed chunk ${i + 1} of ${results.length}';
          });
        }
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = 'Analysis complete';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = 'Analysis failed: $error';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
