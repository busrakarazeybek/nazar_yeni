import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
import './widgets/enhanced_candidate_selection_carousel_widget.dart';
import './widgets/enhanced_potential_matches_section_widget.dart';

class EnhancedSelectorHomeScreen extends StatefulWidget {
  const EnhancedSelectorHomeScreen({super.key});

  @override
  State<EnhancedSelectorHomeScreen> createState() =>
      _EnhancedSelectorHomeScreenState();
}

class _EnhancedSelectorHomeScreenState extends State<EnhancedSelectorHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

  final UserService _userService = UserService();
  final MatchService _matchService = MatchService();
  final MatchProposalService _matchProposalService = MatchProposalService();

  UserProfile? _selectedCandidate;
  List<UserProfile> _assignedCandidates = [];
  List<UserProfile> _potentialMatches = [];
  List<UserProfile> _filteredMatches = [];
  bool _isLoading = true;
  String? _error;
  int _totalMatches = 0;
  int _todayMatches = 0;
  int _pendingMatches = 0;
  int _proposalCounter = 0;
  List<MatchProposal> _selectorProposals = [];
  bool _isLoadingMatches = false;
  final List<String> _removedCandidateIds = [];
  final Set<String> _swipedCandidateIds = {}; // class seviyesinde
  // Her aday için gösterilen kart id'lerini tutan map
  final Map<String, Set<String>> _shownCardIdsPerCandidate = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her açıldığında verileri yenile
    _refreshData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _selectionAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.elasticOut,
      ),
    );

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
        _userService.getCandidates(limit: 50),
        _matchService.getUserMatches(currentUser.id),
        _matchService.getTodayMatches(currentUser.id),
        _matchService.getPendingMatches(currentUser.id),
        _matchProposalService.getSelectorProposals(currentUser.id),
      ]);

      setState(() {
        _assignedCandidates = results[0] as List<UserProfile>;
        _potentialMatches = results[1] as List<UserProfile>;
        _selectorProposals = results[5] as List<MatchProposal>;

        // Kaldırılan adayları filtrele
        _assignedCandidates = _assignedCandidates
            .where((candidate) => !_removedCandidateIds.contains(candidate.id))
            .toList();

        if (_assignedCandidates.isEmpty) {
          _assignedCandidates = [
            UserProfile(
              id: 'b3e1c2d4-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
              email: 'aday1@example.com',
              fullName: 'Aday Bir',
              role: UserRole.candidate,
              age: 25,
              gender: GenderType.female,
              bio: 'Kitap okumayı ve yürüyüş yapmayı severim.',
              interests: ['Kitap', 'Spor', 'Yürüyüş'],
              location: 'İstanbul',
              profession: 'Mühendis',
              imageUrl: null,
              phone: null,
              isActive: true,
              isVerified: false,
              createdAt: DateTime.now(),
            ),
          ];
        }
        if (_potentialMatches.isEmpty) {
          _potentialMatches = [
            UserProfile(
              id: 'c7f8e9a1-2b3c-4d5e-8f9a-0b1c2d3e4f5a',
              email: 'aday2@example.com',
              fullName: 'Aday İki',
              role: UserRole.candidate,
              age: 27,
              gender: GenderType.male,
              bio: 'Sosyal ve aktif biriyim.',
              interests: ['Müzik', 'Yüzme', 'Spor'],
              location: 'Ankara',
              profession: 'Doktor',
              imageUrl: null,
              phone: null,
              isActive: true,
              isVerified: false,
              createdAt: DateTime.now(),
            ),
            UserProfile(
              id: 'd1e2f3a4-b5c6-7d8e-9f0a-1b2c3d4e5f6a',
              email: 'aday3@example.com',
              fullName: 'Aday Üç',
              role: UserRole.candidate,
              age: 24,
              gender: GenderType.female,
              bio: 'Sanata ve doğaya düşkünüm.',
              interests: ['Sanat', 'Doğa', 'Kitap'],
              location: 'İstanbul',
              profession: 'Grafiker',
              imageUrl: null,
              phone: null,
              isActive: true,
              isVerified: false,
              createdAt: DateTime.now(),
            ),
          ];
        }
        _filteredMatches = _potentialMatches;
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

  Future<void> _loadPotentialMatches() async {
    if (_selectedCandidate == null) {
      setState(() {
        _potentialMatches = [];
        _isLoadingMatches = false;
      });
      return;
    }

    setState(() {
      _isLoadingMatches = true;
    });

    try {
      final userService = UserService();
      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) return;

      // Use preference-based filtering when a candidate is selected
      final matches = await userService.getFilteredCandidatesByPreferences(
        currentUser.id,
        candidateId: _selectedCandidate!.id,
      );

      if (mounted) {
        setState(() {
          _potentialMatches = matches;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      print('Error loading potential matches: $e');
      if (mounted) {
        setState(() {
          _potentialMatches = [];
          _isLoadingMatches = false;
        });
      }
    }
  }

  void _onCandidateSelected(UserProfile candidate) {
    setState(() {
      _selectedCandidate = candidate;
    });

    _selectionAnimationController.reset();
    _selectionAnimationController.forward();
    HapticFeedback.selectionClick();

    // Filter potential matches based on selected candidate preferences
    _filterMatchesForCandidate(candidate);
  }

  void _filterMatchesForCandidate(UserProfile candidate) {
    final excludedIds = <String>{..._swipedCandidateIds};
    for (final p in _selectorProposals) {
      if (p.candidateId == candidate.id &&
          p.status != AcceptanceStatus.pending) {
        excludedIds.add(p.targetCandidateId);
      }
      if (p.targetCandidateId == candidate.id &&
          p.targetStatus != AcceptanceStatus.pending) {
        excludedIds.add(p.candidateId);
      }
    }
    final shownIds = _shownCardIdsPerCandidate[candidate.id] ?? <String>{};
    setState(() {
      _filteredMatches = _potentialMatches.where((match) {
        if (match.id == candidate.id) return false;
        if (excludedIds.contains(match.id)) return false;
        if (shownIds.contains(match.id)) return false;
        // Yaş aralığı filtresi
        if (candidate.preferredAgeMin != null &&
            match.age != null &&
            match.age! < candidate.preferredAgeMin!) {
          return false;
        }
        if (candidate.preferredAgeMax != null &&
            match.age != null &&
            match.age! > candidate.preferredAgeMax!) {
          return false;
        }
        // Şehir filtresi
        if (candidate.preferredCities != null &&
            candidate.preferredCities!.isNotEmpty &&
            (match.location == null ||
                !candidate.preferredCities!.contains(match.location))) {
          return false;
        }
        // İlgi alanı filtresi
        if (candidate.preferredInterests != null &&
            candidate.preferredInterests!.isNotEmpty) {
          final intersect =
              match.interests?.toSet().intersection(
                candidate.preferredInterests!.toSet(),
              ) ??
              {};
          if (intersect.isEmpty) return false;
        }
        // Cinsiyet filtresi
        if (candidate.preferredGenders != null &&
            candidate.preferredGenders!.isNotEmpty) {
          final matchGender = match.gender?.toString().toLowerCase() ?? '';
          final allowedGenders = candidate.preferredGenders!
              .map((g) => g.toLowerCase())
              .toList();
          if (!allowedGenders.any((g) => matchGender.contains(g))) return false;
        }
        return true;
      }).toList();
    });
  }

  int _calculateCompatibilityScore(UserProfile candidate, UserProfile match) {
    int score = 0;

    // Age compatibility (closer age = higher score)
    if (candidate.age != null && match.age != null) {
      final ageDiff = (candidate.age! - match.age!).abs();
      score += (10 - ageDiff).clamp(0, 10);
    }

    // Location compatibility
    if (candidate.location == match.location) {
      score += 20;
    }

    // Interest compatibility
    if (candidate.interests != null && match.interests != null) {
      final commonInterests = candidate.interests!
          .where((interest) => match.interests!.contains(interest))
          .length;
      score += commonInterests * 5;
    }

    return score;
  }

  Future<void> _onMatchProposal(UserProfile targetCandidate) async {
    if (_selectedCandidate == null) return;

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
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.lightTheme.primaryColor,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Eşleştirme önerisi gönderiliyor...',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );

      await _matchProposalService.createProposal(
        selectorId: currentUser.id,
        candidateId: _selectedCandidate!.id,
        targetCandidateId: targetCandidate.id,
        message:
            '${_selectedCandidate!.fullName} için ${targetCandidate.fullName} ile eşleşme önerisi',
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Increment proposal counter
      setState(() {
        _proposalCounter++;
      });

      // Show success message with enhanced animation
      _showSuccessMessage(
        '${_selectedCandidate!.fullName} için ${targetCandidate.fullName} ile eşleşme önerisi gönderildi!',
      );

      // Refresh data
      await _refreshData();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showErrorMessage('Eşleşme önerisi gönderilemedi: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 20.w,
            ),
            SizedBox(width: 2.w),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    print('HATA: $message'); // Hata mesajını terminale/loga yazdır
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // 1. İstekleri çekmek için fonksiyon
  Future<List<Map<String, dynamic>>> _getIncomingRequests(String userId) async {
    final client = await SupabaseService().client;
    final response = await client
        .from('selector_candidate_requests')
        .select()
        .eq('to_user_id', userId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Kabul/ret fonksiyonları
  Future<void> _handleAcceptRequest(Map<String, dynamic> req) async {
    final client = await SupabaseService().client;
    await client
        .from('selector_candidate_requests')
        .update({'status': 'accepted'})
        .eq('id', req['id']);

    // Gerçek ilişkiyi oluştur
    if (req['type'] == 'selector') {
      // Aday, seçiciyi kendi listesine ekler (selector_id: to_user_id, candidate_id: from_user_id)
      await UserService().addCandidateToSelector(
        selectorId: req['to_user_id'],
        candidateId: req['from_user_id'],
      );
    } else if (req['type'] == 'candidate') {
      // Seçici, adayı kendi listesine ekler (selector_id: from_user_id, candidate_id: to_user_id)
      await UserService().addCandidateToSelector(
        selectorId: req['from_user_id'],
        candidateId: req['to_user_id'],
      );
    }
    setState(() {});
  }

  Future<void> _handleRejectRequest(Map<String, dynamic> req) async {
    final client = await SupabaseService().client;
    await client
        .from('selector_candidate_requests')
        .update({'status': 'rejected'})
        .eq('id', req['id']);
    setState(() {});
  }

  // 3. Gelen istekler widget'ı
  Widget _buildIncomingRequestsSection(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getIncomingRequests(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        final requests = snapshot.data!;
        if (requests.isEmpty) return SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Text(
                'Gelen İstekler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...requests.map(
              (req) => Card(
                child: ListTile(
                  title: Text(
                    req['type'] == 'selector'
                        ? '${req['from_user_id']} sizi seçici olarak eklemek istiyor'
                        : '${req['from_user_id']} sizi aday olarak eklemek istiyor',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleAcceptRequest(req),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleRejectRequest(req),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeCandidate(UserProfile candidate) {
    setState(() {
      _assignedCandidates.removeWhere((c) => c.id == candidate.id);
      _removedCandidateIds.add(candidate.id);
      if (_selectedCandidate?.id == candidate.id) {
        _selectedCandidate = null;
        _filteredMatches = [];
      }
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthProvider().currentUser;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: 2.h),
                            SizedBox(height: 3.h),
                            _buildTopSection(),
                            SizedBox(height: 3.h),
                            _buildBottomSection(),
                            SizedBox(height: 4.h),
                          ],
                        ),
                      );
                    },
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
          CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
            strokeWidth: 3,
          ),
          SizedBox(height: 3.h),
          Text(
            'Eşleştirme verileri yükleniyor...',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'En uygun adayları buluyoruz',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'error_outline',
                color: AppTheme.errorColor,
                size: 64.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Bir Hata Oluştu',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _error ?? 'Bilinmeyen bir hata oluştu',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 18.w,
              ),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentUser = AuthProvider().currentUser;
    final displayName = currentUser?.email?.split('@').first ?? 'Görücü';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 1.5.h,
      ), // Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba $displayName 👋',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        // Reduced from headlineSmall
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.3.h), // Reduced spacing
                    Text(
                      'Bugün kimler için eşleştirme yapacaksınız?',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        // Reduced from bodyMedium
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(1.5.w), // Reduced padding
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(
                    6.w,
                  ), // Reduced border radius
                ),
                child: Text(
                  '💖',
                  style: TextStyle(fontSize: 18.sp),
                ), // Reduced emoji size
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Text(
                  '👥',
                  style: TextStyle(fontSize: 14.sp),
                ), // Küçültüldü
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Kimin için seçiyorsun?',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCandidateModal,
                icon: Icon(Icons.person_add, size: 18), // Küçültüldü
                label: Text(
                  'Aday Ekle',
                  style: TextStyle(fontSize: 12),
                ), // Küçültüldü
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ), // Küçültüldü
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(0, 32), // Yükseklik küçültüldü
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h), // Küçültüldü
          AnimatedBuilder(
            animation: _selectionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _selectionAnimation.value,
                child: EnhancedCandidateSelectionCarousel(
                  candidates: _assignedCandidates,
                  selectedCandidate: _selectedCandidate,
                  onCandidateSelected: _onCandidateSelected,
                  onRemoveCandidate: _removeCandidate,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return EnhancedPotentialMatchesSection(
      potentialMatches: _filteredMatches,
      selectedCandidate: _selectedCandidate,
      onRefresh: _refreshData,
      onMatchProposal: _onMatchProposal,
      onCardSwiped: _onCardSwiped, // yeni ekle
    );
  }

  void _onCardSwiped(UserProfile candidate, bool isRightSwipe) async {
    // Kartı swipe edince ilgili adaya ait shownCardIds'e ekle
    final candidateId = _selectedCandidate?.id;
    if (candidateId != null) {
      _shownCardIdsPerCandidate.putIfAbsent(candidateId, () => <String>{});
      _shownCardIdsPerCandidate[candidateId]!.add(candidate.id);
    }
    if (isRightSwipe) {
      await _onMatchProposal(candidate);
    }
    setState(() {
      _swipedCandidateIds.add(candidate.id);
      _filteredMatches.removeWhere((c) => c.id == candidate.id);
    });
  }

  Widget _buildBottomNavigationBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.currentUserProfile;
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            if (userProfile != null && userProfile.role == UserRole.candidate) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.candidateHomeScreen,
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeScreen,
                (route) => false,
              );
            }
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
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'list',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Önerilerim',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Adaylarım',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profil',
        ),
      ],
    );
  }

  void _showAddCandidateModal() async {
    final result = await showModalBottomSheet<UserProfile?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddCandidateModal(),
    );
    if (result != null) {
      await _addCandidate(result);
    }
  }

  Future<void> _addCandidate(UserProfile candidate) async {
    try {
      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) return;
      // Adaya istek gönder
      final client = await SupabaseService().client;
      await client.from('selector_candidate_requests').insert({
        'from_user_id': currentUser.id,
        'to_user_id': candidate.id,
        'type': 'candidate', // ADAY İSTEĞİ
        'status': 'pending',
      });
      await _refreshData();
      _showSuccessMessage(
        '${candidate.fullName} kişisine adaylık isteği gönderildi, onay bekleniyor!',
      );
    } catch (e) {
      _showErrorMessage('Aday eklenemedi: $e');
    }
  }
}

// Modal Widget
class _AddCandidateModal extends StatefulWidget {
  @override
  State<_AddCandidateModal> createState() => _AddCandidateModalState();
}

class _AddCandidateModalState extends State<_AddCandidateModal> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  void _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userService = UserService();
      final results = await userService.searchUsers(
        query: _searchController.text.trim(),
        role: UserRole.candidate,
        limit: 10,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aday Ekle', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Aday adı veya e-posta',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _search,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          SizedBox(height: 16),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: TextStyle(color: Colors.red)),
            ),
          if (!_isLoading && _searchResults.isNotEmpty)
            ..._searchResults.map(
              (candidate) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: candidate.imageUrl != null
                      ? NetworkImage(candidate.imageUrl!)
                      : null,
                  child: candidate.imageUrl == null ? Icon(Icons.person) : null,
                ),
                title: Text(candidate.fullName),
                subtitle: Text(candidate.email),
                onTap: () {
                  Navigator.pop(context, candidate);
                },
              ),
            ),
          if (!_isLoading &&
              _searchResults.isEmpty &&
              _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Aday bulunamadı.'),
            ),
        ],
      ),
    );
  }
}
