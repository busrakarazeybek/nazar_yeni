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
  UserProfile? lastSwipedCandidate;
  bool _hasCheckedArguments = false;
  bool _isRequestsExpanded = false; // Gelen istekler açık/kapalı durumu

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only check arguments once
    if (!_hasCheckedArguments) {
      _hasCheckedArguments = true;

      // Check for pre-selected candidate from navigation arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('selectedCandidateId')) {
        final selectedCandidateId = args['selectedCandidateId'] as String;
        print('Pre-selecting candidate with ID: $selectedCandidateId');

        // Wait for data to load, then select the candidate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectCandidateById(selectedCandidateId);
        });
      }

      // Sayfa her açıldığında verileri yenile
      _refreshData();
    }
  }

  void _selectCandidateById(String candidateId) {
    try {
      final candidate = _assignedCandidates.firstWhere(
        (c) => c.id == candidateId,
      );

      print('Found and selecting candidate: ${candidate.fullName}');
      _onCandidateSelected(candidate);
    } catch (e) {
      print('Candidate with ID $candidateId not found in assigned candidates');
      // If the specific candidate is not found, select the first one if available
      if (_assignedCandidates.isNotEmpty) {
        print(
            'Selecting first available candidate: ${_assignedCandidates.first.fullName}');
        _onCandidateSelected(_assignedCandidates.first);
      }
    }
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

      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
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

        // Default aday profili kaldırıldı - sadece gerçek adaylar gösterilecek
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
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
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

  void _filterMatchesForCandidate(UserProfile candidate) async {
    final excludedIds = <String>{..._swipedCandidateIds};

    // Add previously rejected and approved candidates
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
    if (currentUser != null) {
      final rejectedIds = await _userService.getRejectedCandidatesForSelector(
        selectorId: currentUser.id,
        candidateId: candidate.id,
      );
      final approvedIds = await _userService.getApprovedCandidatesForSelector(
        selectorId: currentUser.id,
        candidateId: candidate.id,
      );
      excludedIds.addAll(rejectedIds);
      excludedIds.addAll(approvedIds);
    }

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
          final intersect = match.interests?.toSet().intersection(
                    candidate.preferredInterests!.toSet(),
                  ) ??
              {};
          if (intersect.isEmpty) return false;
        }
        // Cinsiyet filtresi
        if (candidate.preferredGenders != null &&
            candidate.preferredGenders!.isNotEmpty) {
          final matchGender = match.gender?.toString().toLowerCase() ?? '';
          final allowedGenders =
              candidate.preferredGenders!.map((g) => g.toLowerCase()).toList();
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

  Future<void> _onMatchProposal(UserProfile targetCandidate,
      {String selectorStatus = 'approved'}) async {
    if (_selectedCandidate == null) return;

    try {
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
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
                  selectorStatus == 'approved'
                      ? 'Eşleştirme önerisi gönderiliyor...'
                      : 'İşleniyor...',
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
        selectorStatus: selectorStatus,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Increment proposal counter
      setState(() {
        _proposalCounter++;
      });

      // Show success message only for approved status
      if (selectorStatus == 'approved') {
        _showSuccessMessage(
          '${_selectedCandidate!.fullName} için ${targetCandidate.fullName} ile eşleşme önerisi gönderildi!',
        );
      }
      // No message for rejected cards - silent rejection

      // Refresh data kaldırıldı - kartı zaten sildik, yeniden yüklemeye gerek yok
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
    try {
      final client = await SupabaseService().client;
      await client
          .from('selector_candidate_requests')
          .update({'status': 'accepted'}).eq('id', req['id']);

      // Gerçek ilişkiyi oluştur (duplicate kontrolü ile)
      if (req['type'] == 'selector') {
        // Aday, seçiciyi kendi listesine ekler (selector_id: to_user_id, candidate_id: from_user_id)
        try {
          await UserService().addCandidateToSelector(
            selectorId: req['to_user_id'],
            candidateId: req['from_user_id'],
          );
        } catch (e) {
          // Eğer zaten ilişki varsa, sadece devam et
          if (!e.toString().contains('duplicate key')) {
            rethrow; // Başka bir hata ise yeniden fırlat
          }
        }
      } else if (req['type'] == 'candidate') {
        // Seçici, adayı kendi listesine ekler (selector_id: from_user_id, candidate_id: to_user_id)
        try {
          await UserService().addCandidateToSelector(
            selectorId: req['from_user_id'],
            candidateId: req['to_user_id'],
          );
        } catch (e) {
          // Eğer zaten ilişki varsa, sadece devam et
          if (!e.toString().contains('duplicate key')) {
            rethrow; // Başka bir hata ise yeniden fırlat
          }
        }
      }
      
      // Başarılı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstek kabul edildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRejectRequest(Map<String, dynamic> req) async {
    try {
      final client = await SupabaseService().client;
      await client
          .from('selector_candidate_requests')
          .update({'status': 'rejected'}).eq('id', req['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstek reddedildi!'),
          backgroundColor: Colors.orange,
        ),
      );
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 3. Gelen istekler widget'ı
  Widget _buildIncomingRequestsSection(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getIncomingRequests(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        final requests = snapshot.data!;
        if (requests.isEmpty) return SizedBox();
        
        return FutureBuilder<List<UserProfile>>(
          future: Future.wait(
            requests.map(
              (req) => _userService.getUserProfile(req['from_user_id']),
            ),
          ).then((list) => list.whereType<UserProfile>().toList()),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return SizedBox();
            final userProfiles = userSnapshot.data!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isRequestsExpanded = !_isRequestsExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 5.w,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gelen İstekler',
                                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.lightTheme.primaryColor,
                                ),
                              ),
                              Text(
                                '${requests.length} yeni istek - ${_isRequestsExpanded ? "Gizle" : "Göster"}',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${requests.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              _isRequestsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppTheme.lightTheme.primaryColor,
                              size: 6.w,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isRequestsExpanded) ...[
                  SizedBox(height: 2.h),
                  ...List.generate(requests.length, (i) {
                  final req = requests[i];
                  final fromUser = userProfiles[i];
                  final fromUserName = fromUser.fullName;
                  final relation = req['relation'] ?? '';
                  
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.lightTheme.primaryColor.withOpacity(0.05),
                            AppTheme.lightTheme.primaryColor.withOpacity(0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 6.w,
                                backgroundImage: fromUser.imageUrl != null
                                    ? NetworkImage(fromUser.imageUrl!)
                                    : null,
                                child: fromUser.imageUrl == null
                                    ? Icon(Icons.person, size: 4.w)
                                    : null,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fromUserName,
                                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (relation.isNotEmpty)
                                      Text(
                                        '$relation olarak',
                                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.lightTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Text(
                                  'YENİ',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    req['type'] == 'selector'
                                        ? 'Sizi seçici olarak eklemek istiyor'
                                        : 'Sizi aday olarak eklemek istiyor',
                                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleRejectRequest(req),
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 4.w,
                                  ),
                                  label: Text(
                                    'Reddet',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleAcceptRequest(req),
                                  icon: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 4.w,
                                  ),
                                  label: Text(
                                    'Kabul Et',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  }),
                ],
              ],
            );
          },
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
                                SizedBox(height: 1.h),
                                _buildTopSection(),
                                SizedBox(height: 2.h),
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
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
    final displayName = currentUser?.fullName?.split(' ').first ?? 'Görücü';

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
          // Bildirim bölümü ekle
          Builder(
            builder: (context) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUserProfile;
              if (currentUser != null) {
                return _buildIncomingRequestsSection(currentUser.id);
              }
              return SizedBox.shrink();
            },
          ),
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
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              // Refresh butonu ekle
              IconButton(
                onPressed: _refreshData,
                icon: Icon(Icons.refresh, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.lightTheme.primaryColor,
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
                child: _assignedCandidates.isEmpty
                    ? _buildAddCandidateButton()
                    : EnhancedCandidateSelectionCarousel(
                        candidates: _assignedCandidates,
                        selectedCandidate: _selectedCandidate,
                        onCandidateSelected: _onCandidateSelected,
                        onRemoveCandidate: _removeCandidate,
                        onAddCandidate: _showAddCandidateModal,
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
      onCardSwiped: _onCardSwiped,
    );
  }

  void _onCardSwiped(String candidateName, bool isRightSwipe) {
    // Swipe edilen kartı callback'den gelen isim ile bul
    UserProfile? swipedCandidate;
    try {
      swipedCandidate = _filteredMatches.firstWhere(
        (candidate) => candidate.fullName == candidateName,
      );
    } catch (e) {
      // İsim ile bulunamadıysa, en üstteki kartı al (fallback)
      final visibleCount = _filteredMatches.length.clamp(0, 3);
      final topVisualIndex = visibleCount - 1; // En üstteki kartın indexi (max 2)
      swipedCandidate =
          topVisualIndex >= 0 ? _filteredMatches[topVisualIndex] : null;
    }

    if (swipedCandidate == null || _selectedCandidate == null) {
      return;
    }

    // Kartı listeden çıkar
    setState(() {
      _filteredMatches.remove(swipedCandidate);
    });

    // Eşleştirme işlemi yap
    if (isRightSwipe) {
      _onMatchProposal(swipedCandidate, selectorStatus: 'approved');
    } else {
      _onMatchProposal(swipedCandidate, selectorStatus: 'rejected');
    }
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

  Widget _buildAddCandidateButton() {
    return Container(
      height: 8.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showAddCandidateModal,
            child: Container(
              width: 20.w,
              height: 5.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.6),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: AppTheme.lightTheme.primaryColor,
                    size: 18,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Aday Ekle',
                    style: AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
      if (currentUser == null) return;

      // Check if candidate is already added
      final isAlreadyAdded = await UserService().isCandidateAlreadyAdded(
        selectorId: currentUser.id,
        candidateId: candidate.id,
      );

      if (isAlreadyAdded) {
        _showErrorMessage('Bu aday zaten ekli');
        return;
      }

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
  List<String> _alreadyAddedCandidates = [];
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

      // Check for already added candidates
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      List<String> alreadyAddedIds = [];
      if (currentUser != null) {
        for (final candidate in results) {
          final isAlreadyAdded = await userService.isCandidateAlreadyAdded(
            selectorId: currentUser.id,
            candidateId: candidate.id,
          );
          if (isAlreadyAdded) {
            alreadyAddedIds.add(candidate.id);
          }
        }
      }
      
      setState(() {
        _searchResults = results;
        _alreadyAddedCandidates = alreadyAddedIds;
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
              (candidate) {
                final isAlreadyAdded = _alreadyAddedCandidates.contains(candidate.id);
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: candidate.imageUrl != null
                            ? NetworkImage(candidate.imageUrl!)
                            : null,
                        child: candidate.imageUrl == null ? Icon(Icons.person) : null,
                      ),
                      title: Text(candidate.fullName),
                      subtitle: Text(candidate.email),
                      trailing: isAlreadyAdded 
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        if (isAlreadyAdded) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bu aday zaten ekli'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          Navigator.pop(context, candidate);
                        }
                      },
                    ),
                    if (isAlreadyAdded)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700], size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Bu aday zaten ekli',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
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
