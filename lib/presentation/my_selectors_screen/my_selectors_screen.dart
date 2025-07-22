import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/match_proposal_service.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMockData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
      
      if (currentUser.role == UserRole.selector) {
        // For selectors: Get candidates (existing logic)
        final candidates = await _userService.getSelectorCandidates(currentUser.id);
        
        // Convert UserProfile candidates to selector format for UI consistency
        loadedSelectors = candidates.map((candidate) {
        // Generate mock stats based on candidate ID for consistency
        final stats = _generateStatsForCandidate(candidate.id);
        
          return {
            "id": candidate.id, // Use real ID instead of hashCode
            "name": candidate.fullName,
            "profileImage": candidate.imageUrl?.isNotEmpty == true ? candidate.imageUrl : _getDefaultImageForCandidate(candidate.fullName),
            "relationshipType": _getRelationshipType(candidate),
            "isActive": candidate.isActive,
            "totalSent": stats['totalSent'],
            "pending": stats['pending'],
            "accepted": stats['accepted'],
            "rejected": stats['rejected'],
            "successRate": stats['successRate'],
            "lastActivity": _getLastActivity(candidate),
            "joinedDate": _formatJoinDate(candidate.createdAt),
            "description": candidate.bio ?? _getDefaultDescription(candidate),
            "isPaused": !candidate.isActive,
            "age": candidate.age,
            "location": candidate.location,
            "profession": candidate.profession,
            "interests": candidate.interests,
          };
        }).toList();
        
      } else if (currentUser.role == UserRole.candidate) {
        // For candidates: Get selectors (similar to candidate home screen logic)
        final matchProposalService = MatchProposalService();
        final proposals = await matchProposalService.getProposalsForCandidate(currentUser.id);
        
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
        
        // Convert UserProfile selectors to selector format for UI consistency
        loadedSelectors = selectors.map((selector) {
          // Generate mock stats based on selector ID for consistency
          final stats = _generateStatsForCandidate(selector.id);
          
          return {
            "id": selector.id,
            "name": selector.fullName,
            "profileImage": selector.imageUrl?.isNotEmpty == true ? selector.imageUrl : _getDefaultImageForCandidate(selector.fullName),
            "relationshipType": _getRelationshipType(selector),
            "isActive": selector.isActive,
            "totalSent": stats['totalSent'],
            "pending": stats['pending'],
            "accepted": stats['accepted'],
            "rejected": stats['rejected'],
            "successRate": stats['successRate'],
            "lastActivity": _getLastActivity(selector),
            "joinedDate": _formatJoinDate(selector.createdAt),
            "description": selector.bio ?? _getDefaultDescription(selector),
            "isPaused": !selector.isActive,
            "age": selector.age,
            "location": selector.location,
            "profession": selector.profession,
            "interests": selector.interests,
          };
        }).toList();
      }
      
      // If no real candidates, add fallback data
      if (loadedSelectors.isEmpty) {
        loadedSelectors = [
          {
            "id": 1,
            "name": "Aday Bir",
            "profileImage": "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
            "relationshipType": "Aile",
            "isActive": true,
            "totalSent": 12,
            "pending": 3,
            "accepted": 7,
            "rejected": 2,
            "successRate": 58.3,
            "lastActivity": "2 saat önce",
            "joinedDate": "15 Ocak 2024",
            "description": "Ailemizin sevgili adayı",
            "isPaused": false,
            "age": 25,
            "location": "İstanbul",
            "profession": "Mühendis",
            "interests": ["Kitap", "Spor"],
          },
        ];
      }
      
      setState(() {
        _allSelectors = loadedSelectors;
        _filteredSelectors = List.from(_allSelectors);
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
    final profession = candidate.profession != null ? candidate.profession! : "";
    
    List<String> parts = [];
    if (age.isNotEmpty) parts.add(age);
    if (location.isNotEmpty) parts.add("$location'de yaşıyor");
    if (profession.isNotEmpty) parts.add(profession);
    
    return parts.isNotEmpty ? parts.join(", ") : "Ailemizin sevgili adayı";
  }

  Map<String, dynamic> _generateStatsForCandidate(String candidateId) {
    // Generate consistent mock stats based on candidate ID
    final hash = candidateId.hashCode.abs();
    return {
      'totalSent': 8 + (hash % 10),
      'pending': 1 + (hash % 4),
      'accepted': 3 + (hash % 8),
      'rejected': hash % 3,
      'successRate': 40.0 + ((hash % 30).toDouble()),
    };
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
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
                            onPressed: () => _navigateToMatchmaking(selector),
                            child: Text(_getActionButtonText()),
                          ),
                        ),
                      ],
                    ),
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

  void _toggleSelectorStatus(Map<String, dynamic> selector) {
    setState(() {
      selector['isPaused'] = !(selector['isPaused'] as bool);
      selector['isActive'] = !(selector['isPaused'] as bool);
    });
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (selector['isPaused'] as bool)
              ? "${selector['name']} duraklatıldı"
              : "${selector['name']} aktifleştirildi",
        ),
        action: SnackBarAction(
          label: "Geri Al",
          onPressed: () => _toggleSelectorStatus(selector),
        ),
      ),
    );
  }

  void _navigateToMatchmaking(Map<String, dynamic> selector) {
    Navigator.pop(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUserProfile?.role;
    
    if (role == UserRole.selector) {
      // For selectors: Navigate to enhanced selector home screen with candidate pre-selected
      final candidateId = selector['id'].toString();
      print('DEBUG: Selector navigating with candidate ID: $candidateId');
      print('DEBUG: Selector data: $selector');
      
      Navigator.pushNamed(
        context, 
        AppRoutes.enhancedSelectorHomeScreen,
        arguments: {'selectedCandidateId': candidateId},
      );
    } else if (role == UserRole.candidate) {
      // For candidates: Navigate to candidate home screen with selector pre-selected
      final selectorId = selector['id'].toString();
      print('DEBUG: Candidate navigating with selector ID: $selectorId');
      print('DEBUG: Selector data: $selector');
      
      Navigator.pushNamed(
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
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: isSelector ? 'list' : 'favorite',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: isSelector ? 'list' : 'favorite',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          label: isSelector ? 'Önerilerim' : 'Eşleşmeler',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'people',
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
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
            color: AppTheme
                .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
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
        child: Column(
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
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
      floatingActionButton: _filteredSelectors.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showInviteSelector,
              icon: CustomIconWidget(
                iconName: 'person_add',
                color: AppTheme
                    .lightTheme.floatingActionButtonTheme.foregroundColor!,
                size: 20,
              ),
              label: Text(_getInviteButtonText()),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
