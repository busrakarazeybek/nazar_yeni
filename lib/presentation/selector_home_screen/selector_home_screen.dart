import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/match_proposal_service.dart';
import '../dual_candidate_selection_screen/dual_candidate_selection_screen.dart';
import './widgets/candidate_selection_carousel_widget.dart';
import './widgets/potential_matches_section_widget.dart';
import './widgets/stats_section_widget.dart';

class SelectorHomeScreen extends StatefulWidget {
  const SelectorHomeScreen({super.key});

  @override
  State<SelectorHomeScreen> createState() => _SelectorHomeScreenState();
}

class _SelectorHomeScreenState extends State<SelectorHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  final UserService _userService = UserService();
  final MatchService _matchService = MatchService();
  final MatchProposalService _matchProposalService = MatchProposalService();

  UserProfile? _selectedCandidate;
  List<UserProfile> _assignedCandidates = [];
  List<UserProfile> _potentialMatches = [];
  bool _isLoading = true;
  String? _error;
  int _totalMatches = 0;
  int _todayMatches = 0;
  int _pendingMatches = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _fadeAnimationController, curve: Curves.easeOut));

    _fadeAnimationController.forward();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final results = await Future.wait([
        _userService.getSelectorCandidates(currentUser.id),
        _userService.getCandidates(limit: 20),
        _matchService.getUserMatches(currentUser.id),
        _matchService.getTodayMatches(currentUser.id),
        _matchService.getPendingMatches(currentUser.id),
      ]);

      setState(() {
        _assignedCandidates = results[0] as List<UserProfile>;
        _potentialMatches = results[1] as List<UserProfile>;
        _totalMatches = (results[2] as List).length;
        _todayMatches = (results[3] as List).length;
        _pendingMatches = (results[4] as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadData();
  }

  void _onCandidateSelected(UserProfile candidate) {
    setState(() {
      _selectedCandidate = candidate;
    });
    HapticFeedback.selectionClick();
  }

  void _onCreateMatch() {
    if (_selectedCandidate != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DualCandidateSelectionScreen()));
    }
  }

  Future<void> _onMatchRequest(
      UserProfile selectedFromSecilecekler, UserProfile targetCandidate) async {
    try {
      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) {
        _showErrorMessage('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Show loading indicator
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
              child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.primaryColor)));

      await _matchProposalService.createMatchProposal(
          selectorId: currentUser.id,
          candidateId: selectedFromSecilecekler.id,
          targetCandidateId: targetCandidate.id,
          message:
              '${selectedFromSecilecekler.fullName} için ${targetCandidate.fullName} ile eşleşme isteği');

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      _showSuccessMessage(
          '${selectedFromSecilecekler.fullName} için ${targetCandidate.fullName} ile eşleşme isteği gönderildi!');

      // Refresh data
      _refreshData();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showErrorMessage('Eşleşme isteği gönderilemedi: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            })));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            })));
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppTheme.lightTheme.primaryColor,
                        child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildHeader(),
                                            SizedBox(height: 2.h),
                                            StatsSection(
                                                totalMatches: _totalMatches,
                                                todayMatches: _todayMatches,
                                                pendingMatches:
                                                    _pendingMatches),
                                            SizedBox(height: 3.h),
                                            _buildCandidateSelectionSection(),
                                            SizedBox(height: 3.h),
                                            PotentialMatchesSection(
                                                potentialMatches:
                                                    _potentialMatches,
                                                selectedCandidate:
                                                    _selectedCandidate,
                                                onRefresh: _refreshData,
                                                onMatchRequest:
                                                    _onMatchRequest),
                                            SizedBox(height: 2.h),
                                            _buildCreateMatchButton(),
                                            SizedBox(height: 4.h),
                                          ]));
                                })))),
        bottomNavigationBar: _buildBottomNavigationBar());
  }

  Widget _buildLoadingState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppTheme.lightTheme.primaryColor),
      SizedBox(height: 2.h),
      Text('Veriler yükleniyor...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
    ]));
  }

  Widget _buildErrorState() {
    return Center(
        child: Padding(
            padding: EdgeInsets.all(6.w),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CustomIconWidget(
                  iconName: 'error_outline',
                  color: AppTheme.errorColor,
                  size: 64.w),
              SizedBox(height: 3.h),
              Text('Bir Hata Oluştu',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              Text(_error ?? 'Bilinmeyen bir hata oluştu',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: CustomIconWidget(
                      iconName: 'refresh', color: Colors.white, size: 18.w),
                  label: Text('Tekrar Dene')),
            ])));
  }

  Widget _buildHeader() {
    final currentUser = AuthProvider().currentUser;
    // Get user profile for display name instead of using User.name which doesn't exist
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Merhaba ${currentUser?.email?.split('@').first ?? 'Görücü'} 👋',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface)),
          SizedBox(height: 0.5.h),
          Text('Hangi adaylarınızı eşleştirmek istiyorsunuz?',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
        ]));
  }

  Widget _buildCandidateSelectionSection() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CustomIconWidget(
                iconName: 'people',
                color: AppTheme.lightTheme.primaryColor,
                size: 20.w),
            SizedBox(width: 2.w),
            Text('Seçilecekler:',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface)),
          ]),
          SizedBox(height: 2.h),
          CandidateSelectionCarousel(
              candidates: _assignedCandidates,
              selectedCandidate: _selectedCandidate,
              onCandidateSelected: _onCandidateSelected),
        ]));
  }

  Widget _buildCreateMatchButton() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: _selectedCandidate != null ? _onCreateMatch : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCandidate != null
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.outline,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w)),
                    elevation: _selectedCandidate != null ? 4 : 0),
                icon: CustomIconWidget(
                    iconName: 'favorite', color: Colors.white, size: 20.w),
                label: Text(
                    _selectedCandidate != null
                        ? '${_selectedCandidate!.fullName} için Eşleştirme Yap'
                        : 'Önce bir kişi seçin',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)))));
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on selector home
              break;
            case 1:
              Navigator.pushNamed(context, '/my-selections-screen');
              break;
            case 2:
              Navigator.pushNamed(context, '/my-selectors-screen');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile-screen');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        items: [
          BottomNavigationBarItem(
              icon: CustomIconWidget(
                  iconName: 'home',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24.w),
              label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: CustomIconWidget(
                  iconName: 'list',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24.w),
              label: 'Önerilerim'),
          BottomNavigationBarItem(
              icon: CustomIconWidget(
                  iconName: 'people',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24.w),
              label: 'Adaylarım'),
          BottomNavigationBarItem(
              icon: CustomIconWidget(
                  iconName: 'person',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24.w),
              label: 'Profil'),
        ]);
  }
}
