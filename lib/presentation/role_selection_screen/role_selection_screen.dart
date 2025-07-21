import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/cultural_info_bottom_sheet.dart';
import './widgets/role_card_widget.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);

    _slideController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    // Navigate to appropriate registration screen based on role
    if (role == 'Selector') {
      Navigator.pushNamed(context, '/selector-registration-screen',
          arguments: {'role': role});
    } else {
      Navigator.pushNamed(context, '/registration-screen',
          arguments: {'role': role});
    }
  }

  void _showCulturalInfo() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CulturalInfoBottomSheet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Column(children: [
                  // Header section
                  Expanded(
                      flex: 3,
                      child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App logo
                                Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        borderRadius:
                                            BorderRadius.circular(4.w)),
                                    child: CustomIconWidget(
                                        iconName: 'favorite',
                                        color: Colors.white,
                                        size: 48.w)),

                                SizedBox(height: 3.h),

                                // Welcome text
                                Text('Görücü Uygulamasına\nHoş Geldiniz',
                                    style: AppTheme
                                        .lightTheme.textTheme.headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurface),
                                    textAlign: TextAlign.center),

                                SizedBox(height: 2.h),

                                Text('Hangi rol ile devam etmek istiyorsunuz?',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyLarge
                                        ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.center),

                                SizedBox(height: 1.h),

                                // Cultural info button
                                TextButton.icon(
                                    onPressed: _showCulturalInfo,
                                    icon: CustomIconWidget(
                                        iconName: 'info',
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        size: 16.w),
                                    label: Text('Görücü kültürü hakkında',
                                        style: TextStyle(
                                            color: AppTheme
                                                .lightTheme.colorScheme.primary,
                                            fontWeight: FontWeight.w500))),
                              ]))),

                  // Role selection cards
                  Expanded(
                      flex: 4,
                      child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(children: [
                            // Candidate role card
                            Expanded(
                                child: RoleCardWidget(
                                    title: 'Aday',
                                    subtitle:
                                        'Evlilik için uygun eş arıyorum ayol',
                                    description:
                                        'Profilinizi oluşturun, seçiciler sizinle iletişime geçsin',
                                    iconName: 'person',
                                    gradientColors: [
                                      Colors.blue,
                                      Colors.lightBlue
                                    ],
                                    onTap: () => _onRoleSelected('Candidate'))),

                            SizedBox(height: 3.h),

                            // Selector role card
                            Expanded(
                                child: RoleCardWidget(
                                    title: 'Seçici',
                                    subtitle: 'Aile büyüğü veya görücüyüm',
                                    description:
                                        'Adayları keşfedin, uygun eşleşmeleri gerçekleştirin',
                                    iconName: 'people',
                                    gradientColors: [
                                      Colors.purple,
                                      Colors.deepPurple
                                    ],
                                    onTap: () => _onRoleSelected('Selector'))),
                          ]))),

                  SizedBox(height: 2.h),

                  // Login link
                  FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Zaten hesabınız var mı?',
                                style:
                                    AppTheme.lightTheme.textTheme.bodyMedium),
                            TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login-screen');
                                },
                                child: Text('Giriş Yapın',
                                    style: TextStyle(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        fontWeight: FontWeight.w600))),
                          ])),
                ]))));
  }
}
