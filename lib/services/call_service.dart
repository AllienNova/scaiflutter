import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/call_model.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../services/phone_state_platform_service.dart';

// Real phone state implementation using platform channels
class PhoneStateStatus {
  final String status;
  final String? number;
  PhoneStateStatus(this.status, this.number);
}

class PhoneState {
  static const String CALL_INCOMING = 'CALL_INCOMING';
  static const String CALL_STARTED = 'CALL_STARTED';
  static const String CALL_ENDED = 'CALL_ENDED';
  static const String NOTHING = 'NOTHING';

  static Stream<PhoneStateStatus> get phoneStateStream {
    return PhoneStatePlatformService.instance.phoneStateStream.map((event) {
      String status;
      switch (event.state) {
        case PhoneStateConstants.CALL_STATE_INCOMING:
          status = CALL_INCOMING;
          break;
        case PhoneStateConstants.CALL_STATE_STARTED:
          status = CALL_STARTED;
          break;
        case PhoneStateConstants.CALL_STATE_ENDED:
          status = CALL_ENDED;
          break;
        default:
          status = NOTHING;
          break;
      }
      return PhoneStateStatus(status, event.phoneNumber);
    });
  }
}

class Contact {
  final String? displayName;
  final List<Phone>? phones;
  Contact({this.displayName, this.phones});
}

class Phone {
  final String? value;
  Phone({this.value});
}

class ContactsService {
  static Future<List<Contact>> getContacts() async {
    return []; // Return empty list for now
  }
}

class CallLogEntry {
  final String? number;
  final String? name;
  final int? timestamp;
  final int? duration;
  final String? callType;

  CallLogEntry({this.number, this.name, this.timestamp, this.duration, this.callType});
}

class CallLog {
  static Future<List<CallLogEntry>> get() async {
    return []; // Return empty list for now
  }
}

class CallService {
  static final CallService _instance = CallService._internal();
  static CallService get instance => _instance;
  CallService._internal();
  
  final Logger _logger = Logger();
  StreamSubscription<PhoneStateStatus>? _phoneStateSubscription;
  
  final StreamController<CallModel> _callStreamController = 
      StreamController<CallModel>.broadcast();
  Stream<CallModel> get callStream => _callStreamController.stream;
  
  final StreamController<PhoneStateStatus> _phoneStateController = 
      StreamController<PhoneStateStatus>.broadcast();
  Stream<PhoneStateStatus> get phoneStateStream => _phoneStateController.stream;
  
  CallModel? _currentCall;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('Initializing CallService...');

      // Start platform phone state monitoring
      await PhoneStatePlatformService.instance.startPhoneStateMonitoring();

      _phoneStateSubscription = PhoneState.phoneStateStream.listen(
        _handlePhoneStateChange,
        onError: (error) {
          _logger.e('Phone state stream error: $error');
        },
      );

      _isInitialized = true;
      _logger.i('CallService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize CallService: $e');
      rethrow;
    }
  }
  
  void _handlePhoneStateChange(PhoneStateStatus status) {
    _logger.i('Phone state changed: ${status.status}');
    _phoneStateController.add(status);
    
    switch (status.status) {
      case PhoneState.CALL_INCOMING:
        _handleIncomingCall(status.number);
        break;
      case PhoneState.CALL_STARTED:
        _handleCallStarted(status.number);
        break;
      case PhoneState.CALL_ENDED:
        _handleCallEnded();
        break;
      case PhoneState.NOTHING:
        _handleCallIdle();
        break;
    }
  }
  
  Future<void> _handleIncomingCall(String? number) async {
    if (number == null || number.isEmpty) return;
    
    try {
      final contact = await _getContactByNumber(number);
      
      _currentCall = CallModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: number,
        contactName: contact?.displayName ?? 'Unknown',
        isIncoming: true,
        startTime: DateTime.now(),
        status: CallStatus.incoming,
      );
      
      _callStreamController.add(_currentCall!);
      _logger.i('Incoming call from: $number');
    } catch (e) {
      _logger.e('Error handling incoming call: $e');
    }
  }
  
  Future<void> _handleCallStarted(String? number) async {
    if (number == null || number.isEmpty) return;
    
    try {
      if (_currentCall == null) {
        final contact = await _getContactByNumber(number);
        
        _currentCall = CallModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          phoneNumber: number,
          contactName: contact?.displayName ?? 'Unknown',
          isIncoming: false,
          startTime: DateTime.now(),
          status: CallStatus.active,
        );
      } else {
        _currentCall = _currentCall!.copyWith(
          status: CallStatus.active,
          startTime: DateTime.now(),
        );
      }
      
      _callStreamController.add(_currentCall!);

      // Start call recording
      await AudioService.instance.startCallRecording(
        _currentCall!.phoneNumber,
        _currentCall!.isIncoming,
      );

      _logger.i('Call started with: $number');
    } catch (e) {
      _logger.e('Error handling call started: $e');
    }
  }
  
  Future<void> _handleCallEnded() async {
    if (_currentCall == null) return;
    
    try {
      _currentCall = _currentCall!.copyWith(
        status: CallStatus.ended,
        endTime: DateTime.now(),
        duration: Duration(
          milliseconds: DateTime.now().difference(_currentCall!.startTime).inMilliseconds,
        ),
      );
      
      _callStreamController.add(_currentCall!);

      // Stop call recording
      await AudioService.instance.stopCallRecording();

      await DatabaseService.instance.insertCall(_currentCall!);
      
      _logger.i('Call ended: ${_currentCall!.phoneNumber}');
      _currentCall = null;
    } catch (e) {
      _logger.e('Error handling call ended: $e');
    }
  }
  
  void _handleCallIdle() {
    if (_currentCall != null) {
      _logger.i('Phone returned to idle state');
    }
  }
  
  Future<Contact?> _getContactByNumber(String phoneNumber) async {
    try {
      final contacts = await ContactsService.getContacts();
      
      for (final contact in contacts) {
        if (contact.phones?.isNotEmpty == true) {
          for (final phone in contact.phones!) {
            final cleanContactNumber = _cleanPhoneNumber(phone.value ?? '');
            final cleanInputNumber = _cleanPhoneNumber(phoneNumber);
            
            if (cleanContactNumber == cleanInputNumber ||
                cleanContactNumber.endsWith(cleanInputNumber) ||
                cleanInputNumber.endsWith(cleanContactNumber)) {
              return contact;
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error getting contact by number: $e');
    }
    
    return null;
  }
  
  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }
  
  Future<List<CallLogEntry>> getCallHistory({int limit = 100}) async {
    try {
      final entries = await CallLog.get();
      return entries.take(limit).toList();
    } catch (e) {
      _logger.e('Error getting call history: $e');
      return [];
    }
  }
  
  Future<void> makeCall(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      await SystemChannels.platform.invokeMethod('url_launcher', {
        'url': uri.toString(),
        'enableJavaScript': false,
        'enableDomStorage': false,
        'universalLinksOnly': false,
        'headers': <String, String>{},
      });
    } catch (e) {
      _logger.e('Error making call: $e');
      rethrow;
    }
  }
  
  CallModel? get currentCall => _currentCall;
  
  bool get isCallActive => _currentCall?.status == CallStatus.active;
  
  void dispose() {
    _phoneStateSubscription?.cancel();
    PhoneStatePlatformService.instance.stopPhoneStateMonitoring();
    _callStreamController.close();
    _phoneStateController.close();
    _isInitialized = false;
  }
}