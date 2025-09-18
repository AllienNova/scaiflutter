import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';

class ProtectionStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 2.seconds)
                  .then()
                  .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protection Active',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      Text(
                        'AI monitoring enabled',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Calls Protected',
                      '0',
                      Icons.phone_callback,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.borderColor,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Scams Blocked',
                      '0',
                      Icons.block,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}