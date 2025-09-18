import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'Contact management coming soon',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}