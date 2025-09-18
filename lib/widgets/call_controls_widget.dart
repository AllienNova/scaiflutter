import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';

class CallControlsWidget extends StatefulWidget {
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onHangup;
  final VoidCallback? onMute;
  final VoidCallback? onSpeaker;
  
  const CallControlsWidget({
    super.key,
    required this.isIncoming,
    this.onAccept,
    this.onReject,
    this.onHangup,
    this.onMute,
    this.onSpeaker,
  });
  
  @override
  State<CallControlsWidget> createState() => _CallControlsWidgetState();
}

class _CallControlsWidgetState extends State<CallControlsWidget> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  
  @override
  Widget build(BuildContext context) {
    if (widget.isIncoming) {
      return _buildIncomingCallControls();
    } else {
      return _buildActiveCallControls();
    }
  }
  
  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRejectButton(),
        const SizedBox(width: 40),
        _buildAcceptButton(),
      ],
    );
  }
  
  Widget _buildActiveCallControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMuteButton(),
            _buildSpeakerButton(),
            _buildAddCallButton(),
          ],
        ),
        const SizedBox(height: 24),
        _buildHangupButton(),
      ],
    );
  }
  
  Widget _buildAcceptButton() {
    return GestureDetector(
      onTap: widget.onAccept,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.successColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.successColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.call,
          color: Colors.white,
          size: 32,
        ),
      ).animate(onPlay: (controller) => controller.repeat())
        .scale(duration: 1.5.seconds, curve: Curves.easeInOut)
        .then()
        .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0)),
    );
  }
  
  Widget _buildRejectButton() {
    return GestureDetector(
      onTap: widget.onReject,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildHangupButton() {
    return GestureDetector(
      onTap: widget.onHangup,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
  
  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isMuted = !isMuted;
        });
        widget.onMute?.call();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isMuted ? AppTheme.errorColor : AppTheme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isMuted ? AppTheme.errorColor : AppTheme.borderColor,
          ),
        ),
        child: Icon(
          isMuted ? Icons.mic_off : Icons.mic,
          color: isMuted ? Colors.white : AppTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildSpeakerButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSpeakerOn = !isSpeakerOn;
        });
        widget.onSpeaker?.call();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSpeakerOn ? AppTheme.primaryColor : AppTheme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSpeakerOn ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Icon(
          isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          color: isSpeakerOn ? Colors.white : AppTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildAddCallButton() {
    return GestureDetector(
      onTap: () {
        // Handle add call
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Icon(
          Icons.add_call,
          color: AppTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}