import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/call_model.dart';

class CallHistoryWidget extends StatelessWidget {
  const CallHistoryWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Call History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Refresh call history
                },
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildEmptyState(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
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
            'No calls yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ).animate(delay: 0.2.seconds)
            .fadeIn(duration: 0.6.seconds),
          const SizedBox(height: 8),
          Text(
            'Your call history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ).animate(delay: 0.4.seconds)
            .fadeIn(duration: 0.6.seconds),
        ],
      ),
    );
  }
  
  Widget _buildCallItem(BuildContext context, CallModel call) {
    IconData icon;
    Color iconColor;
    
    switch (call.status) {
      case CallStatus.incoming:
        icon = Icons.call_received;
        iconColor = AppTheme.successColor;
        break;
      case CallStatus.active:
        icon = Icons.phone_in_talk;
        iconColor = AppTheme.primaryColor;
        break;
      case CallStatus.ended:
        icon = call.isIncoming ? Icons.call_received : Icons.call_made;
        iconColor = AppTheme.textSecondary;
        break;
      case CallStatus.missed:
        icon = Icons.call_received;
        iconColor = AppTheme.errorColor;
        break;
      case CallStatus.rejected:
        icon = Icons.call_end;
        iconColor = AppTheme.errorColor;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          call.contactName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call.phoneNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (call.isScamSuspected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SCAM DETECTED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(call.startTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            if (call.duration != null)
              Text(
                call.formattedDuration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        onTap: () {
          // Show call details
        },
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (callDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}