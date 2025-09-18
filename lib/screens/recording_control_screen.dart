import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../services/recording_mode_service.dart';
import '../services/call_recording_service.dart';
import '../providers/call_recording_provider.dart';

class RecordingControlScreen extends ConsumerStatefulWidget {
  const RecordingControlScreen({super.key});

  @override
  ConsumerState<RecordingControlScreen> createState() => _RecordingControlScreenState();
}

class _RecordingControlScreenState extends ConsumerState<RecordingControlScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  RecordingMode _selectedMode = RecordingMode.manual;
  DemoScenario _selectedScenario = DemoScenario.legitimateCall;
  bool _isIncoming = true;
  String _statusMessage = 'Ready to record';

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+1 (555) 123-4567';
    _nameController.text = 'Test Contact';

    // Set up the ref for RecordingModeService to refresh providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RecordingModeService.instance.setRef(ref);
    });

    // Listen to status updates
    RecordingModeService.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showSystemAppGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System App Installation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To enable full call recording (both sides of conversation), SCAI must be installed as a system app.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Rooted Android device'),
              const Text('• ADB (Android Debug Bridge)'),
              const Text('• USB debugging enabled'),
              const SizedBox(height: 16),
              const Text(
                'Current Capability:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• ✅ Phone call detection'),
              const Text('• ✅ Automatic recording triggers'),
              const Text('• ⚠️ Microphone audio only'),
              const Text('• ❌ Full call recording (requires system app)'),
              const SizedBox(height: 16),
              const Text(
                'See SYSTEM_APP_INSTALLATION_GUIDE.md in the project root for detailed installation instructions.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recording Control',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildModeSelector(),
            const SizedBox(height: 24),
            if (_selectedMode == RecordingMode.manual) _buildManualControls(),
            if (_selectedMode == RecordingMode.demo) _buildDemoControls(),
            if (_selectedMode == RecordingMode.automatic) _buildAutomaticControls(),
            const SizedBox(height: 24),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isRecording = CallRecordingService.instance.isRecording;
    final isDemoRunning = RecordingModeService.instance.isDemoRunning;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRecording || isDemoRunning
              ? [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)]
              : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isRecording || isDemoRunning ? AppTheme.errorColor : AppTheme.primaryColor).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRecording || isDemoRunning ? Icons.fiber_manual_record : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRecording || isDemoRunning ? 'RECORDING' : 'READY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${_getModeDisplayName(_selectedMode)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 0.6.seconds)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recording Mode',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...RecordingMode.values.map((mode) => _buildModeOption(mode)),
      ],
    );
  }

  Widget _buildModeOption(RecordingMode mode) {
    final isSelected = _selectedMode == mode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            setState(() {
              _selectedMode = mode;
            });
            try {
              await RecordingModeService.instance.setMode(mode);
            } catch (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error switching mode: $error'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getModeIcon(mode),
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getModeDisplayName(mode),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getModeDescription(mode),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualControls() {
    final isRecording = CallRecordingService.instance.isRecording;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manual Recording',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Contact Name (Optional)',
            hintText: 'Enter contact name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Incoming Call'),
          subtitle: Text(_isIncoming ? 'Simulating incoming call' : 'Simulating outgoing call'),
          value: _isIncoming,
          onChanged: (value) {
            setState(() {
              _isIncoming = value;
            });
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRecording ? _stopManualRecording : _startManualRecording,
            icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
            label: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? AppTheme.errorColor : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Debug button to test recording list refresh
        OutlinedButton(
          onPressed: _testRecordingListRefresh,
          child: const Text('Test Recording List Refresh'),
        ),
      ],
    );
  }

  Widget _buildDemoControls() {
    final isDemoRunning = RecordingModeService.instance.isDemoRunning;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo Scenarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<DemoScenario>(
          value: _selectedScenario,
          decoration: InputDecoration(
            labelText: 'Select Scenario',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: DemoScenario.values.map((scenario) {
            return DropdownMenuItem(
              value: scenario,
              child: Text(_getScenarioDisplayName(scenario)),
            );
          }).toList(),
          onChanged: isDemoRunning ? null : (value) {
            if (value != null) {
              setState(() {
                _selectedScenario = value;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isDemoRunning ? _stopDemo : _startDemo,
            icon: Icon(isDemoRunning ? Icons.stop : Icons.play_arrow),
            label: Text(isDemoRunning ? 'Stop Demo' : 'Start Demo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDemoRunning ? AppTheme.errorColor : AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomaticControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Automatic Mode',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.autorenew,
                color: AppTheme.successColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Automatic Recording Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The app is now monitoring phone state in the background. All incoming and outgoing calls will be automatically recorded when connected.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phone state monitoring enabled',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatic recording lifecycle management',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Background call detection active',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recording limitation warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recording Limitation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Currently recording microphone audio only. For full call recording (both sides), SCAI must be installed as a system app.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showSystemAppGuide(),
                child: Text(
                  'View installation guide →',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to Use',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Manual Mode: Record audio manually with custom phone numbers\n'
            '• Demo Mode: Experience realistic scam detection scenarios\n'
            '• Recordings are saved locally and can be analyzed by the backend server\n'
            '• Check the Call History tab to view and analyze your recordings',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Event Handlers
  Future<void> _startManualRecording() async {
    try {
      await RecordingModeService.instance.startManualRecording(
        phoneNumber: _phoneController.text.trim(),
        contactName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        isIncoming: _isIncoming,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _stopManualRecording() async {
    try {
      final recording = await RecordingModeService.instance.stopManualRecording();
      if (mounted && recording != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved: ${recording.fileName}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _testRecordingListRefresh() async {
    try {
      // Manually refresh the recordings list
      await ref.read(callRecordingProvider.notifier).loadRecordings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording list refreshed'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing list: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _startDemo() async {
    try {
      await RecordingModeService.instance.startDemo(_selectedScenario);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting demo: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _stopDemo() async {
    try {
      await RecordingModeService.instance.stopDemo();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping demo: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Helper Methods
  String _getModeDisplayName(RecordingMode mode) {
    switch (mode) {
      case RecordingMode.manual:
        return 'Manual Recording';
      case RecordingMode.demo:
        return 'Demo Mode';
      case RecordingMode.automatic:
        return 'Automatic Detection';
    }
  }

  String _getModeDescription(RecordingMode mode) {
    switch (mode) {
      case RecordingMode.manual:
        return 'Manually start and stop recordings';
      case RecordingMode.demo:
        return 'Experience realistic scam scenarios';
      case RecordingMode.automatic:
        return 'Automatically detect and record calls';
    }
  }

  IconData _getModeIcon(RecordingMode mode) {
    switch (mode) {
      case RecordingMode.manual:
        return Icons.radio_button_checked;
      case RecordingMode.demo:
        return Icons.play_circle_outline;
      case RecordingMode.automatic:
        return Icons.autorenew;
    }
  }

  String _getScenarioDisplayName(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.legitimateCall:
        return 'Legitimate Business Call';
      case DemoScenario.robocall:
        return 'Automated Robocall';
      case DemoScenario.phishingScam:
        return 'Banking Phishing Scam';
      case DemoScenario.techSupportScam:
        return 'Tech Support Scam';
      case DemoScenario.irsScam:
        return 'IRS Impersonation Scam';
    }
  }
}
