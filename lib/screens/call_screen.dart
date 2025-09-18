import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../core/app_theme.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../services/audio_service.dart';
import '../widgets/scam_alert_widget.dart';
import '../widgets/analysis_indicator_widget.dart';
import '../widgets/call_controls_widget.dart';
import '../widgets/waveform_widget.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String contactName;
  final String phoneNumber;
  final bool isIncoming;
  
  const CallScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.isIncoming,
  });
  
  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scamAlertController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scamAlertAnimation;
  
  CallModel? currentCall;
  List<AnalysisResult> analysisResults = [];
  bool showScamAlert = false;
  double scamConfidence = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scamAlertController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scamAlertAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scamAlertController,
      curve: Curves.elasticOut,
    ));
    
    _listenToCallUpdates();
    _listenToAnalysisResults();
  }
  
  void _listenToCallUpdates() {
    CallService.instance.callStream.listen((call) {
      if (mounted) {
        setState(() {
          currentCall = call;
        });
      }
    });
  }
  
  void _listenToAnalysisResults() {
    AudioService.instance.analysisStream.listen((results) {
      if (mounted) {
        setState(() {
          analysisResults.addAll(results);
          
          final scamIndicators = results.where((r) => r.isScamIndicator).toList();
          if (scamIndicators.isNotEmpty) {
            final avgConfidence = scamIndicators
                .map((r) => r.confidence)
                .reduce((a, b) => a + b) / scamIndicators.length;
            
            scamConfidence = avgConfidence;
            showScamAlert = true;
            _scamAlertController.forward();
            _triggerHapticFeedback();
          }
        });
      }
    });
  }
  
  void _triggerHapticFeedback() {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.vibrate();
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scamAlertController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              showScamAlert 
                  ? AppTheme.errorColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildContactAvatar(),
                    const SizedBox(height: 24),
                    _buildContactInfo(),
                    const SizedBox(height: 16),
                    _buildCallStatus(),
                    const SizedBox(height: 32),
                    if (showScamAlert)
                      ScamAlertWidget(
                        confidence: scamConfidence,
                        analysisResults: analysisResults,
                      ).animate(controller: _scamAlertController)
                        .scale(curve: Curves.elasticOut),
                    const SizedBox(height: 32),
                    WaveformWidget(
                      isActive: currentCall?.status == CallStatus.active,
                    ),
                    const SizedBox(height: 24),
                    AnalysisIndicatorWidget(
                      analysisResults: analysisResults,
                    ),
                  ],
                ),
              ),
              _buildCallControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentCall?.status == CallStatus.active 
                        ? AppTheme.successColor 
                        : AppTheme.warningColor,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 1.seconds, curve: Curves.easeInOut)
                  .then()
                  .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0)),
                const SizedBox(width: 8),
                Text(
                  currentCall?.statusText ?? 'Connecting...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: currentCall?.status == CallStatus.active ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.contactName.isNotEmpty 
                    ? widget.contactName[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContactInfo() {
    return Column(
      children: [
        AutoSizeText(
          widget.contactName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          minFontSize: 20,
        ),
        const SizedBox(height: 8),
        Text(
          widget.phoneNumber,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCallStatus() {
    if (currentCall == null) return const SizedBox.shrink();
    
    String statusText = '';
    Color statusColor = AppTheme.textSecondary;
    
    switch (currentCall!.status) {
      case CallStatus.incoming:
        statusText = 'Incoming call...';
        statusColor = AppTheme.warningColor;
        break;
      case CallStatus.active:
        statusText = 'Call in progress • ${currentCall!.formattedDuration}';
        statusColor = AppTheme.successColor;
        break;
      case CallStatus.ended:
        statusText = 'Call ended';
        statusColor = AppTheme.textSecondary;
        break;
      case CallStatus.missed:
        statusText = 'Missed call';
        statusColor = AppTheme.errorColor;
        break;
      case CallStatus.rejected:
        statusText = 'Call rejected';
        statusColor = AppTheme.errorColor;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: CallControlsWidget(
        isIncoming: widget.isIncoming,
        onAccept: () {
          // Handle call accept
        },
        onReject: () {
          Navigator.of(context).pop();
        },
        onHangup: () {
          Navigator.of(context).pop();
        },
        onMute: () {
          // Handle mute toggle
        },
        onSpeaker: () {
          // Handle speaker toggle
        },
      ),
    );
  }
}