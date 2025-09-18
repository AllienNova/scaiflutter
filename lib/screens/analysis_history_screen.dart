import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'No analysis data yet',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Make a call to see real-time analysis',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}