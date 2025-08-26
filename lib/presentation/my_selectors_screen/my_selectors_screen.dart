import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
import '../../services/user_service.dart';
import './widgets/empty_selectors_widget.dart';
import './widgets/invite_selector_widget.dart';
import './widgets/selector_card_widget.dart';

class MySelectorsScreen extends StatefulWidget {
  const MySelectorsScreen({super.key});

  @override
  State<MySelectorsScreen> createState() => _MySelectorsScreenState();
}

class _MySelectorsScreenState extends State<MySelectorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _allSelectors = [];
  List<Map<String, dynamic>> _filteredSelectors = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Yakınlık derecesi için
  String _selectedRelationshipDegree = '';
  bool _isEditingRelationship = false;
  final TextEditingController _relationshipController = TextEditingController();
  int _newMatchesCount = 0;
  int _pendingRequestsCount = 0; // Önerilerim badge için

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load data after build to prevent double rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMockData();
      _loadPendingRequestsCount();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Badge count'u yenile (diğer sayfalardan döndüğümüzde)
    _loadPendingRequestsCount();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  /// Yakınlık derecelerini yükle
  Future<void> _loadRelationshipDegrees(List<Map<String, dynamic>> selectors, UserProfile currentUser) async {
    for (var selector in selectors) {
      try {
        String selectorId, candidateId;
        if (currentUser.role == UserRole.selector) {
          selectorId = currentUser.id;
          candidateId = selector['id'] as String;
        } else {
          selectorId = selector['id'] as String;
          candidateId = currentUser.id;
        }
        
        final relationshipDegree = await _userService.getRelationshipDegree(
          selectorId: selectorId,
          candidateId: candidateId,
        );
        
        selector['relationshipDegree'] = relationshipDegree ?? '';
      } catch (e) {
        print('Error loading relationship degree for ${selector['id']}: $e');
        selector['relationshipDegree'] = '';
      }
    }
  }

  Future<void> _loadMockData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;

      if (currentUser == null) {
        setState(() {
          _allSelectors = [];
          _filteredSelectors = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> loadedSelectors = [];
      List<MatchProposal> proposals = []; // Proposals'ı burada tanımla

      if (currentUser.role == UserRole.selector) {
        // For selectors: Get candidates with their status (including paused ones)
        final candidatesWithStatus =
            await _userService.getSelectorCandidatesWithStatus(currentUser.id);

        // Load real statistics for each candidate
        final matchProposalService = MatchProposalService();
        final allProposalsForSelector = await matchProposalService.getSelectorProposals(currentUser.id);
        
        // Convert candidates with status to selector format for UI consistency
        loadedSelectors = candidatesWithStatus.map((candidateData) {
          final candidateId = candidateData['id'];
          final createdAt = candidateData['createdAt'] != null 
              ? DateTime.parse(candidateData['createdAt'])
              : DateTime.now();

          // Calculate real stats for this candidate
          final candidateProposals = allProposalsForSelector.where((proposal) => 
              proposal.candidateId == candidateId || proposal.targetCandidateId == candidateId
          ).toList();

          final totalSent = candidateProposals.length;
          final pending = candidateProposals.where((p) => 
              (p.candidateId == candidateId && p.status == AcceptanceStatus.pending) ||
              (p.targetCandidateId == candidateId && p.targetStatus == AcceptanceStatus.pending)
          ).length;
          final accepted = candidateProposals.where((p) => 
              (p.candidateId == candidateId && p.status == AcceptanceStatus.accepted) ||
              (p.targetCandidateId == candidateId && p.targetStatus == AcceptanceStatus.accepted)
          ).length;
          final rejected = candidateProposals.where((p) => 
              (p.candidateId == candidateId && p.status == AcceptanceStatus.rejected) ||
              (p.targetCandidateId == candidateId && p.targetStatus == AcceptanceStatus.rejected)
          ).length;
          
          final successRate = totalSent > 0 ? (accepted / totalSent * 100) : 0.0;

          return {
            "id": candidateId,
            "name": candidateData['name'],
            "email": candidateData['email'],
            "profileImage": candidateData['imageUrl']?.isNotEmpty == true
                ? candidateData['imageUrl']
                : _getDefaultImageForCandidate(candidateData['name']),
            "relationshipType": "Aday",
            "isActive": candidateData['isActive'],
            "totalSent": totalSent,
            "pending": pending,
            "accepted": accepted,
            "rejected": rejected,
            "successRate": successRate,
            "lastActivity": "Son görülme: Bilinmiyor",
            "joinedDate": _formatJoinDate(createdAt),
            "description": candidateData['bio'] ?? "Seçiminizde ki aday",
            "isPaused": candidateData['isPaused'],
            "age": candidateData['age'],
            "location": candidateData['location'],
            "profession": candidateData['profession'],
            "interests": candidateData['interests'],
            "relationshipDegree": "", // Will be loaded separately
          };
        }).toList();
      } else if (currentUser.role == UserRole.candidate) {
        // For candidates: Get selectors (similar to candidate home screen logic)
        final matchProposalService = MatchProposalService();
        proposals =
            await matchProposalService.getProposalsForCandidate(currentUser.id);

        // Yeni eşleşmeleri say
        final matchedProposals = proposals
            .where((p) =>
                p.status == AcceptanceStatus.accepted &&
                p.targetStatus == AcceptanceStatus.accepted)
            .toList();

        // Extract unique selector IDs from proposals
        final selectorIds = proposals.map((p) => p.selectorId).toSet().toList();
        final selectors = <UserProfile>[];

        for (final selectorId in selectorIds) {
          try {
            final selector = await _userService.getUserProfile(selectorId);
            if (selector != null) {
              selectors.add(selector);
            }
          } catch (e) {
            print('Error loading selector $selectorId: $e');
          }
        }

        // Get relation information for each selector
        final selectorRelations = <String, String>{};
        for (final selector in selectors) {
          try {
            final relationResponse = await _userService.getRelationshipDegree(
              selectorId: selector.id, 
              candidateId: currentUser.id,
            );
            if (relationResponse != null) {
              selectorRelations[selector.id] = relationResponse;
            }
          } catch (e) {
            print('Error getting relation for selector ${selector.id}: $e');
          }
        }

        // Convert UserProfile selectors to selector format for UI consistency
        loadedSelectors = selectors.map((selector) {
          // Calculate real stats for this selector (from candidate's perspective)
          final selectorProposals = proposals.where((proposal) => 
              proposal.selectorId == selector.id
          ).toList();

          final totalSent = selectorProposals.length;
          final pending = selectorProposals.where((p) => 
              (p.candidateId == currentUser.id && p.status == AcceptanceStatus.pending) ||
              (p.targetCandidateId == currentUser.id && p.targetStatus == AcceptanceStatus.pending)
          ).length;
          final accepted = selectorProposals.where((p) => 
              (p.candidateId == currentUser.id && p.status == AcceptanceStatus.accepted) ||
              (p.targetCandidateId == currentUser.id && p.targetStatus == AcceptanceStatus.accepted)
          ).length;
          final rejected = selectorProposals.where((p) => 
              (p.candidateId == currentUser.id && p.status == AcceptanceStatus.rejected) ||
              (p.targetCandidateId == currentUser.id && p.targetStatus == AcceptanceStatus.rejected)
          ).length;
          
          final successRate = totalSent > 0 ? (accepted / totalSent * 100) : 0.0;

          return {
            "id": selector.id,
            "name": selector.fullName,
            "profileImage": selector.imageUrl?.isNotEmpty == true
                ? selector.imageUrl
                : _getDefaultImageForCandidate(selector.fullName),
            "relationshipType": _getRelationshipType(selector),
            "isActive": selector.isActive,
            "totalSent": totalSent,
            "pending": pending,
            "accepted": accepted,
            "rejected": rejected,
            "successRate": successRate,
            "lastActivity": _getLastActivity(selector),
            "joinedDate": _formatJoinDate(selector.createdAt),
            "description": selector.bio ?? _getDefaultDescription(selector),
            "isPaused": !selector.isActive,
            "age": selector.age,
            "location": selector.location,
            "profession": selector.profession,
            "interests": selector.interests,
            "relationshipDegree": selectorRelations[selector.id] ?? "", // Actual relation from database
          };
        }).toList();
      }

      // Yakınlık derecelerini yükle
      await _loadRelationshipDegrees(loadedSelectors, currentUser);

      // No fallback data - show empty state for new users

      // Badge durumunu kontrol et
      int matchesCount = 0;
      if (currentUser.role == UserRole.candidate) {
        final prefs = await SharedPreferences.getInstance();
        final hasViewedMatches =
            prefs.getBool('hasViewedMatches_${currentUser.id}') ?? false;

        final currentMatchCount = proposals
            .where((p) =>
                p.status == AcceptanceStatus.accepted &&
                p.targetStatus == AcceptanceStatus.accepted)
            .length;

        if (!hasViewedMatches) {
          matchesCount = currentMatchCount;
        }
      }

      setState(() {
        _allSelectors = loadedSelectors;
        _filteredSelectors = List.from(_allSelectors);
        _newMatchesCount = matchesCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading candidates: $e');
      setState(() {
        // Fallback to empty or default data on error
        _allSelectors = [];
        _filteredSelectors = [];
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

  String _getDefaultImageForCandidate(String name) {
    // Return different default images based on name
    final images = [
      "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
      "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
      "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
      "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
    ];
    return images[name.hashCode % images.length];
  }

  String _getDefaultDescription(UserProfile candidate) {
    if (candidate.bio != null && candidate.bio!.isNotEmpty) {
      return candidate.bio!;
    }
    final age = candidate.age != null ? "${candidate.age} yaşında" : "";
    final location = candidate.location != null ? candidate.location! : "";
    final profession =
        candidate.profession != null ? candidate.profession! : "";

    List<String> parts = [];
    if (age.isNotEmpty) parts.add(age);
    if (location.isNotEmpty) parts.add("$location'de yaşıyor");
    if (profession.isNotEmpty) parts.add(profession);

    return parts.isNotEmpty ? parts.join(", ") : "Ailemizin sevgili adayı";
  }


  String _getRelationshipType(UserProfile candidate) {
    // You could add this to UserProfile model or determine from other fields
    return candidate.age != null && candidate.age! > 25 ? "Aile" : "Arkadaş";
  }

  String _getLastActivity(UserProfile candidate) {
    final now = DateTime.now();
    final diff = now.difference(candidate.createdAt);

    if (diff.inDays > 7) return "${diff.inDays} gün önce";
    if (diff.inDays > 0) return "${diff.inDays} gün önce";
    if (diff.inHours > 0) return "${diff.inHours} saat önce";
    return "Az önce";
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredSelectors = _allSelectors.where((selector) {
        final name = (selector['name'] as String).toLowerCase();
        final relationshipType =
            (selector['relationshipType'] as String).toLowerCase();
        return name.contains(_searchQuery) ||
            relationshipType.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Reload real data
    await _loadMockData();

    setState(() {
      _isLoading = false;
    });
  }

  void _showSelectorDetail(Map<String, dynamic> selector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.w),
                          child: CustomImageWidget(
                            imageUrl: selector['profileImage'] as String,
                            width: 16.w,
                            height: 16.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selector['name'] as String,
                                style: AppTheme.lightTheme.textTheme.titleLarge,
                              ),
                              Text(
                                selector['relationshipType'] as String,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                "Katılım: ${selector['joinedDate']}",
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: (selector['isActive'] as bool)
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.warningColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (selector['isActive'] as bool) ? "Aktif" : "Pasif",
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: (selector['isActive'] as bool)
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      selector['description'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 3.h),
                    
                    // Yakınlık Derecesi Bölümü
                    _buildRelationshipDegreeSection(selector),
                    SizedBox(height: 3.h),
                    
                    Text(
                      "İstatistikler",
                      style: AppTheme.lightTheme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Toplam Gönderilen",
                            "${selector['totalSent']}",
                            AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildStatCard(
                            "Bekleyen",
                            "${selector['pending']}",
                            AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Kabul Edilen",
                            "${selector['accepted']}",
                            AppTheme.successColor,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildStatCard(
                            "Başarı Oranı",
                            "%${selector['successRate'].toStringAsFixed(1)}",
                            AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _toggleSelectorStatus(selector),
                            child: Text(
                              (selector['isPaused'] as bool)
                                  ? "Aktifleştir"
                                  : "Duraklat",
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (selector['isPaused'] as bool) 
                                ? null // Deaktif yap
                                : () => _navigateToMatchmaking(selector),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (selector['isPaused'] as bool)
                                  ? Colors.grey // Gri renk
                                  : AppTheme.lightTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_getActionButtonText()),
                          ),
                        ),
                      ],
                    ),
                    
                    // Delete button for selectors viewing candidates
                    if (_isCurrentUserSelector()) ...[
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteCandidateDialog(selector),
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                          ),
                          label: Text(
                            'Adayı Sil',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleSelectorStatus(Map<String, dynamic> selector) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUserProfile;
    if (currentUser == null) return;

    final wasPaused = selector['isPaused'] as bool;
    
    // Role'e göre ID'leri doğru atayalım
    String selectorId, candidateId;
    if (currentUser.role == UserRole.selector) {
      // Eğer current user selector ise
      selectorId = currentUser.id; // selector ID
      candidateId = selector['id'] as String; // candidate ID
    } else {
      // Eğer current user candidate ise
      selectorId = selector['id'] as String; // selector ID  
      candidateId = currentUser.id; // candidate ID
    }

    try {
      // Veritabanında durumu güncelle
      if (wasPaused) {
        // Seçici kendi adayını aktifleştirmeye çalışıyorsa ve seçici offline ise
        if (currentUser.role == UserRole.selector && !currentUser.isActive) {
          Navigator.pop(context); // Modal'ı kapat
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adayları aktifleştirmek için önce profil sayfasından aktif hizmeti başlatın'),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Profil Sayfası',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/profile-screen');
                },
              ),
            ),
          );
          return;
        }
        
        // Aktifleştir
        await _userService.activateCandidateForSelector(
          selectorId: selectorId,
          candidateId: candidateId,
        );
      } else {
        // Duraklat
        await _userService.pauseCandidateForSelector(
          selectorId: selectorId,
          candidateId: candidateId,
        );
      }

      setState(() {
        selector['isPaused'] = !wasPaused;
        selector['isActive'] = wasPaused;
      });
      Navigator.pop(context); // Context menüyü kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (!wasPaused)
                ? "${selector['name']} duraklatıldı - Anasayfa güncellenecek"
                : "${selector['name']} aktifleştirildi - Anasayfa güncellenecek",
          ),
          backgroundColor: (!wasPaused) ? Colors.orange : Colors.green,
          action: SnackBarAction(
            label: "Geri Al",
            textColor: Colors.white,
            onPressed: () => _toggleSelectorStatus(selector),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Modal'ı kapat
      
      // RLS policy hatası - seçici offline olduğunda
      if (e.toString().contains('new row violates row-level security policy') || 
          e.toString().contains('selector_candidates') ||
          e.toString().contains('42501')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selector['name']} artık aktif hizmet vermiyor. Arama sonuçlarında görünmez durumda.'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Diğer hatalar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToMatchmaking(Map<String, dynamic> selector) {
    Navigator.pop(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;

    if (role == UserRole.selector) {
      // For selectors: Navigate to enhanced selector home screen with candidate pre-selected
      final candidateId = selector['id'].toString();

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.enhancedSelectorHomeScreen,
        arguments: {'selectedCandidateId': candidateId},
      );
    } else if (role == UserRole.candidate) {
      // For candidates: Navigate to candidate home screen with selector pre-selected
      final selectorId = selector['id'].toString();

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.candidateHomeScreen,
        arguments: {'selectedSelectorId': selectorId},
      );
    }
  }

  void _showInviteSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteSelectorWidget(
        onInviteSent: (String name, String relationship) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$name kişisine davet gönderildi"),
            ),
          );
        },
      ),
    );
  }

  void _removeSelector(Map<String, dynamic> selector) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Görücüyü Kaldır"),
        content: Text(
            "${selector['name']} kişisini görücü listenizden kaldırmak istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allSelectors.removeWhere((s) => s['id'] == selector['id']);
                _filteredSelectors
                    .removeWhere((s) => s['id'] == selector['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${selector['name']} kaldırıldı"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    onPressed: () {
                      setState(() {
                        _allSelectors.add(selector);
                        _onSearchChanged();
                      });
                    },
                  ),
                ),
              );
            },
            child: const Text("Kaldır"),
          ),
        ],
      ),
    );
  }

  /// Önerilerim badge için pending requests sayısını yükle
  Future<void> _loadPendingRequestsCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      if (currentUser != null && currentUser.role == UserRole.selector) {
        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('pending_requests_count_${currentUser.id}') ?? 0;
        final badgeManuallyCleared = prefs.getBool('badge_manually_cleared_${currentUser.id}') ?? false;
        
        // Eğer badge manuel temizlenmişse count'u 0 yap
        final finalCount = badgeManuallyCleared ? 0 : count;
        
        setState(() {
          _pendingRequestsCount = finalCount;
        });
      }
    } catch (e) {
      print('Error loading pending requests count in my_selectors_screen: $e');
    }
  }

  String _getScreenTitle() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    return role == UserRole.selector ? "Adaylarım" : "Seçicilerim";
  }

  String _getSearchHint() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    return role == UserRole.selector ? "Aday ara..." : "Seçici ara...";
  }

  String _getInviteButtonText() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    return role == UserRole.selector ? "Görücü Davet Et" : "Seçici Davet Et";
  }

  String _getActionButtonText() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    return role == UserRole.selector ? "Eşleştir" : "Seçtiği Adaylar";
  }

  Widget _buildBottomNavigationBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    final isSelector = role == UserRole.selector;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2, // My Selectors tab active
      onTap: (index) {
        switch (index) {
          case 0:
            if (role == UserRole.selector) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.enhancedSelectorHomeScreen,
                (route) => false,
              );
            } else if (role == UserRole.candidate) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.candidateHomeScreen,
                (route) => false,
              );
            }
            break;
          case 1:
            if (role == UserRole.selector) {
              Navigator.pushReplacementNamed(context, '/my-selections-screen');
            } else {
              // Badge'i kalıcı olarak sıfırla ve matches screen'e git
              _markMatchesAsViewed();
              Navigator.pushReplacementNamed(context, '/matches-screen');
            }
            break;
          case 2:
            // Current screen - do nothing
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'home',
            color:
                AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: isSelector ? 'list' : 'favorite',
                color: AppTheme
                    .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
                size: 24,
              ),
              if (!isSelector && _newMatchesCount > 0)
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
              if (isSelector && _pendingRequestsCount > 0)
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
                      '$_pendingRequestsCount',
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
          activeIcon: Stack(
            children: [
              CustomIconWidget(
                iconName: isSelector ? 'list' : 'favorite',
                color: AppTheme
                    .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
                size: 24,
              ),
              if (!isSelector && _newMatchesCount > 0)
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
              if (isSelector && _pendingRequestsCount > 0)
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
                      '$_pendingRequestsCount',
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
          label: isSelector ? 'Önerilerim' : 'Eşleşmeler',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color:
                AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'people',
            color:
                AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          label: isSelector ? 'Adaylarım' : 'Seçicilerim',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            color:
                AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          label: 'Profil',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showInviteSelector,
            icon: CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingScreen()
            : Column(
                children: [
                  // Search Bar
                  Container(
                    margin: EdgeInsets.all(4.w),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _getSearchHint(),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Selectors List
                  Expanded(
                    child: _filteredSelectors.isEmpty
                        ? EmptySelectorsWidget(
                            onAddSelector: _showInviteSelector,
                          )
                        : RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _filteredSelectors.length,
                              itemBuilder: (context, index) {
                                final selector = _filteredSelectors[index];
                                return SelectorCardWidget(
                                  selector: selector,
                                  onTap: () => _showSelectorDetail(selector),
                                  onRemove: () => _removeSelector(selector),
                                  onToggleStatus: () =>
                                      _toggleSelectorStatus(selector),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
      // FloatingActionButton kaldırıldı
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(height: 2.h),
          Text(
            'Seçiciler yükleniyor...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Yakınlık derecesi bölümü oluştur
  Widget _buildRelationshipDegreeSection(Map<String, dynamic> selector) {
    final relationshipDegree = selector['relationshipDegree'] as String? ?? '';
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor.withOpacity(0.05),
            AppTheme.lightTheme.primaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'favorite',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yakınlık Derecesi',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      relationshipDegree.isEmpty 
                          ? 'Henüz belirlenmedi' 
                          : relationshipDegree,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: relationshipDegree.isEmpty 
                            ? AppTheme.lightTheme.colorScheme.onSurfaceVariant 
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: relationshipDegree.isEmpty 
                            ? FontWeight.normal 
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showRelationshipDegreeDialog(selector),
                icon: Icon(
                  relationshipDegree.isEmpty ? Icons.add_circle : Icons.edit,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                tooltip: relationshipDegree.isEmpty ? 'Yakınlık Derecesi Ekle' : 'Düzenle',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Yakınlık derecesi düzenleme dialogu
  void _showRelationshipDegreeDialog(Map<String, dynamic> selector) {
    final currentDegree = selector['relationshipDegree'] as String? ?? '';
    _relationshipController.text = currentDegree;
    
    final relationshipOptions = [
      'Kardeş',
      'Kuzen',
      'Akraba',
      'Aile Dostu',
      'Komşu',
      'İş Arkadaşı',
      'Okul Arkadaşı',
      'Yakın Arkadaş',
      'Arkadaş',
      'Tanıdık',
    ];
    
    String selectedOption = currentDegree.isNotEmpty && relationshipOptions.contains(currentDegree) 
        ? currentDegree 
        : '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'favorite',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Yakınlık Derecesi',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selector['name']} ile yakınlık derecenizi seçin:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                SizedBox(height: 3.h),
                
                // Hızlı seçenekler
                Text(
                  'Hızlı Seçenekler:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: relationshipOptions.map((option) {
                    final isSelected = selectedOption == option;
                    return FilterChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedOption = selected ? option : '';
                          _relationshipController.text = selectedOption;
                        });
                      },
                      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                      selectedColor: AppTheme.lightTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.lightTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 3.h),
                
                // Manuel giriş
                Text(
                  'Veya kendiniz yazın:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _relationshipController,
                  decoration: InputDecoration(
                    hintText: 'Yakınlık derecesi girin...',
                    prefixIcon: Icon(
                      Icons.edit,
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.lightTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedOption = '';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final degree = _relationshipController.text.trim();
                if (degree.isNotEmpty) {
                  // Önce yakınlık derecesi dialog'unu kapat
                  Navigator.of(context).pop();
                  // Sonra kişi detay popup'ını da kapat
                  Navigator.of(context).pop();
                  
                  // Ana sayfa state'ini güncelle
                  _updateSelectorRelationshipDegree(selector, degree);
                  
                  // Başarı bildirimini göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Yakınlık derecesi güncellendi: $degree'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  // Arka planda veritabanını güncelle
                  try {
                    await _updateRelationshipDegreeInDatabase(selector, degree);
                  } catch (e) {
                    // Eğer veritabanı güncellemesi başarısız olursa kullanıcıya bildir
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Veritabanı güncelleme hatası: $e'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  // Boş değer girildiyse sadece dialog'u kapat
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lütfen yakınlık derecesi girin'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                }
              },
              icon: Icon(Icons.save),
              label: Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ana sayfa state'ini güncelle
  void _updateSelectorRelationshipDegree(Map<String, dynamic> selector, String degree) {
    setState(() {
      selector['relationshipDegree'] = degree;
      
      // Filtered list'i de güncelle
      final index = _filteredSelectors.indexWhere((s) => s['id'] == selector['id']);
      if (index != -1) {
        _filteredSelectors[index]['relationshipDegree'] = degree;
      }
      
      // All selectors list'i de güncelle
      final allIndex = _allSelectors.indexWhere((s) => s['id'] == selector['id']);
      if (allIndex != -1) {
        _allSelectors[allIndex]['relationshipDegree'] = degree;
      }
    });
  }

  /// Yakınlık derecesini veritabanında güncelle
  Future<void> _updateRelationshipDegreeInDatabase(Map<String, dynamic> selector, String degree) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser == null) return;
      
      String selectorId, candidateId;
      if (currentUser.role == UserRole.selector) {
        selectorId = currentUser.id;
        candidateId = selector['id'] as String;
      } else {
        selectorId = selector['id'] as String;
        candidateId = currentUser.id;
      }
      
      await _userService.updateRelationshipDegree(
        selectorId: selectorId,
        candidateId: candidateId,
        relationshipDegree: degree,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veritabanı güncellenirken hata: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  /// Check if current user is a selector
  bool _isCurrentUserSelector() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUserProfile?.role == UserRole.selector;
  }
  
  /// Show delete candidate confirmation dialog
  void _showDeleteCandidateDialog(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 28,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Adayı Sil',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${candidate['name']} kişisini adaylarınız listesinden kalıcı olarak silmek istediğinizden emin misiniz?',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz. Tüm eşleşme geçmişi korunur.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteCandidate(candidate);
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Delete candidate from selector's list
  Future<void> _deleteCandidate(Map<String, dynamic> candidate) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser == null || currentUser.role != UserRole.selector) {
        return;
      }
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 3.w),
              Text('Aday siliniyor...'),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Remove from database
      await _userService.removeCandidateFromSelector(
        selectorId: currentUser.id,
        candidateId: candidate['id'] as String,
      );
      
      // Remove from local lists
      setState(() {
        _allSelectors.removeWhere((s) => s['id'] == candidate['id']);
        _filteredSelectors.removeWhere((s) => s['id'] == candidate['id']);
      });
      
      // Close detail modal if it's open
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${candidate['name']} başarıyla silindi'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Geri Al',
            textColor: Colors.white,
            onPressed: () {
              // Add back to lists (UI only - would need restore logic for database)
              setState(() {
                _allSelectors.add(candidate);
                _onSearchChanged();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${candidate['name']} geri eklendi (geçici)'),
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                ),
              );
            },
          ),
        ),
      );
      
    } catch (e) {
      // Hide loading and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aday silinirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
