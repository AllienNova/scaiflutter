import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/permission_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _progressController.forward();
    
    await _checkAppState();
  }
  
  Future<void> _checkAppState() async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (appState.isFirstLaunch) {
      if (mounted) context.go('/onboarding');
    } else {
      final hasPermissions = await PermissionService.instance.checkAllPermissions();
      
      if (!hasPermissions) {
        if (mounted) context.go('/permission-setup');
      } else {
        appStateNotifier.setPermissionsGranted(true);
        if (mounted) context.go('/home');
      }
    }
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildAppName(),
                      const SizedBox(height: 16),
                      _buildTagline(),
                    ],
                  ),
                ),
              ),
              _buildProgress(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoController.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.security,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      },
    ).animate()
      .fadeIn(duration: 1.seconds)
      .scale(curve: Curves.elasticOut);
  }
  
  Widget _buildAppName() {
    return Text(
      'SCAI Guard',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ).animate(delay: 0.5.seconds)
      .fadeIn(duration: 0.8.seconds)
      .slideY(begin: 0.3, end: 0);
  }
  
  Widget _buildTagline() {
    return Text(
      'AI-Powered Call Protection',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w500,
      ),
    ).animate(delay: 0.8.seconds)
      .fadeIn(duration: 0.8.seconds)
      .slideY(begin: 0.3, end: 0);
  }
  
  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Initializing...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ).animate(delay: 1.2.seconds)
          .fadeIn(duration: 0.6.seconds),
        const SizedBox(height: 16),
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 200 * _progressController.value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ).animate(delay: 1.5.seconds)
          .fadeIn(duration: 0.6.seconds),
      ],
    );
  }
}