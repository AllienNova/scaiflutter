import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'AI-Powered Protection',
      description: 'Advanced artificial intelligence analyzes every call in real-time to detect potential scams and deepfake voices.',
      icon: Icons.psychology,
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'Real-Time Detection',
      description: 'Get instant alerts during calls when suspicious activity is detected, keeping you safe from fraud attempts.',
      icon: Icons.warning_amber_rounded,
      color: AppTheme.warningColor,
    ),
    OnboardingPage(
      title: 'Complete Privacy',
      description: 'Your calls are processed securely with enterprise-grade encryption. Your privacy is our top priority.',
      icon: Icons.privacy_tip,
      color: AppTheme.successColor,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 0.6.seconds)
            .slideX(begin: -0.2, end: 0),
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate()
            .fadeIn(duration: 0.6.seconds)
            .slideX(begin: 0.2, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ).animate(delay: Duration(milliseconds: 200 + index * 100))
            .scale(curve: Curves.elasticOut, duration: 0.8.seconds),
          
          const SizedBox(height: 48),
          
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: Duration(milliseconds: 400 + index * 100))
            .fadeIn(duration: 0.6.seconds)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 24),
          
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: Duration(milliseconds: 600 + index * 100))
            .fadeIn(duration: 0.6.seconds)
            .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPageIndicator(),
          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? AppTheme.primaryColor 
                : AppTheme.textTertiary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: _previousPage,
            child: const Text('Back'),
          ).animate()
            .fadeIn(duration: 0.3.seconds)
            .slideX(begin: -0.2, end: 0),
        const Spacer(),
        ElevatedButton(
          onPressed: _currentPage == _pages.length - 1 
              ? _finishOnboarding 
              : _nextPage,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
          ),
        ).animate()
          .fadeIn(duration: 0.3.seconds)
          .slideX(begin: 0.2, end: 0),
      ],
    );
  }
  
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _skipOnboarding() {
    _finishOnboarding();
  }
  
  void _finishOnboarding() {
    ref.read(appStateProvider.notifier).setFirstLaunchComplete();
    context.go('/permission-setup');
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}