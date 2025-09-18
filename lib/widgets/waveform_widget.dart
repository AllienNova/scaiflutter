import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';

class WaveformWidget extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final double height;
  
  const WaveformWidget({
    super.key,
    required this.isActive,
    this.color,
    this.height = 60,
  });
  
  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  
  final int _barCount = 40;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _barControllers = List.generate(_barCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 200 + _random.nextInt(300)),
        vsync: this,
      );
    });
    
    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 0.3 + _random.nextDouble() * 0.7,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
    
    if (widget.isActive) {
      _startAnimation();
    }
  }
  
  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }
  
  void _startAnimation() {
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isActive) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }
  
  void _stopAnimation() {
    for (final controller in _barControllers) {
      controller.reset();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: widget.isActive ? _buildActiveWaveform() : _buildInactiveWaveform(),
    );
  }
  
  Widget _buildActiveWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_barCount, (index) {
        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            final barHeight = widget.height * _barAnimations[index].value;
            return Container(
              width: 2,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        );
      }),
    );
  }
  
  Widget _buildInactiveWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_barCount, (index) {
        return Container(
          width: 2,
          height: widget.height * 0.1,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppTheme.textTertiary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    ).animate()
      .fadeIn(duration: 0.5.seconds)
      .slideY(begin: 0.2, end: 0);
  }
}