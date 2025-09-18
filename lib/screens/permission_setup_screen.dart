import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../services/permission_service.dart';
import '../providers/app_state_provider.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});
  
  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final permissions = PermissionService.instance.requiredPermissions;
    
    for (final permission in permissions) {
      final status = await PermissionService.instance.checkPermission(permission);
      setState(() {
        _permissionStatuses[permission] = status;
      });
    }
  }
  
  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    final allGranted = await PermissionService.instance.requestAllPermissions();
    
    await _checkPermissions();
    
    setState(() {
      _isLoading = false;
    });
    
    if (allGranted) {
      ref.read(appStateProvider.notifier).setPermissionsGranted(true);
      if (mounted) context.go('/home');
    } else {
      _showPermissionDialog();
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Some permissions were not granted. The app may not function properly without them. '
          'You can grant them later in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.instance.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: _buildPermissionsList(),
              ),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.security,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ).animate()
          .scale(curve: Curves.elasticOut, duration: 0.8.seconds),
        
        const SizedBox(height: 24),
        
        Text(
          'Permissions Setup',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 0.2.seconds)
          .fadeIn(duration: 0.6.seconds)
          .slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 12),
        
        Text(
          'SCAI Guard needs these permissions to protect you from scam calls',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 0.4.seconds)
          .fadeIn(duration: 0.6.seconds)
          .slideY(begin: 0.3, end: 0),
      ],
    );
  }
  
  Widget _buildPermissionsList() {
    final permissions = PermissionService.instance.requiredPermissions;
    
    return ListView.builder(
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        final status = _permissionStatuses[permission] ?? PermissionStatus.denied;
        
        return _buildPermissionItem(permission, status, index);
      },
    );
  }
  
  Widget _buildPermissionItem(Permission permission, PermissionStatus status, int index) {
    IconData icon;
    String title;
    Color statusColor;
    IconData statusIcon;
    
    switch (permission) {
      case Permission.phone:
        icon = Icons.phone;
        title = 'Phone Access';
        break;
      case Permission.microphone:
        icon = Icons.mic;
        title = 'Microphone';
        break;
      case Permission.storage:
        icon = Icons.storage;
        title = 'Storage';
        break;
      case Permission.contacts:
        icon = Icons.contacts;
        title = 'Contacts';
        break;
      case Permission.sms:
        icon = Icons.sms;
        title = 'SMS';
        break;
      case Permission.notification:
        icon = Icons.notifications;
        title = 'Notifications';
        break;
      default:
        icon = Icons.security;
        title = 'System Permission';
    }
    
    switch (status) {
      case PermissionStatus.granted:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case PermissionStatus.denied:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      case PermissionStatus.permanentlyDenied:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          PermissionService.instance.getPermissionDescription(permission),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
      .fadeIn(duration: 0.5.seconds)
      .slideX(begin: 0.2, end: 0);
  }
  
  Widget _buildContinueButton() {
    final allGranted = _permissionStatuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
    
    return Column(
      children: [
        if (!allGranted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestAllPermissions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Grant Permissions'),
            ),
          ).animate()
            .fadeIn(duration: 0.6.seconds)
            .slideY(begin: 0.3, end: 0),
        
        if (allGranted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(appStateProvider.notifier).setPermissionsGranted(true);
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.successColor,
              ),
              child: const Text('Continue to App'),
            ),
          ).animate()
            .fadeIn(duration: 0.6.seconds)
            .slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(
            'Skip for now',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}