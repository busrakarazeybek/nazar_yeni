import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../enhanced_selector_home_screen/enhanced_selector_home_screen.dart';

class SelectorHomeWidget extends StatefulWidget {
  final UserProfile userProfile;

  const SelectorHomeWidget({
    super.key,
    required this.userProfile,
  });

  @override
  State<SelectorHomeWidget> createState() => _SelectorHomeWidgetState();
}

class _SelectorHomeWidgetState extends State<SelectorHomeWidget> {
  @override
  void initState() {
    super.initState();
    // Immediately redirect to enhanced selector home screen after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToEnhancedHome();
    });
  }

  void _navigateToEnhancedHome() {
    // Replace current widget with enhanced selector home screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EnhancedSelectorHomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while transitioning to enhanced screen
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or loading indicator
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'favorite',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 48.w,
                ),
              ),
              SizedBox(height: 3.h),

              // Loading indicator
              CircularProgressIndicator(
                color: AppTheme.lightTheme.primaryColor,
                strokeWidth: 3,
              ),
              SizedBox(height: 2.h),

              // Welcome message
              Text(
                'Hoş geldiniz ${widget.userProfile.fullName.split(' ').first}',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),

              Text(
                'Gelişmiş eşleştirme sistemi yükleniyor...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 0.5.h),

              Text(
                'Adaylarınızı seçin ve eşleştirme yapın',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
