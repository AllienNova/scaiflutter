import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';

class QuickActionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6, // Slightly wider to reduce height
              children: [
                _buildActionCard(
                  context,
                  'Test Call',
                  Icons.phone_in_talk,
                  AppTheme.primaryColor,
                  () {
                    context.push('/call', extra: {
                      'contactName': 'Test Contact',
                      'phoneNumber': '+1234567890',
                      'isIncoming': true,
                    });
                  },
                ).animate(delay: 0.1.seconds)
                  .fadeIn(duration: 0.5.seconds)
                  .slideX(begin: -0.2, end: 0),
                
                _buildActionCard(
                  context,
                  'Settings',
                  Icons.settings,
                  AppTheme.secondaryColor,
                  () => context.push('/settings'),
                ).animate(delay: 0.2.seconds)
                  .fadeIn(duration: 0.5.seconds)
                  .slideX(begin: 0.2, end: 0),
                
                _buildActionCard(
                  context,
                  'Analysis History',
                  Icons.analytics,
                  AppTheme.warningColor,
                  () => context.push('/analysis-history'),
                ).animate(delay: 0.3.seconds)
                  .fadeIn(duration: 0.5.seconds)
                  .slideX(begin: -0.2, end: 0),
                
                _buildActionCard(
                  context,
                  'Blocked Numbers',
                  Icons.block,
                  AppTheme.errorColor,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')),
                    );
                  },
                ).animate(delay: 0.4.seconds)
                  .fadeIn(duration: 0.5.seconds)
                  .slideX(begin: 0.2, end: 0),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16 to 12
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24, // Reduced from 28 to 24
              ),
              const SizedBox(height: 6), // Reduced from 8 to 6
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}