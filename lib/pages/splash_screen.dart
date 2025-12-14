// File: lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

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
              color: const Color(0xFF0A66C2), // Your app color
              shape: BoxShape.circle,
            ),
            child: Center(
              // Replace with your logo
              child: Image.asset(
                'assets/logo.png', // Your logo path
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              // Or use text like LinkedIn:
              // child: const Text(
              //   'CT',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 60,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
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
                painter: CircularProgressPainter(
                  progress: _controller.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  progressColor: const Color(0xFF0A66C2),
                ),
              );
            },
          ),
          widget.logoWidget,
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -90 * 3.14159 / 180;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
