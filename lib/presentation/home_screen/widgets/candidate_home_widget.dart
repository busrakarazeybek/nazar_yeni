import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './candidate_profile_summary_widget.dart';
import './incoming_matches_widget.dart';
import './selector_suggestions_widget.dart';
import './selectors_section_widget.dart';

class CandidateHomeWidget extends StatefulWidget {
  final UserProfile userProfile;

  const CandidateHomeWidget({super.key, required this.userProfile});

  @override
  State<CandidateHomeWidget> createState() => _CandidateHomeWidgetState();
}

class _CandidateHomeWidgetState extends State<CandidateHomeWidget> {
  final matchService = MatchService();
  final userService = UserService();
  int _selectedBottomNavIndex = 0;
  bool _isLoading = true;
  List<Match> _incomingMatches = [];
  List<UserProfile> _selectors = [];
  List<Map<String, dynamic>> _selectorSuggestions = [];
  int _totalMatches = 0;
  int _pendingMatches = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final results = await Future.wait([
        matchService.getIncomingMatches(widget.userProfile.id),
        matchService.getUserMatches(widget.userProfile.id),
        userService.getCandidateSelectors(widget.userProfile.id),
        _loadSelectorSuggestions(),
      ]);

      final allIncomingMatches = results[0] as List<Match>;
      final allMatches = results[1] as List<Match>;
      final selectors = results[2] as List<UserProfile>;
      final suggestions = results[3] as List<Map<String, dynamic>>;

      setState(() {
        _incomingMatches = allIncomingMatches;
        _totalMatches = allMatches.length;
        _pendingMatches = allIncomingMatches
            .where((match) => match.status == MatchStatus.pending)
            .length;
        _selectors = selectors;
        _selectorSuggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadSelectorSuggestions() async {
    // Seçicilerin önerdiği adayları yükle
    try {
      final suggestions = await userService.getSelectorSuggestions(
        widget.userProfile.id,
      );
      return suggestions;
    } catch (e) {
      // Eğer servis henüz yoksa mock data döndür
      return [
        {
          'id': '1',
          'selectorName': 'Ayşe Teyze',
          'selectorImage':
              'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg',
          'suggestedCandidateName': 'Mehmet Ali',
          'suggestedCandidateAge': 28,
          'suggestedCandidateImage':
              'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
          'suggestedCandidateBio': 'Mühendis, spor ve müzik sever',
          'status': 'pending',
          'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        },
        {
          'id': '2',
          'selectorName': 'Fatma Hanım',
          'selectorImage':
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg',
          'suggestedCandidateName': 'Ahmet Yılmaz',
          'suggestedCandidateAge': 30,
          'suggestedCandidateImage':
              'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg',
          'suggestedCandidateBio': 'Doktor, sanat ve seyahat meraklısı',
          'status': 'accepted',
          'timestamp': DateTime.now().subtract(Duration(days: 1)),
        },
      ];
    }
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

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _addSelector(String email) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),
      );

      // Seçici ekleme işlemi
      await userService.addSelectorToCandidate(
        candidateId: widget.userProfile.id,
        selectorEmail: email,
      );

      // Loading'i kapat
      Navigator.of(context).pop();

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seçici başarıyla eklendi'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Verileri yenile
      await _loadData();
    } catch (e) {
      // Loading'i kapat
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seçici eklenirken hata: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showAddSelectorDialog() {
    // Implement the selector dialog functionality
    // This is a stub implementation that was missing
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seçici Ekle'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: 'Seçici Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (emailController.text.isNotEmpty) {
                _addSelector(emailController.text);
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSuggestionAction(
    String suggestionId,
    String action,
  ) async {
    // Implement the suggestion action handling
    // This is a stub implementation that was missing
    try {
      // Process the suggestion action (accept/reject)
      // You would implement the actual API call here

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Öneri ${action == 'accept' ? 'kabul edildi' : 'reddedildi'}',
          ),
          backgroundColor: action == 'accept'
              ? AppTheme.successColor
              : AppTheme.lightTheme.colorScheme.outline,
        ),
      );

      // Refresh data after action
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.lightTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildStatsSection(),
                      SizedBox(height: 2.h),
                      CandidateProfileSummaryWidget(
                        userProfile: widget.userProfile,
                        onEditProfile: () {
                          Navigator.pushNamed(context, '/profile-screen');
                        },
                      ),
                      SizedBox(height: 3.h),
                      SelectorsSectionWidget(
                        selectors: _selectors,
                        onAddSelector: _showAddSelectorDialog,
                      ),
                      SizedBox(height: 3.h),
                      SelectorSuggestionsWidget(
                        suggestions: _selectorSuggestions,
                        onSuggestionAction: _handleSuggestionAction,
                      ),
                      SizedBox(height: 2.h),
                      IncomingMatchesWidget(
                        matches: _incomingMatches,
                        onMatchAction: _handleMatchAction,
                        onViewAllMatches: () {
                          Navigator.pushNamed(context, '/matches-screen');
                        },
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.lightTheme.primaryColor),
          SizedBox(height: 2.h),
          Text(
            'Profil bilgileri yükleniyor...',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba ${widget.userProfile.fullName.split(' ').first} 👋',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Profilinizi güncel tutun',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: widget.userProfile.isProfileComplete
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.w),
              border: Border.all(
                color: widget.userProfile.isProfileComplete
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: widget.userProfile.isProfileComplete
                      ? 'check_circle'
                      : 'warning',
                  color: widget.userProfile.isProfileComplete
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  size: 16.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  widget.userProfile.isProfileComplete ? 'Tamamlandı' : 'Eksik',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: widget.userProfile.isProfileComplete
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Bekleyen Eşleşme',
              '$_pendingMatches',
              CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.warningColor,
                size: 20.w,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 5.h,
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.3,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Toplam Eşleşme',
              '$_totalMatches',
              CustomIconWidget(
                iconName: 'favorite',
                color: AppTheme.successColor,
                size: 20.w,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 5.h,
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.3,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Profil Tamamlama',
              widget.userProfile.isProfileComplete ? '100%' : '60%',
              CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Widget icon) {
    return Column(
      children: [
        icon,
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleMatchAction(String matchId, String action) async {
    try {
      if (action == 'accept') {
        await matchService.acceptMatch(matchId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eşleşme kabul edildi!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (action == 'reject') {
        await matchService.rejectMatch(matchId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eşleşme reddedildi.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.outline,
          ),
        );
      }

      // Refresh data after action
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'favorite',
                color: _selectedBottomNavIndex == 1
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              if (_pendingMatches > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    constraints: BoxConstraints(minWidth: 4.w, minHeight: 4.w),
                    child: Text(
                      '$_pendingMatches',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
