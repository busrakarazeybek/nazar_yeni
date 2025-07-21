import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

      setState(() {
        _proposals = proposals;
        _selectors = selectors;
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

  List<MatchProposal> get _filteredProposals {
    if (_selectedSelector == null) return [];
    return _proposals
        .where(
          (p) =>
              p.selectorId == _selectedSelector!.id &&
              p.status == AcceptanceStatus.pending &&
              p.targetStatus == AcceptanceStatus.pending,
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
    final client = await SupabaseService().client;
    await client
        .from('selector_candidate_requests')
        .update({'status': 'accepted'}).eq('id', req['id']);

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
        .update({'status': 'rejected'}).eq('id', req['id']);
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
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Text(
                    'Gelen İstekler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...List.generate(requests.length, (i) {
                  final req = requests[i];
                  final fromUser = userProfiles[i];
                  final fromUserName =
                      fromUser.fullName ?? req['from_user_id'];
                  return Card(
                    child: ListTile(
                      title: Text(
                        req['type'] == 'selector'
                            ? '$fromUserName sizi seçici olarak eklemek istiyor'
                            : '$fromUserName sizi aday olarak eklemek istiyor',
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
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Eşleşme Önerileri',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.primaryColor,
              size: 24.w,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.lightTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.lightTheme.primaryColor,
          tabs: [
            Tab(text: 'Seçicilerim'),
            Tab(text: 'Tüm Öneriler'),
            Tab(text: 'Eşleşmeler'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBody(), // Seçicilerim sekmesi
            _buildAllProposalsBody(), // Tüm öneriler sekmesi
            _buildMatchesBody(), // Eşleşmeler sekmesi
          ],
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
        if (_selectors.isEmpty)
          _buildEmptySelectorsScreen()
        else ...[
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
      margin: EdgeInsets.only(bottom: 2.h),
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
                        SizedBox(width: 3.w),
                        Text(
                          'Benim Görücülerim',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${_selectors.length} aktif görücü',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAddSelectorButton(),
            ],
          ),
          SizedBox(height: 2.h),
          // Selectors horizontal list
          _buildSelectorsHorizontalList(),
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
          onTap: _handleAddSelector,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Görücü Ekle',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
      height: 32.w,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: _selectors.length,
        itemBuilder: (context, index) {
          final selector = _selectors[index];
          final isSelected = _selectedSelector?.id == selector.id;
          final pendingCount =
              _getPendingCountsForSelectors()[selector.id] ?? 0;

          return _buildSelectorCard(
            selector: selector,
            isSelected: isSelected,
            pendingCount: pendingCount,
            onTap: () => _handleSelectorSelection(selector),
          );
        },
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
      width: 22.w,
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
  }

  void _handleAddSelector() async {
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

  Widget _buildMatchesBody() {
    final matchedProposals = _proposals
        .where(
          (p) =>
              p.status == AcceptanceStatus.accepted &&
              p.targetStatus == AcceptanceStatus.accepted,
        )
        .toList();

    if (_isLoading) return _buildLoadingScreen();
    if (_errorMessage != null) return _buildErrorScreen();

    if (matchedProposals.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'chat',
                color: AppTheme.lightTheme.primaryColor,
                size: 48.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'Henüz eşleşme yok',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Karşılıklı kabul edilen eşleşmeler burada listelenir.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUserProfile;

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: matchedProposals.length,
      itemBuilder: (context, index) {
        final proposal = matchedProposals[index];
        final isCandidate = proposal.candidateId == currentUser?.id;
        final partnerName =
            isCandidate ? proposal.targetCandidateName : proposal.candidateName;
        final partnerImage = isCandidate
            ? proposal.targetCandidateImageUrl
            : proposal.candidateImageUrl;
        final partnerBio =
            isCandidate ? proposal.targetCandidateBio : proposal.candidateBio;
        final matchDate = proposal.updatedAt ?? proposal.createdAt;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.primaryColor.withAlpha(40),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage:
                      partnerImage != null ? NetworkImage(partnerImage) : null,
                  radius: 28,
                  child: partnerImage == null
                      ? Icon(Icons.person, size: 32)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(0.8.w),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            title: Text(
              partnerName ?? 'Bilinmeyen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (partnerBio != null && partnerBio.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h, bottom: 0.5.h),
                    child: Text(
                      partnerBio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                    SizedBox(width: 1.w),
                    Text(
                      'Eşleşme: ${_formatMatchDate(matchDate)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.chatScreen,
                  arguments: {
                    'matchId': proposal.id,
                    'partnerName': partnerName,
                    'partnerImageUrl': partnerImage,
                  },
                );
              },
              icon: Icon(Icons.chat),
              label: Text('Mesajlaş'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
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
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'person_search',
              color: AppTheme.lightTheme.primaryColor,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz sizi eşleştirmeye çalışan bir seçici yok',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Profilinizi güncelleyerek daha fazla seçicinin sizi görmesini sağlayabilirsiniz.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile-screen');
              },
              icon: Icon(Icons.person),
              label: Text('Profilimi Güncelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
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

      await matchProposalService.updateCandidateResponse(
        proposalId: proposal.id,
        candidateId: currentUser.id,
        status: AcceptanceStatus.accepted,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri kabul edildi'),
          backgroundColor: Colors.green,
        ),
      );
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
      currentIndex: _tabController.index,
      onTap: (index) {
        switch (index) {
          case 0:
            _tabController.animateTo(0);
            break;
          case 1:
            _tabController.animateTo(2); // Eşleşmeler sekmesi
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
          icon: CustomIconWidget(
            iconName: 'chat',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Eşleşmeler',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Görücülerim',
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
  final _emailController = TextEditingController();
  String? _selectedRelation;
  UserProfile? _selectedUser;
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  final List<String> _relations = [
    'Kardeş',
    'Arkadaş',
    'Anne',
    'Baba',
    'Diğer',
  ];

  void _searchUser(String query) async {
    setState(() => _isSearching = true);
    try {
      final userService = UserService();
      final results = await userService.searchUsers(
        query: query,
        role: UserRole.selector,
        limit: 10,
      );
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

  void _addSelector() {
    if (_selectedUser != null && _selectedRelation != null) {
      Navigator.pop(
        context,
        AddSelectorResult(user: _selectedUser, relation: _selectedRelation),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen ilişki ve kullanıcı seçin.')),
      );
    }
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
          children: [
            Text('Seçici Ekle', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
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
              onChanged: (val) => setState(() => _selectedRelation = val),
              decoration: InputDecoration(labelText: 'İlişkiniz'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Görücü ara veya e-posta gir',
                suffixIcon: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : null,
              ),
              onChanged: (val) {
                if (val.length > 2) _searchUser(val);
              },
              controller: _emailController,
            ),
            if (_searchResults.isNotEmpty)
              ..._searchResults.map(
                (user) => ListTile(
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  onTap: () => setState(() => _selectedUser = user),
                  selected: _selectedUser == user,
                  trailing: _selectedUser == user
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _addSelector, child: Text('Ekle')),
          ],
        ),
      ),
    );
  }
}
