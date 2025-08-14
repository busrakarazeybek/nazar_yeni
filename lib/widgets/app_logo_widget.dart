import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppLogoWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AppLogoWidget({
    super.key,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 6.w;
    
    Widget logo = Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/nazar_logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to custom icon if image fails to load
            return Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    const Color(0xFF2563EB),
                    const Color(0xFF1E40AF),
                    const Color(0xFF1E3A8A),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Icon(
                Icons.visibility,
                size: logoSize * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logo,
      );
    }

    return logo;
  }
}