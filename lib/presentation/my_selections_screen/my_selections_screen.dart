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
  List<Map<String, dynamic>> _notifications = [];

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

      // Load notifications
      final notifications = await _getSelectorNotifications();

      setState(() {
        _proposals = proposals;
        _notifications = notifications;
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

          // Combined notifications and proposals feed
          _buildCombinedActivityFeed(),
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

  Widget _buildCombinedActivityFeed() {
    // Combine notifications and proposals into a single list
    List<Map<String, dynamic>> combinedItems = [];

    // Add notifications
    for (final notification in _notifications) {
      combinedItems.add({
        'type': 'notification',
        'data': notification,
        'created_at': notification['created_at'] as DateTime,
        'isNew': notification['isNew'] as bool,
      });
    }

    // Add proposals (only last 3 days)
    final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
    for (final proposal in _filteredProposals) {
      // Only add proposals from last 3 days
      if (proposal.createdAt.isAfter(threeDaysAgo)) {
        combinedItems.add({
          'type': 'proposal',
          'data': proposal,
          'created_at': proposal.createdAt,
          'isNew': false, // Proposals don't have isNew flag
        });
      }
    }

    // Sort by date (newest first)
    combinedItems.sort((a, b) =>
        (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));

    if (combinedItems.isEmpty) {
      return Container(
        height: 30.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              SizedBox(height: 2.h),
              Text(
                'Henüz aktivite yok',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with notification count
          Row(
            children: [
              Icon(Icons.timeline, color: Color(0xFF667EEA), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Tüm Aktiviteler',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              if (combinedItems.any((item) => item['isNew'] == true))
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${combinedItems.where((item) => item['isNew'] == true).length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),

          // Combined list
          ...combinedItems.map((item) {
            if (item['type'] == 'notification') {
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                child: _buildNotificationCard(
                    item['data'] as Map<String, dynamic>),
              );
            } else {
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                child: _buildActivityCard(item['data'] as MatchProposal),
              );
            }
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isNew = notification['isNew'] as bool;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isNew ? Color(0xFF667EEA).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? Color(0xFF667EEA).withOpacity(0.3) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4.w,
            backgroundImage: notification['user_image'] != null
                ? NetworkImage(notification['user_image'])
                : null,
            backgroundColor: notification['type'] == 'accepted'
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            child: notification['user_image'] == null
                ? Icon(
                    notification['type'] == 'accepted'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: notification['type'] == 'accepted'
                        ? Colors.green
                        : Colors.red,
                    size: 4.w,
                  )
                : null,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['message'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isNew ? FontWeight.w600 : FontWeight.normal,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  notification['time'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              width: 2.w,
              height: 2.w,
              decoration: BoxDecoration(
                color: Color(0xFF667EEA),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    final notifications = _notifications;

    if (notifications.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active,
                  color: Color(0xFF667EEA), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Bildirimler',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              if (notifications.any((n) => n['isNew'] == true))
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notifications.where((n) => n['isNew'] == true).length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          ...notifications
              .map((notification) => Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: notification['isNew'] == true
                          ? Color(0xFF667EEA).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notification['isNew'] == true
                            ? Color(0xFF667EEA).withOpacity(0.3)
                            : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 4.w,
                          backgroundImage: notification['user_image'] != null
                              ? NetworkImage(notification['user_image'])
                              : null,
                          backgroundColor: notification['type'] == 'accepted'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          child: notification['user_image'] == null
                              ? Icon(
                                  notification['type'] == 'accepted'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: notification['type'] == 'accepted'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 4.w,
                                )
                              : null,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['message']! as String,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: notification['isNew'] == true
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                notification['time']! as String,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (notification['isNew'] == true)
                          Container(
                            width: 2.w,
                            height: 2.w,
                            decoration: BoxDecoration(
                              color: Color(0xFF667EEA),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getSelectorNotifications() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      if (currentUser == null) return [];

      final client = await SupabaseService().client;

      // Tüm istekleri al (debug için)
      final allRequests = await client
          .from('selector_candidate_requests')
          .select('*')
          .eq('from_user_id', currentUser.id);

      print('DEBUG - Tüm istekler: $allRequests');

      // Son 3 günde seçiciye gelen yanıtları al - tarihe göre sıralı (en yeni önce)
      final threeDaysAgo =
          DateTime.now().subtract(Duration(days: 3)).toIso8601String();
      final responses = await client
          .from('selector_candidate_requests')
          .select('*')
          .eq('from_user_id', currentUser.id)
          .inFilter('status', ['accepted', 'rejected'])
          .gte('created_at', threeDaysAgo)
          .order('created_at', ascending: false)
          .limit(20);

      // Kullanıcı bilgilerini ayrı ayrı çek
      final userIds =
          responses.map((r) => r['to_user_id'] as String).toSet().toList();
      final users = <String, Map<String, dynamic>>{};

      if (userIds.isNotEmpty) {
        final userProfiles = await client
            .from('user_profiles')
            .select('id, full_name, image_url')
            .inFilter('id', userIds);

        for (final user in userProfiles) {
          users[user['id']] = user;
        }
      }

      print('DEBUG - Filtrelenmiş yanıtlar: $responses');

      List<Map<String, dynamic>> notifications = [];

      for (final response in responses) {
        final toUserId = response['to_user_id'] as String;
        final toUser = users[toUserId];

        if (toUser == null) continue; // Skip if user not found

        final relation = response['relation'] ?? 'Aday'; // Varsayılan değer
        final isAccepted = response['status'] == 'accepted';
        final createdAt = DateTime.parse(response['created_at']);

        notifications.add({
          'type': isAccepted ? 'accepted' : 'rejected',
          'message': isAccepted
              ? '${toUser['full_name']} isteğinizi kabul etti!'
              : '${toUser['full_name']} isteğinizi reddetti.',
          'time': _getTimeAgo(createdAt),
          'created_at': createdAt, // Store actual DateTime for sorting
          'isNew': DateTime.now().difference(createdAt).inHours < 24,
          'user_image': toUser['image_url'],
        });
      }

      // Bildirimleri tarihe göre sırala (en yeni önce)
      notifications.sort((a, b) {
        final dateA = a['created_at'] as DateTime;
        final dateB = b['created_at'] as DateTime;
        return dateB.compareTo(dateA); // En yeni önce
      });

      print('DEBUG - Son bildirimler: $notifications');

      return notifications;
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Widget _buildActivityStoryHeader() {
    final recentMatches = _proposals
        .where((p) =>
            p.status == AcceptanceStatus.accepted &&
            p.targetStatus == AcceptanceStatus.accepted &&
            DateTime.now().difference(p.createdAt).inDays <= 7)
        .take(3)
        .toList();

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
                'Son Eşleşmeler',
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
                border: Border.all(
                    color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Center(
                child: Text(
                  'Yakın zamanda eşleşme yok',
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
            'Eşleştiniz!',
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
        children: _filteredProposals
            .map((proposal) => Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: _buildActivityCard(proposal),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActivityCard(MatchProposal proposal) {
    final isMatched = proposal.status == AcceptanceStatus.accepted &&
        proposal.targetStatus == AcceptanceStatus.accepted;
    final isRejected = proposal.status == AcceptanceStatus.rejected ||
        proposal.targetStatus == AcceptanceStatus.rejected;

    return GestureDetector(
      onTap: () => isMatched
          ? _showMatchCelebration(proposal)
          : _showProposalDetails(proposal),
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
        child: isMatched
            ? _buildMatchCard(proposal)
            : _buildRegularActivityCard(proposal),
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
                      TextSpan(text: 'Başarıyla eşleştirdiniz: '),
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
                      child:
                          Icon(Icons.favorite, color: Colors.white, size: 8.w),
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
                // Text(
                //   "IT'S A",
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 16.sp,
                //     fontWeight: FontWeight.w600,
                //     letterSpacing: 2,
                //   ),
                // ),
                Text(
                  "EŞLEŞTİNİZ!",
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
                    Icon(Icons.share, size: 3.w, color: Color(0xFF667EEA)),
                    SizedBox(width: 1.w),
                    Text(
                      'Paylaş',
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
                      TextSpan(
                          text: isRejected
                              ? 'You proposed '
                              : 'Eşleştirme öneriniz: '),
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
                          ? Icon(Icons.person,
                              size: 3.w, color: Colors.grey[600])
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
                      isRejected ? 'Proposal declined' : 'Yanıt bekleniyor...',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color:
                            isRejected ? Color(0xFFE53E3E) : Color(0xFFED8936),
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
                    Icon(Icons.remove_red_eye,
                        size: 3.w, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      'Görüntüle',
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
      body: Column(
        children: [
          // Selector style header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: CustomIconWidget(
                    iconName: 'list',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 18,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Önerilerim',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${_filteredProposals.length} öneri',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadMyProposals,
                  icon: Icon(Icons.refresh, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                    foregroundColor: AppTheme.lightTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar under title
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: LinearProgressIndicator(
              value: _isLoading ? null : 1.0,
              backgroundColor:
                  AppTheme.lightTheme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.primaryColor),
              minHeight: 2,
            ),
          ),
          SizedBox(height: 1.h),

          // Body content
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: _buildModernBody(),
            ),
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
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'list',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                if (_notifications.any((n) => n['isNew'] == true))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${_notifications.where((n) => n['isNew'] == true).length}',
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
    if (proposal.status == AcceptanceStatus.accepted &&
        proposal.targetStatus == AcceptanceStatus.accepted) {
      return 'Eşleşti ✅';
    } else if (proposal.status == AcceptanceStatus.rejected ||
        proposal.targetStatus == AcceptanceStatus.rejected) {
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
                    child:
                        Icon(Icons.favorite, color: Colors.white, size: 12.w),
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
                "${proposal.candidateName} ve ${proposal.targetCandidateName} birbirlerini beğendi!",
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
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, color: Colors.white, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Paylaş',
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
