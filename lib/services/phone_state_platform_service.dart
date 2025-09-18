import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class PhoneStatePlatformService {
  static final PhoneStatePlatformService _instance = PhoneStatePlatformService._internal();
  static PhoneStatePlatformService get instance => _instance;
  PhoneStatePlatformService._internal();

  final Logger _logger = Logger();
  
  static const MethodChannel _methodChannel = MethodChannel('com.scai.guard/phone_state');
  static const EventChannel _eventChannel = EventChannel('com.scai.guard/phone_state_events');
  
  StreamSubscription<dynamic>? _phoneStateSubscription;
  final StreamController<PhoneStateEvent> _phoneStateController = 
      StreamController<PhoneStateEvent>.broadcast();
  
  Stream<PhoneStateEvent> get phoneStateStream => _phoneStateController.stream;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  Future<void> startPhoneStateMonitoring() async {
    try {
      _logger.i('Starting phone state monitoring...');
      
      // Start monitoring on Android side
      final result = await _methodChannel.invokeMethod('startPhoneStateMonitoring');
      
      if (result == true) {
        // Listen to phone state events
        _phoneStateSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            _handlePhoneStateEvent(event);
          },
          onError: (error) {
            _logger.e('Phone state event error: $error');
          },
        );
        
        _isMonitoring = true;
        _logger.i('Phone state monitoring started successfully');
      } else {
        throw Exception('Failed to start phone state monitoring');
      }
    } catch (error) {
      _logger.e('Error starting phone state monitoring: $error');
      rethrow;
    }
  }

  Future<void> stopPhoneStateMonitoring() async {
    try {
      _logger.i('Stopping phone state monitoring...');
      
      // Cancel event subscription
      await _phoneStateSubscription?.cancel();
      _phoneStateSubscription = null;
      
      // Stop monitoring on Android side
      await _methodChannel.invokeMethod('stopPhoneStateMonitoring');
      
      _isMonitoring = false;
      _logger.i('Phone state monitoring stopped');
    } catch (error) {
      _logger.e('Error stopping phone state monitoring: $error');
    }
  }

  Future<bool> isPhoneStateMonitoringActive() async {
    try {
      final result = await _methodChannel.invokeMethod('isPhoneStateMonitoringActive');
      return result == true;
    } catch (error) {
      _logger.e('Error checking phone state monitoring status: $error');
      return false;
    }
  }

  void _handlePhoneStateEvent(dynamic event) {
    try {
      if (event is Map<dynamic, dynamic>) {
        final state = event['state'] as String?;
        final phoneNumber = event['phoneNumber'] as String?;
        final timestamp = event['timestamp'] as int?;
        
        if (state != null) {
          final phoneStateEvent = PhoneStateEvent(
            state: state,
            phoneNumber: phoneNumber,
            timestamp: timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : DateTime.now(),
          );
          
          _logger.i('Phone state event: ${phoneStateEvent.state}, number: ${phoneStateEvent.phoneNumber}');
          _phoneStateController.add(phoneStateEvent);
        }
      }
    } catch (error) {
      _logger.e('Error handling phone state event: $error');
    }
  }

  void dispose() {
    _phoneStateSubscription?.cancel();
    _phoneStateController.close();
  }
}

class PhoneStateEvent {
  final String state;
  final String? phoneNumber;
  final DateTime timestamp;

  PhoneStateEvent({
    required this.state,
    this.phoneNumber,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PhoneStateEvent(state: $state, phoneNumber: $phoneNumber, timestamp: $timestamp)';
  }
}

// Phone state constants matching Android implementation
class PhoneStateConstants {
  static const String CALL_STATE_IDLE = 'CALL_IDLE';
  static const String CALL_STATE_INCOMING = 'CALL_INCOMING';
  static const String CALL_STATE_STARTED = 'CALL_STARTED';
  static const String CALL_STATE_ENDED = 'CALL_ENDED';
}
