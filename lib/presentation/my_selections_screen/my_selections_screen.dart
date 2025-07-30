import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';

class MySelectionsScreen extends StatefulWidget {
  const MySelectionsScreen({super.key});

  @override
  State<MySelectionsScreen> createState() => _MySelectionsScreenState();
}

class _MySelectionsScreenState extends State<MySelectionsScreen> {
  bool _isLoading = true;
  List<MatchProposal> _proposals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyProposals();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMyProposals() async {
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

      // Load proposals created by this selector
      final matchProposalService = MatchProposalService();
      final proposals =
          await matchProposalService.getProposalsBySelector(currentUser.id);

      setState(() {
        _proposals = proposals;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Öneriler yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MatchProposal> get _filteredProposals {
    List<MatchProposal> filtered = _proposals;

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  Widget _buildModernBody() {
    if (_isLoading) {
      return _buildModernLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildModernErrorScreen();
    }

    if (_proposals.isEmpty) {
      return _buildModernEmptyScreen();
    }

    return RefreshIndicator(
      onRefresh: _loadMyProposals,
      child: Column(
        children: [
          // Story-like header with recent activities
          _buildActivityStoryHeader(),
          SizedBox(height: 2.h),
          
          // Activity feed style proposals
          _buildActivityFeed(),
        ],
      ),
    );
  }


  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActivityStoryHeader() {
    final recentMatches = _proposals.where((p) => 
      p.status == AcceptanceStatus.accepted && 
      p.targetStatus == AcceptanceStatus.accepted &&
      DateTime.now().difference(p.createdAt).inDays <= 7
    ).take(3).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF667EEA), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          
          // Story-like horizontal scroll
          if (recentMatches.isNotEmpty)
            SizedBox(
              height: 25.w,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentMatches.length,
                itemBuilder: (context, index) {
                  final proposal = recentMatches[index];
                  return Container(
                    margin: EdgeInsets.only(right: 3.w),
                    child: _buildStoryCircle(proposal),
                  );
                },
              ),
            )
          else
            Container(
              height: 15.w,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Center(
                child: Text(
                  'No recent matches',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(MatchProposal proposal) {
    return GestureDetector(
      onTap: () => _showMatchCelebration(proposal),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 1.w,
                  top: 1.w,
                  child: CircleAvatar(
                    radius: 8.w,
                    backgroundImage: proposal.candidateImageUrl != null 
                      ? NetworkImage(proposal.candidateImageUrl!) 
                      : null,
                    backgroundColor: Colors.grey[300],
                    child: proposal.candidateImageUrl == null 
                      ? Icon(Icons.person, size: 6.w, color: Colors.grey[600]) 
                      : null,
                  ),
                ),
                Positioned(
                  right: 1.w,
                  bottom: 1.w,
                  child: CircleAvatar(
                    radius: 6.w,
                    backgroundImage: proposal.targetCandidateImageUrl != null 
                      ? NetworkImage(proposal.targetCandidateImageUrl!) 
                      : null,
                    backgroundColor: Colors.grey[300],
                    child: proposal.targetCandidateImageUrl == null 
                      ? Icon(Icons.person, size: 4.w, color: Colors.grey[600]) 
                      : null,
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Match!',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667EEA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: _filteredProposals.map((proposal) => 
          Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: _buildActivityCard(proposal),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildActivityCard(MatchProposal proposal) {
    final isMatched = proposal.status == AcceptanceStatus.accepted && 
                     proposal.targetStatus == AcceptanceStatus.accepted;
    final isRejected = proposal.status == AcceptanceStatus.rejected || 
                      proposal.targetStatus == AcceptanceStatus.rejected;
    
    return GestureDetector(
      onTap: () => isMatched ? _showMatchCelebration(proposal) : _showProposalDetails(proposal),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isMatched ? _buildMatchCard(proposal) : _buildRegularActivityCard(proposal),
      ),
    );
  }

  Widget _buildMatchCard(MatchProposal proposal) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF667EEA).withOpacity(0.1),
            Color(0xFF764BA2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF667EEA).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Match announcement header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, color: Colors.white, size: 4.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFF2D3748)),
                    children: [
                      TextSpan(text: 'You found '),
                      TextSpan(
                        text: '${proposal.candidateName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: '${proposal.targetCandidateName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' a match!'),
                    ],
                  ),
                ),
              ),
              Text(
                _getTimeAgo(proposal.createdAt),
                style: TextStyle(fontSize: 10.sp, color: Color(0xFF718096)),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          
          // Big "IT'S A MATCH!" section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Profile images
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 8.w,
                      backgroundImage: proposal.candidateImageUrl != null 
                        ? NetworkImage(proposal.candidateImageUrl!) 
                        : null,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: proposal.candidateImageUrl == null 
                        ? Icon(Icons.person, color: Colors.white, size: 6.w) 
                        : null,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(Icons.favorite, color: Colors.white, size: 8.w),
                    ),
                    CircleAvatar(
                      radius: 8.w,
                      backgroundImage: proposal.targetCandidateImageUrl != null 
                        ? NetworkImage(proposal.targetCandidateImageUrl!) 
                        : null,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: proposal.targetCandidateImageUrl == null 
                        ? Icon(Icons.person, color: Colors.white, size: 6.w) 
                        : null,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  "IT'S A",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "MATCH!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Social engagement
          Row(
            children: [
              Row(
                children: List.generate(3, (index) => 
                  Container(
                    margin: EdgeInsets.only(right: 1.w),
                    child: CircleAvatar(
                      radius: 2.5.w,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 3.w, color: Colors.grey[600]),
                    ),
                  )
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '2 friends ship this',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 3.w, color: Color(0xFF667EEA)),
                    SizedBox(width: 1.w),
                    Text(
                      'Send Message',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegularActivityCard(MatchProposal proposal) {
    final isRejected = proposal.status == AcceptanceStatus.rejected || 
                      proposal.targetStatus == AcceptanceStatus.rejected;
    
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isRejected ? Color(0xFFE53E3E) : Color(0xFFED8936),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.close : Icons.hourglass_empty,
                  color: Colors.white,
                  size: 4.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFF2D3748)),
                    children: [
                      TextSpan(text: isRejected ? 'You proposed ' : 'You are shipping '),
                      TextSpan(
                        text: '${proposal.candidateName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: '${proposal.targetCandidateName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: isRejected ? ' but it was declined' : '.'),
                    ],
                  ),
                ),
              ),
              Text(
                _getTimeAgo(proposal.createdAt),
                style: TextStyle(fontSize: 10.sp, color: Color(0xFF718096)),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          
          // Profile images row
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 6.w,
                    backgroundImage: proposal.candidateImageUrl != null 
                      ? NetworkImage(proposal.candidateImageUrl!) 
                      : null,
                    backgroundColor: Colors.grey[300],
                    child: proposal.candidateImageUrl == null 
                      ? Icon(Icons.person, size: 4.w, color: Colors.grey[600]) 
                      : null,
                  ),
                  Positioned(
                    right: -3.w,
                    child: CircleAvatar(
                      radius: 5.w,
                      backgroundImage: proposal.targetCandidateImageUrl != null 
                        ? NetworkImage(proposal.targetCandidateImageUrl!) 
                        : null,
                      backgroundColor: Colors.grey[300],
                      child: proposal.targetCandidateImageUrl == null 
                        ? Icon(Icons.person, size: 3.w, color: Colors.grey[600]) 
                        : null,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${proposal.candidateName} & ${proposal.targetCandidateName}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      isRejected ? 'Proposal declined' : 'Waiting for response...',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isRejected ? Color(0xFFE53E3E) : Color(0xFFED8936),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_red_eye, size: 3.w, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  Widget _buildModernLoadingScreen() {
    return Container(
      height: 70.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Öneriler yükleniyor...',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernErrorScreen() {
    return Container(
      height: 70.h,
      child: Center(
        child: _buildGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFE53E3E),
              ),
              SizedBox(height: 2.h),
              Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _errorMessage ?? 'Bilinmeyen hata',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadMyProposals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernEmptyScreen() {
    return Container(
      height: 70.h,
      child: Center(
        child: _buildGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 48,
                  color: Color(0xFF667EEA),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Henüz öneri yok',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'İlk önerinizi oluşturmak için ana sayfaya gidin',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Glassmorphism
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA).withAlpha(230),
                    Color(0xFF764BA2).withAlpha(230),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 4.w, bottom: 2.h),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Önerilerim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_filteredProposals.length} öneri',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 4.w, top: 1.h),
                child: IconButton(
                  onPressed: _loadMyProposals,
                  icon: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Modern Body Content
          SliverToBoxAdapter(
            child: _buildModernBody(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // My Selections tab active
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(
                  context, '/enhanced-selector-home-screen');
              break;
            case 1:
              // Already on my-selections-screen
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/my-selectors-screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile-screen');
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
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'list',
              color: AppTheme.lightTheme.colorScheme.primary,
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
      ),
    );
  }

  void _showProposalDetails(MatchProposal proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: Color(0xFF718096),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Öneri Detayları',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildActivityCard(proposal),
                    SizedBox(height: 2.h),
                    // Proposal bilgileri
                    _buildProposalInfo(proposal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalInfo(MatchProposal proposal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öneri Bilgileri',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Oluşturulma', _getTimeAgo(proposal.createdAt)),
              SizedBox(height: 1.h),
              _buildInfoRow('Durum', _getStatusText(proposal)),
              if (proposal.candidateBio?.isNotEmpty == true) ...[
                SizedBox(height: 1.h),
                _buildInfoRow('Aday 1 Bio', proposal.candidateBio!),
              ],
              if (proposal.targetCandidateBio?.isNotEmpty == true) ...[
                SizedBox(height: 1.h),
                _buildInfoRow('Aday 2 Bio', proposal.targetCandidateBio!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5568),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(MatchProposal proposal) {
    if (proposal.status == AcceptanceStatus.accepted && proposal.targetStatus == AcceptanceStatus.accepted) {
      return 'Eşleşti ✅';
    } else if (proposal.status == AcceptanceStatus.rejected || proposal.targetStatus == AcceptanceStatus.rejected) {
      return 'Reddedildi ❌';
    } else {
      return 'Bekliyor ⏳';
    }
  }

  void _showMatchCelebration(MatchProposal proposal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: 8.w),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: Colors.white, size: 6.w),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              
              // Profile images
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 12.w,
                    backgroundImage: proposal.candidateImageUrl != null 
                      ? NetworkImage(proposal.candidateImageUrl!) 
                      : null,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: proposal.candidateImageUrl == null 
                      ? Icon(Icons.person, color: Colors.white, size: 8.w) 
                      : null,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Icon(Icons.favorite, color: Colors.white, size: 12.w),
                  ),
                  CircleAvatar(
                    radius: 12.w,
                    backgroundImage: proposal.targetCandidateImageUrl != null 
                      ? NetworkImage(proposal.targetCandidateImageUrl!) 
                      : null,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: proposal.targetCandidateImageUrl == null 
                      ? Icon(Icons.person, color: Colors.white, size: 8.w) 
                      : null,
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              
              // Match text
              Text(
                "EŞLEŞTİNİZ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "${proposal.candidateName} and ${proposal.targetCandidateName} liked each other!",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, color: Colors.white, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate to chat
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble, color: Color(0xFF667EEA), size: 5.w),
                            SizedBox(width: 2.w),
                            Text(
                              'Send Message',
                              style: TextStyle(
                                color: Color(0xFF667EEA),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

