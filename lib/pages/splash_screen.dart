// File: lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' show lerpDouble;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Wait for 3 seconds then navigate
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedLoadingLogo(
          logoWidget: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(235, 255, 255, 255), // Your app color
              shape: BoxShape.circle,
            ),
            child: Center(
              // Replace with your logo
              child: Image.asset(
                'assets/loadingLogo.png', 
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              
            ),
          ),
          size: 200,
        ),
      ),
    );
  }
}

class AnimatedLoadingLogo extends StatefulWidget {
  final Widget logoWidget;
  final double size;

  const AnimatedLoadingLogo({
    super.key,
    required this.logoWidget,
    this.size = 200,
  });

  @override
  State<AnimatedLoadingLogo> createState() => _AnimatedLoadingLogoState();
}

class _AnimatedLoadingLogoState extends State<AnimatedLoadingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 0.96), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 0.92), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: PulseRingPainter(
                  progress: _controller.value,
                  baseColor: const Color.fromARGB(255, 203, 50, 155),
                  intensity: _glowAnimation.value,
                ),
              );
            },
          ),
          ScaleTransition(scale: _scaleAnimation, child: widget.logoWidget),
        ],
      ),
    );
  }
}

class PulseRingPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final double intensity;

  PulseRingPainter({
    required this.progress,
    required this.baseColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var ring = 0; ring < 2; ring++) {
      final phase = (progress + ring * 0.5) % 1.0;
      final radius = lerpDouble(maxRadius * 0.7, maxRadius * 1.2, phase)!;
      final alpha = lerpDouble(
        0.0,
        0.5,
        (1.0 - phase) * intensity,
      )!.clamp(0.0, 0.45);

      final paint = Paint()
        ..color = baseColor.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(2, 6, 1.0 - phase)!;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(PulseRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}
