import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/call_recording_model.dart';
import '../providers/call_recording_provider.dart';
import '../widgets/call_recording_item.dart';
import '../widgets/filter_bottom_sheet.dart';

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
    // TODO: Navigate to recording details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Show details for ${recording.phoneNumber}')),
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
