import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  static PermissionService get instance => _instance;
  PermissionService._internal();
  
  final Logger _logger = Logger();
  
  final List<Permission> _requiredPermissions = [
    // Core permissions for call recording
    Permission.microphone,
    Permission.notification,
    // Phone permissions for automatic call detection
    Permission.phone,
    // Temporarily disabled problematic permissions
    // Permission.storage,
    // Permission.contacts,
    // Permission.sms,
    // Permission.manageExternalStorage,
    // Permission.systemAlertWindow,
    // Permission.ignoreBatteryOptimizations,
  ];
  
  Future<bool> requestAllPermissions() async {
    try {
      _logger.i('Requesting permissions for automatic call recording...');

      final Map<Permission, PermissionStatus> statuses =
          await _requiredPermissions.request();

      bool allGranted = true;

      for (final entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;

        _logger.i('Permission ${permission.toString()}: ${status.toString()}');

        if (status != PermissionStatus.granted) {
          allGranted = false;

          if (status == PermissionStatus.permanentlyDenied) {
            _logger.w('Permission ${permission.toString()} permanently denied');
          }
        }
      }

      _logger.i('Essential permissions granted: $allGranted');
      return allGranted;
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      return false;
    }
  }
  
  Future<bool> checkAllPermissions() async {
    try {
      for (final permission in _requiredPermissions) {
        final status = await permission.status;
        if (status != PermissionStatus.granted) {
          return false;
        }
      }
      return true;
    } catch (e) {
      _logger.e('Error checking permissions: $e');
      return false;
    }
  }
  
  Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }
  
  Future<bool> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      _logger.e('Error requesting permission ${permission.toString()}: $e');
      return false;
    }
  }
  
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return 'Phone access is required to manage calls and detect incoming calls';
      case Permission.microphone:
        return 'Microphone access is required to record and analyze call audio';
      case Permission.storage:
        return 'Storage access is required to save call recordings';
      case Permission.contacts:
        return 'Contacts access is required to identify callers';
      case Permission.sms:
        return 'SMS access is required to analyze text messages for scams';
      case Permission.notification:
        return 'Notification access is required to alert you of potential scams';
      case Permission.manageExternalStorage:
        return 'External storage access is required to manage call recordings';
      case Permission.systemAlertWindow:
        return 'System alert access is required to show scam warnings during calls';
      case Permission.ignoreBatteryOptimizations:
        return 'Battery optimization exemption is required for continuous monitoring';
      default:
        return 'This permission is required for the app to function properly';
    }
  }
  
  List<Permission> get requiredPermissions => List.unmodifiable(_requiredPermissions);
}