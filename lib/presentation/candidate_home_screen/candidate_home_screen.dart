import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
import '../../widgets/match_celebration_dialog.dart';
import './widgets/suggested_candidates_section_widget.dart';

class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<UserProfile> _selectors = [];
  List<MatchProposal> _proposals = [];
  UserProfile? _selectedSelector;
  String? _errorMessage;
  late TabController _tabController;
  int _newMatchesCount = 0;
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectionAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Kullanıcı oturumu bulunamadı';
        });
        return;
      }

      // Load proposals for this candidate
      final matchProposalService = MatchProposalService();
      final proposals = await matchProposalService.getProposalsForCandidate(
        currentUser.id,
      );

      // Extract unique selectors from proposals
      final selectorIds = proposals.map((p) => p.selectorId).toSet().toList();

      final userService = UserService();
      final selectors = <UserProfile>[];

      for (final selectorId in selectorIds) {
        try {
          final selector = await userService.getUserProfile(selectorId);
          if (selector != null) {
            selectors.add(selector);
          }
        } catch (e) {
          print('Error loading selector $selectorId: $e');
        }
      }

      // Yeni eşleşmeleri say
      final matchedProposals = proposals.where((p) => 
        p.status == AcceptanceStatus.accepted && 
        p.targetStatus == AcceptanceStatus.accepted
      ).toList();
      
      // SharedPreferences ile badge durumunu kontrol et
      final prefs = await SharedPreferences.getInstance();
      final hasViewedMatches = prefs.getBool('hasViewedMatches_${currentUser.id}') ?? false;
      
      setState(() {
        _proposals = proposals;
        _selectors = selectors;
        
        // Badge'i sadece görüntülenmediyse göster
        if (!hasViewedMatches) {
          _newMatchesCount = matchedProposals.length;
        } else {
          _newMatchesCount = 0;
        }
        
        // Auto-select first selector if available
        if (_selectors.isNotEmpty && _selectedSelector == null) {
          _selectedSelector = _selectors.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markMatchesAsViewed() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasViewedMatches_${currentUser.id}', true);
        
        setState(() {
          _newMatchesCount = 0;
        });
      }
    } catch (e) {
      print('Error marking matches as viewed: $e');
    }
  }

  List<MatchProposal> get _filteredProposals {
    if (_selectedSelector == null) return [];
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;
    if (currentUser == null) return [];
    
    return _proposals
        .where(
          (p) {
            // Only show proposals from the selected selector
            if (p.selectorId != _selectedSelector!.id) return false;
            
            // Don't show if selector has rejected the proposal
            if (p.selectorStatus == AcceptanceStatus.rejected) return false;
            
            // Determine if current user is the candidate or target candidate
            if (p.candidateId == currentUser.id) {
              // Current user is the first candidate - only show if they haven't responded
              return p.status == AcceptanceStatus.pending;
            } else if (p.targetCandidateId == currentUser.id) {
              // Current user is the target candidate - only show if they haven't responded
              return p.targetStatus == AcceptanceStatus.pending;
            }
            
            // Current user is not part of this proposal
            return false;
          },
        )
        .toList();
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
      // Loading dialog göster
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
                  'İstek kabul ediliyor...',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
      
      final client = await SupabaseService().client;
      await client
          .from('selector_candidate_requests')
          .update({
            'status': 'accepted',
          }).eq('id', req['id']);

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
      
      // Loading dialog'ı kapat
      Navigator.of(context).pop();
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 2.w),
              Text('İstek başarıyla kabul edildi!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Verileri yenile
      await _loadData();
    } catch (e) {
      // Loading dialog'ı kapat
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstek kabul edilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRejectRequest(Map<String, dynamic> req) async {
    try {
      // Loading dialog göster
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
                  'İstek reddediliyor...',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
      
      final client = await SupabaseService().client;
      await client
          .from('selector_candidate_requests')
          .update({
            'status': 'rejected',
          }).eq('id', req['id']);
      
      // Loading dialog'ı kapat
      Navigator.of(context).pop();
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 2.w),
              Text('İstek reddedildi'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Verileri yenile
      await _loadData();
    } catch (e) {
      // Loading dialog'ı kapat
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstek reddedilirken hata oluştu: $e'),
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
              (req) => UserService().getUserProfile(req['from_user_id']),
            ),
          ).then((list) => list.whereType<UserProfile>().toList()),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return SizedBox();
            final userProfiles = userSnapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                              '${requests.length} yeni istek',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.lightTheme.primaryColor.withOpacity(0.8),
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
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                ...List.generate(requests.length, (i) {
                  final req = requests[i];
                  final fromUser = userProfiles[i];
                  final fromUserName = fromUser.fullName ?? req['from_user_id'];
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        if (currentUser != null) _buildIncomingRequestsSection(currentUser.id),
        // Only show empty screen if not loading AND selectors are actually empty
        if (!_isLoading && _selectors.isEmpty)
          _buildEmptySelectorsScreen()
        else if (!_isLoading && _selectors.isNotEmpty) ...[
          // My Selectors Section with responsive layout
          _buildMySelectorsSection(),
          SizedBox(height: 3.h),
          // Suggested Candidates Section
          SuggestedCandidatesSection(
            proposals: _filteredProposals,
            selectedSelector: _selectedSelector,
            onAcceptProposal: _acceptProposal,
            onRejectProposal: _rejectProposal,
            onViewProfile: _viewCandidateProfile,
            currentUser: currentUser!,
          ),
        ],
      ],
    );
  }

  Widget _buildMySelectorsSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor.withAlpha(
                              26,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'people',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 5.w,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Görücülerim',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildAddSelectorButton(),
            ],
          ),
          // Selectors horizontal list
          AnimatedBuilder(
            animation: _selectionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _selectionAnimation.value,
                child: _buildSelectorsHorizontalList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddSelectorButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('🔥 Görücü Ekle butonu CLICKED!');
            _handleAddSelector();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 3.w),
                SizedBox(width: 1.w),
                Text(
                  'Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorsHorizontalList() {
    return SizedBox(
      height: 15.h, // Enhanced selector style height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _selectors.length,
        itemBuilder: (context, index) {
          final selector = _selectors[index];
          final isSelected = _selectedSelector?.id == selector.id;
          final pendingCount =
              _getPendingCountsForSelectors()[selector.id] ?? 0;

          return _buildEnhancedSelectorCard(
            selector: selector,
            isSelected: isSelected,
            pendingCount: pendingCount,
            onTap: () => _handleSelectorSelection(selector),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedSelectorCard({
    required UserProfile selector,
    required bool isSelected,
    required int pendingCount,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 12.w : 10.w,
                  height: isSelected ? 12.w : 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: selector.imageUrl != null && selector.imageUrl!.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: selector.imageUrl!,
                            width: isSelected ? 12.w : 10.w,
                            height: isSelected ? 12.w : 10.w,
                            fit: BoxFit.cover,
                            errorWidget: _buildDefaultSelectorAvatar(selector, isSelected),
                          )
                        : _buildDefaultSelectorAvatar(selector, isSelected),
                  ),
                ),
                // Pending count badge
                if (pendingCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorColor.withOpacity(0.5),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(minWidth: 5.w, minHeight: 5.w),
                      child: Text(
                        pendingCount > 99 ? '99+' : pendingCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              style: AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: isSelected ? 12.sp : 11.sp,
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              child: Container(
                width: 16.w,
                child: Text(
                  selector.fullName.split(' ').first,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSelectorAvatar(UserProfile selector, bool isSelected) {
    return Container(
      width: isSelected ? 12.w : 10.w,
      height: isSelected ? 12.w : 10.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor.withOpacity(0.8),
            AppTheme.accentColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: isSelected ? 4.w : 3.w,
      ),
    );
  }

  Widget _buildSelectorCard({
    required UserProfile selector,
    required bool isSelected,
    required int pendingCount,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(right: 3.w),
      width: 16.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.lightTheme.primaryColor.withAlpha(26),
                        AppTheme.lightTheme.primaryColor.withAlpha(13),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [Colors.white, Colors.grey[50]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor.withAlpha(26)
                      : Colors.black.withAlpha(8),
                  blurRadius: isSelected ? 12 : 4,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: isSelected ? 7.w : 6.w,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: selector.imageUrl != null
                            ? NetworkImage(selector.imageUrl!)
                            : null,
                        child: selector.imageUrl == null
                            ? Icon(
                                Icons.person,
                                size: isSelected ? 7.w : 6.w,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 5.w,
                            minHeight: 5.w,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  selector.fullName,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  SizedBox(height: 0.5.h),
                  Container(
                    width: 4.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelectorSelection(UserProfile selector) {
    setState(() {
      _selectedSelector = selector;
    });

    _selectionAnimationController.reset();
    _selectionAnimationController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleAddSelector() async {
    print('Add selector button tapped'); // Debug
    final result = await showModalBottomSheet<AddSelectorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddSelectorBottomSheet(),
    );

    if (result != null && result.user != null && result.relation != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUserProfile;
        if (currentUser != null) {
          final client = await SupabaseService().client;
          await client.from('selector_candidate_requests').insert({
            'from_user_id': currentUser.id,
            'to_user_id': result.user!.id,
            'type': 'selector',
            'status': 'pending',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Görücüye istek gönderildi, onay bekleniyor!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görücü ekleme isteği gönderilemedi'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAddSelectorBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 3.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: AddSelectorDialog(),
    );
  }

  // 1. Tüm öneriler sekmesinde sadece pending olanları göster
  Widget _buildAllProposalsBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }
    // SADECE PENDING OLANLARI GÖSTER
    final pendingProposals = _proposals
        .where(
          (p) =>
              p.status == AcceptanceStatus.pending &&
              p.targetStatus == AcceptanceStatus.pending,
        )
        .toList();

    if (pendingProposals.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'search_off',
                color: Colors.grey[400]!,
                size: 48.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'Henüz Öneri Yok',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Sana gelen tüm eşleşme önerileri burada listelenir.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        SuggestedCandidatesSection(
          proposals: pendingProposals,
          selectedSelector: null, // Tüm önerilerde seçici seçimi yok
          onAcceptProposal: _acceptProposal,
          onRejectProposal: _rejectProposal,
          onViewProfile: _viewCandidateProfile,
          currentUser: currentUser!,
        ),
      ],
    );
  }


  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.lightTheme.primaryColor),
          SizedBox(height: 2.h),
          Text(
            'Öneriler yükleniyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.errorColor,
              size: 64.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Hata',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20.w,
              ),
              label: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySelectorsScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 60.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'people_outline',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 80,
                  ),
                  SizedBox(height: 2.h),
                  CustomIconWidget(
                    iconName: 'favorite',
                    color: AppTheme.accentColor,
                    size: 40,
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Title
            Text(
              "Henüz Seçiciniz Yok",
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),

            // Description
            Text(
              "Seçiciler, sizin için uygun eşleri bulup önerebilecek güvenilir kişilerdir. Aile üyelerinizi veya yakın arkadaşlarınızı seçici olarak davet edebilirsiniz.",
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Benefits
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Seçici Avantajları",
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildBenefitItem(
                    "Güvenilir Eşleşmeler",
                    "Sizi tanıyan kişiler daha uygun eşler önerir",
                    'verified',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildBenefitItem(
                    "Kültürel Uyum",
                    "Geleneksel değerlerinize uygun öneriler",
                    'favorite',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildBenefitItem(
                    "Aile Desteği",
                    "Ailenizin onayladığı ilişkiler",
                    'family_restroom',
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Call to Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddSelectorDialog,
                icon: CustomIconWidget(
                  iconName: 'person_add',
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text("İlk Seçicinizi Ekleyin"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Secondary Action
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-screen');
              },
              icon: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 18,
              ),
              label: const Text("Profilimi Tamamla"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, String iconName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksStep({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 14.w,
            ),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSelectorDialog() async {
    final TextEditingController emailController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.primaryColor,
              size: 24.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Seçici Ekle',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sizin için eşleşme bulacak kişinin email adresini girin:',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Adresi',
                hintText: 'ornek@email.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 16.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Bu kişi sizin için uygun adayları bulup eşleştirme önerileri gönderecek.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.w),
              ),
            ),
            child: Text('Ekle'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.trim().isNotEmpty) {
      await _addSelectorByEmail(emailController.text.trim());
    }
  }

  Future<void> _addSelectorByEmail(String email) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;

      if (currentUser == null) {
        _showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Show loading
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
                  'Seçici ekleniyor...',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );

      await UserService().addSelectorToCandidate(
        candidateId: currentUser.id,
        selectorEmail: email,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
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
              Text('Seçici başarıyla eklendi!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.w),
          ),
        ),
      );

      // Refresh data
      _loadData();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showErrorSnackBar('Seçici eklenirken hata oluştu: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: Colors.white,
              size: 20.w,
            ),
            SizedBox(width: 2.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.w),
        ),
      ),
    );
  }

  bool _checkIfMatched(MatchProposal proposal) {
    return proposal.status == AcceptanceStatus.accepted && 
           proposal.targetStatus == AcceptanceStatus.accepted;
  }

  void _navigateToChat(MatchProposal proposal) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUserProfile!.id;
    final isDirectCandidate = proposal.candidateId == currentUserId;
    
    final partnerId = isDirectCandidate
        ? proposal.targetCandidateId
        : proposal.candidateId;
    final partnerName = isDirectCandidate
        ? proposal.targetCandidateName ?? 'Eşiniz'
        : proposal.candidateName ?? 'Eşiniz';
    final partnerImageUrl = isDirectCandidate
        ? proposal.targetCandidateImageUrl
        : proposal.candidateImageUrl;

    Navigator.pushNamed(
      context,
      AppRoutes.chatScreen,
      arguments: {
        'matchId': proposal.id,
        'partnerId': partnerId,
        'partnerName': partnerName,
        'partnerImageUrl': partnerImageUrl,
      },
    );
  }

  Map<String, int> _getPendingCountsForSelectors() {
    final counts = <String, int>{};
    for (final selector in _selectors) {
      final pendingCount = _proposals
          .where((p) => p.selectorId == selector.id && p.isPending)
          .length;
      counts[selector.id] = pendingCount;
    }
    return counts;
  }

  Future<void> _acceptProposal(MatchProposal proposal) async {
    try {
      final matchProposalService = MatchProposalService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      if (currentUser == null) throw Exception('Kullanıcı bulunamadı');

      final updatedProposal = await matchProposalService.updateCandidateResponse(
        proposalId: proposal.id,
        candidateId: currentUser.id,
        status: AcceptanceStatus.accepted,
      );

      // Check if this resulted in a match
      final isMatched = _checkIfMatched(updatedProposal);
      
      if (isMatched) {
        // Show celebration dialog for match
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => MatchCelebrationDialog(
            matchProposal: updatedProposal,
            currentUser: currentUser,
            onSendMessage: () => _navigateToChat(updatedProposal),
          ),
        );
      } else {
        // Show simple success message for acceptance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri kabul edildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Update the state to remove the accepted proposal from the list
      setState(() {
        _proposals.removeWhere((p) => p.id == proposal.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri kabul edilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _rejectProposal(MatchProposal proposal) async {
    try {
      final matchProposalService = MatchProposalService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      if (currentUser == null) throw Exception('Kullanıcı bulunamadı');

      await matchProposalService.updateCandidateResponse(
        proposalId: proposal.id,
        candidateId: currentUser.id,
        status: AcceptanceStatus.rejected,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri reddedildi'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Update the state to remove the rejected proposal from the list
      setState(() {
        _proposals.removeWhere((p) => p.id == proposal.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri reddedilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _viewCandidateProfile(MatchProposal proposal) {
    // Navigate to candidate profile detail screen
    Navigator.pushNamed(
      context,
      AppRoutes.candidateProfileDetailScreen,
      arguments: {
        'candidateId': proposal.targetCandidateId, // The other candidate
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0, // Always highlight home
      onTap: (index) {
        print('🔥 Bottom nav CLICKED: $index'); // Debug
        print('🔥 Navigation working!'); // Debug
        switch (index) {
          case 0:
            // Already on home screen
            break;
          case 1:
            // Badge'i kalıcı olarak sıfırla ve matches screen'e git
            _markMatchesAsViewed();
            Navigator.pushNamed(context, '/matches-screen');
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
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'chat',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              if (_newMatchesCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_newMatchesCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Seçicilerim',
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
}

class AddSelectorResult {
  final UserProfile? user;
  final String? relation;
  AddSelectorResult({this.user, this.relation});
}

class AddSelectorDialog extends StatefulWidget {
  const AddSelectorDialog({super.key});

  @override
  State<AddSelectorDialog> createState() => _AddSelectorDialogState();
}

class _AddSelectorDialogState extends State<AddSelectorDialog> {
  final _searchController = TextEditingController();
  final _customRelationController = TextEditingController();
  String? _selectedRelation;
  UserProfile? _selectedUser;
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _isCustomRelation = false;
  String _searchType = 'email'; // 'email' or 'phone'
  String? _duplicateWarning;
  
  final List<String> _relations = [
    'Kardeş',
    'Arkadaş', 
    'Anne',
    'Baba',
    'En yakın kanki',
    'Bacı',
    'Kuzen',
    'Özel İlişki',
  ];

  void _searchUser(String query) async {
    setState(() => _isSearching = true);
    try {
      final userService = UserService();
      List<UserProfile> results = [];
      
      if (_searchType == 'email') {
        results = await userService.searchUsers(
          query: query,
          role: UserRole.selector,
          limit: 10,
        );
      } else if (_searchType == 'phone') {
        results = await userService.searchUsersByPhone(
          phone: query,
          role: UserRole.selector,
          limit: 10,
        );
      }
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectUser(UserProfile user) async {
    setState(() {
      _selectedUser = user;
      _duplicateWarning = null;
    });

    // Check if this selector is already added
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final isAlreadyAdded = await UserService().isSelectorAlreadyAdded(
          candidateId: currentUser.id,
          selectorId: user.id,
        );
        
        if (isAlreadyAdded) {
          setState(() {
            _duplicateWarning = 'Seçiciniz zaten eklidir';
          });
        }
      }
    } catch (e) {
      print('Error checking duplicate selector: $e');
    }
  }

  void _addSelector() {
    // Check for duplicate warning
    if (_duplicateWarning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_duplicateWarning!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? finalRelation = _selectedRelation;
    
    // Check if custom relation is selected and use custom text
    if (_selectedRelation == 'Özel İlişki' && _customRelationController.text.trim().isNotEmpty) {
      finalRelation = _customRelationController.text.trim();
    }
    
    if (_selectedUser != null && finalRelation != null && finalRelation.isNotEmpty) {
      Navigator.pop(
        context,
        AddSelectorResult(user: _selectedUser, relation: finalRelation),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen ilişki ve kullanıcı seçin.')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seçici Ekle', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 20),
            
            // Relationship selection
            Text('İlişkiniz:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRelation,
              items: _relations
                  .map(
                    (relation) => DropdownMenuItem(
                      value: relation,
                      child: Text(relation),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedRelation = val;
                _isCustomRelation = val == 'Özel İlişki';
              }),
              decoration: InputDecoration(
                labelText: 'İlişki seçin',
                border: OutlineInputBorder(),
              ),
            ),
            
            // Custom relationship input
            if (_selectedRelation == 'Özel İlişki') ...[
              SizedBox(height: 12),
              TextField(
                controller: _customRelationController,
                decoration: InputDecoration(
                  labelText: 'Özel ilişki tanımınız (örn: en yakın kankim, bacım)',
                  hintText: 'İlişkinizi yazın...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Search type selection
            Text('Arama türü:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('E-posta'),
                    value: 'email',
                    groupValue: _searchType,
                    onChanged: (val) => setState(() {
                      _searchType = val!;
                      _searchResults.clear();
                      _searchController.clear();
                    }),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Telefon'),
                    value: 'phone',
                    groupValue: _searchType,
                    onChanged: (val) => setState(() {
                      _searchType = val!;
                      _searchResults.clear();
                      _searchController.clear();
                    }),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: _searchType == 'email' 
                    ? 'E-posta adresi girin' 
                    : 'Telefon numarası girin',
                hintText: _searchType == 'email' 
                    ? 'ornek@email.com' 
                    : '05xx xxx xx xx',
                border: OutlineInputBorder(),
                suffixIcon: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Icon(Icons.search),
              ),
              onChanged: (val) {
                if (val.length > 2) _searchUser(val);
              },
            ),
            
            // Search results
            if (_searchResults.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Arama sonuçları:', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _searchResults.map(
                    (user) => ListTile(
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('E-posta: ${user.email}'),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            Text('Telefon: ${user.phone}'),
                        ],
                      ),
                      onTap: () => _selectUser(user),
                      selected: _selectedUser == user,
                      trailing: _selectedUser == user
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      tileColor: _selectedUser == user 
                          ? Colors.green.shade50 
                          : null,
                    ),
                  ).toList(),
                ),
              ),
            ],
            
            // Duplicate warning display
            if (_duplicateWarning != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _duplicateWarning!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSelector,
                icon: Icon(Icons.person_add),
                label: Text('Seçici Ekle'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
