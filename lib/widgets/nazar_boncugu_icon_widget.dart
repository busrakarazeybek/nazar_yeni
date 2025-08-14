import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NazarBoncuguIconWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final VoidCallback? onTap;
  final bool animated;

  const NazarBoncuguIconWidget({
    super.key,
    this.size,
    this.color,
    this.onTap,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 6.w;
    
    Widget nazarIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            const Color(0xFF2563EB), // Bright blue center
            const Color(0xFF1E40AF), // Darker blue middle
            const Color(0xFF1E3A8A), // Dark blue outer
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer white circle
          Container(
            width: iconSize * 0.8,
            height: iconSize * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF1E3A8A),
                width: iconSize * 0.03,
              ),
            ),
          ),
          // Inner blue circle (pupil)
          Container(
            width: iconSize * 0.4,
            height: iconSize * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E3A8A),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // Small white highlight
          Positioned(
            top: iconSize * 0.25,
            left: iconSize * 0.35,
            child: Container(
              width: iconSize * 0.15,
              height: iconSize * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );

    if (animated) {
      nazarIcon = TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 2),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: nazarIcon,
          );
        },
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: nazarIcon,
      );
    }

    return nazarIcon;
  }
}