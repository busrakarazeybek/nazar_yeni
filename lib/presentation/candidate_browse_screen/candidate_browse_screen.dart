import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/candidate_card_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';

class CandidateBrowseScreen extends StatefulWidget {
  const CandidateBrowseScreen({super.key});

  @override
  State<CandidateBrowseScreen> createState() => _CandidateBrowseScreenState();
}

class _CandidateBrowseScreenState extends State<CandidateBrowseScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _swipeIndicatorController;
  late Animation<double> _cardAnimation;
  late Animation<double> _swipeIndicatorAnimation;

  final userService = UserService();
  final matchService = MatchService();

  int _currentIndex = 0;
  bool _isSwipeInProgress = false;
  String _swipeDirection = '';
  int _selectedBottomNavIndex = 0;
  bool _isLoading = true;
  List<UserProfile> _candidates = [];

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );

    _swipeIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _swipeIndicatorController, curve: Curves.easeOut),
    );

    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final candidates = await userService.getCandidates(limit: 20);

      setState(() {
        _candidates = candidates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adaylar yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _swipeIndicatorController.dispose();
    super.dispose();
  }

  void _handleSwipe(String direction) async {
    if (_isSwipeInProgress || _currentIndex >= _candidates.length) return;

    setState(() {
      _isSwipeInProgress = true;
      _swipeDirection = direction;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // If it's a like, create a match
    if (direction == 'like') {
      await _createMatch();
    }

    _swipeIndicatorController.forward().then((_) {
      _cardAnimationController.forward().then((_) {
        setState(() {
          _currentIndex++;
          _isSwipeInProgress = false;
          _swipeDirection = '';
        });

        _cardAnimationController.reset();
        _swipeIndicatorController.reset();

        // Show match animation if it's a like and successful match
        if (direction == 'like' && _currentIndex % 3 == 0) {
          _showMatchDialog();
        }
      });
    });
  }

  Future<void> _createMatch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;

    if (currentUser == null || _currentIndex >= _candidates.length) return;

    try {
      // For now, we'll create a match with a mock target candidate
      // In a real implementation, this would be more sophisticated
      final candidate = _candidates[_currentIndex];

      await matchService.createMatch(
        selectorId: currentUser.id,
        candidateId: candidate.id,
        targetCandidateId:
            candidate.id, // This would be different in real implementation
      );
    } catch (e) {
      debugPrint('Failed to create match: $e');
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'favorite',
                  color: AppTheme.successColor,
                  size: 48.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Eşleşme!',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Tebrikler! Yeni bir eşleşmeniz var.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Devam Et'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/matches-screen');
                        },
                        child: Text('Eşleşmeleri Gör'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, '/matches-screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/my-selectors-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile-screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : (_currentIndex >= _candidates.length
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildCardStack(),
                      ),
                      _buildActionButtons(),
                      SizedBox(height: 2.h),
                    ],
                  )),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(height: 2.h),
          Text(
            'Adaylar yükleniyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Adaylar',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  '${_candidates.length - _currentIndex} kişi',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.w),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'tune',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20.w,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_candidates.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Stack(
        children: [
          // Background cards for depth
          if (_currentIndex + 1 < _candidates.length)
            Positioned(
              top: 1.h,
              left: 2.w,
              right: 2.w,
              bottom: 1.h,
              child: Transform.scale(
                scale: 0.95,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main card
          AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _cardAnimation.value *
                      (_swipeDirection == 'like' ? 100.w : -100.w),
                  0,
                ),
                child: Transform.rotate(
                  angle: _cardAnimation.value *
                      (_swipeDirection == 'like' ? 0.1 : -0.1),
                  child: Opacity(
                    opacity: 1.0 - (_cardAnimation.value * 0.8),
                    child: CandidateCardWidget(
                      candidate: _convertToMap(_candidates[_currentIndex]),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/candidate-profile-detail-screen',
                          arguments: _convertToMap(_candidates[_currentIndex]),
                        );
                      },
                      onSwipe: _handleSwipe,
                    ),
                  ),
                ),
              );
            },
          ),

          // Swipe indicators
          if (_isSwipeInProgress)
            AnimatedBuilder(
              animation: _swipeIndicatorAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 25.h,
                  left: _swipeDirection == 'like' ? 60.w : 10.w,
                  child: Opacity(
                    opacity: _swipeIndicatorAnimation.value,
                    child: Transform.scale(
                      scale: _swipeIndicatorAnimation.value,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _swipeDirection == 'like'
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: _swipeDirection == 'like'
                                  ? 'favorite'
                                  : 'close',
                              color: Colors.white,
                              size: 20.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _swipeDirection == 'like' ? 'BEĞENDİ' : 'GEÇTİ',
                              style: AppTheme.lightTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _convertToMap(UserProfile candidate) {
    return {
      "id": candidate.id,
      "name": candidate.fullName,
      "age": candidate.age ?? 25,
      "bio": candidate.bio ?? "Henüz biyografi eklenmemiş.",
      "profileImage": candidate.imageUrl ??
          "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg",
      "interests": candidate.interests ?? [],
      "location": candidate.location ?? "Bilinmiyor",
      "profession": candidate.profession ?? "Belirtilmemiş"
    };
  }

  Widget _buildActionButtons() {
    return ActionButtonsWidget(
      onPass: () => _handleSwipe('pass'),
      onLike: () => _handleSwipe('like'),
      isEnabled: !_isSwipeInProgress,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.outline,
              size: 64.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Daha Fazla Aday Yok',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Şu anda gösterilecek yeni aday bulunmuyor. Filtrelerinizi değiştirmeyi deneyin.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
                _loadCandidates();
              },
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20.w,
              ),
              label: Text('Yenile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _selectedBottomNavIndex == 0
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'favorite',
            color: _selectedBottomNavIndex == 1
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Eşleşmeler',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: _selectedBottomNavIndex == 2
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Adaylarım',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _selectedBottomNavIndex == 3
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}
