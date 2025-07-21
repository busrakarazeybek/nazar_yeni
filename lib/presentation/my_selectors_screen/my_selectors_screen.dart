import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  List<Map<String, dynamic>> _allSelectors = [];
  List<Map<String, dynamic>> _filteredSelectors = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    _allSelectors = [
      {
        "id": 1,
        "name": "Ayşe Demir",
        "profileImage":
            "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
        "relationshipType": "Aile",
        "isActive": true,
        "totalSent": 12,
        "pending": 3,
        "accepted": 7,
        "rejected": 2,
        "successRate": 58.3,
        "lastActivity": "2 saat önce",
        "joinedDate": "15 Ocak 2024",
        "description": "Teyzem, ailemizin en deneyimli görücüsü",
        "isPaused": false,
      },
      {
        "id": 2,
        "name": "Mehmet Özkan",
        "profileImage":
            "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
        "relationshipType": "Arkadaş",
        "isActive": true,
        "totalSent": 8,
        "pending": 2,
        "accepted": 4,
        "rejected": 2,
        "successRate": 50.0,
        "lastActivity": "1 gün önce",
        "joinedDate": "22 Şubat 2024",
        "description": "Yakın arkadaşım, sosyal çevresi geniş",
        "isPaused": false,
      },
      {
        "id": 3,
        "name": "Fatma Yılmaz",
        "profileImage":
            "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
        "relationshipType": "Aile",
        "isActive": false,
        "totalSent": 15,
        "pending": 1,
        "accepted": 9,
        "rejected": 5,
        "successRate": 60.0,
        "lastActivity": "1 hafta önce",
        "joinedDate": "8 Mart 2024",
        "description": "Annem, geleneksel değerlere önem verir",
        "isPaused": true,
      },
      {
        "id": 4,
        "name": "Ali Kaya",
        "profileImage":
            "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
        "relationshipType": "Arkadaş",
        "isActive": true,
        "totalSent": 6,
        "pending": 4,
        "accepted": 2,
        "rejected": 0,
        "successRate": 33.3,
        "lastActivity": "3 saat önce",
        "joinedDate": "5 Nisan 2024",
        "description": "İş arkadaşım, profesyonel çevresi var",
        "isPaused": false,
      },
    ];
    _filteredSelectors = List.from(_allSelectors);
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

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate updated data
    for (var selector in _allSelectors) {
      selector['lastActivity'] = "Az önce güncellendi";
    }

    setState(() {
      _isLoading = false;
      _filteredSelectors = List.from(_allSelectors);
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
                            onPressed: () => _sendAppreciationMessage(selector),
                            child: const Text("Teşekkür Mesajı"),
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

  void _sendAppreciationMessage(Map<String, dynamic> selector) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("${selector['name']} kişisine teşekkür mesajı gönderildi"),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Görücülerim"),
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
                  hintText: "Görücü ara...",
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
              label: const Text("Görücü Davet Et"),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // My Selectors tab active
        onTap: (index) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final role = authProvider.currentUserProfile?.role;
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
              Navigator.pushReplacementNamed(context, '/matches-screen');
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
              iconName: 'favorite',
              color: AppTheme
                  .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'favorite',
              color: AppTheme
                  .lightTheme.bottomNavigationBarTheme.selectedItemColor!,
              size: 24,
            ),
            label: 'Eşleşmeler',
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
            label: 'Görücülerim',
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
      ),
    );
  }
}
