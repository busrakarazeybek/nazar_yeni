import 'dart:math' as dart_math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showRetryButton = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  Future<void> _startInitialization() async {
    try {
      setState(() {
        _isInitializing = true;
        _showRetryButton = false;
      });

      // Simulate initialization tasks
      await Future.wait([
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchConfiguration(),
        _prepareCachedData(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Initialization timeout');
        },
      );

      // Minimum splash display time
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showRetryButton = true;
        });
      }
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    // Simulate authentication check
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user role preferences
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _fetchConfiguration() async {
    // Simulate fetching essential configuration
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached profile data
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated &&
        authProvider.currentUserProfile != null) {
      // User is authenticated, go to home screen (role-based)
      Navigator.pushReplacementNamed(context, '/home-screen');
    } else if (_mockIsReturningUser()) {
      Navigator.pushReplacementNamed(context, '/login-screen');
    } else {
      Navigator.pushReplacementNamed(context, '/role-selection-screen');
    }
  }

  bool _mockAuthenticationCheck() {
    // Check actual authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isAuthenticated;
  }

  String? _mockUserRoleCheck() {
    // Get actual user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUserProfile?.role.toString().split('.').last;
  }

  bool _mockIsReturningUser() {
    // Mock returning user check - returns false for demo
    return false;
  }

  void _retryInitialization() {
    _startInitialization();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryLight,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryLight,
                AppTheme.primaryLight.withValues(alpha: 0.8),
                AppTheme.secondaryLight.withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTurkishPatternBackground(),
                      SizedBox(height: 8.h),
                      _buildAppLogo(),
                      SizedBox(height: 4.h),
                      _buildAppTitle(),
                      SizedBox(height: 2.h),
                      _buildSubtitle(),
                    ],
                  ),
                ),
                _buildBottomSection(),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurkishPatternBackground() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.1,
          child: Container(
            width: 80.w,
            height: 25.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: TurkishPatternPainter(),
              size: Size(80.w, 25.h),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLogo() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'favorite',
                      color: AppTheme.primaryLight,
                      size: 12.w,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Text(
            'Görücü Matchmaker',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.8,
          child: Text(
            'Geleneksel Görücü Usulü',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        _isInitializing ? _buildLoadingIndicator() : const SizedBox.shrink(),
        _showRetryButton ? _buildRetryButton() : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              SizedBox(
                width: 6.w,
                height: 6.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Hazırlanıyor...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRetryButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: Colors.white.withValues(alpha: 0.8),
                size: 8.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'Bağlantı hatası oluştu',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _retryInitialization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryLight,
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Tekrar Dene',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TurkishPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw geometric Turkish pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final startX = center.dx + radius * 0.5 * cos(angle);
      final startY = center.dy + radius * 0.5 * sin(angle);
      final endX = center.dx + radius * cos(angle);
      final endY = center.dy + radius * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * i / 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper function for cos calculation
double cos(double radians) {
  return radians.cos();
}

// Helper function for sin calculation
double sin(double radians) {
  return radians.sin();
}

// Extension for trigonometric functions
extension on double {
  double cos() {
    return dart_math.cos(this);
  }

  double sin() {
    return dart_math.sin(this);
  }
}

// Import for math functions

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Görücü Matchmaker',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}
