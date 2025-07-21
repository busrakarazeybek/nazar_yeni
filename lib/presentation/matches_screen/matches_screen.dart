import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './widgets/empty_matches_widget.dart';
import './widgets/match_card_widget.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomIndex = 1; // Matches tab is active
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  final String _currentUserRole = 'Selector'; // Mock current user role

  // Mock data for matches
  final List<Map<String, dynamic>> _sentMatches = [
    {
      "id": 1,
      "candidateName": "Ayşe Demir",
      "candidateAge": 26,
      "candidateImage":
          "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg",
      "status": "pending",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
      "bio": "Öğretmen, kitap okumayı ve doğa yürüyüşlerini seviyor.",
      "interests": ["Kitap", "Doğa", "Müzik"],
    },
    {
      "id": 2,
      "candidateName": "Fatma Özkan",
      "candidateAge": 28,
      "candidateImage":
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg",
      "status": "accepted",
      "timestamp": DateTime.now().subtract(Duration(days: 1)),
      "bio": "Mimar, sanat ve tasarımla ilgileniyor.",
      "interests": ["Sanat", "Tasarım", "Seyahat"],
    },
    {
      "id": 3,
      "candidateName": "Zeynep Kaya",
      "candidateAge": 24,
      "candidateImage":
          "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg",
      "status": "rejected",
      "timestamp": DateTime.now().subtract(Duration(days: 3)),
      "bio": "Doktor, spor yapmayı ve seyahat etmeyi seviyor.",
      "interests": ["Spor", "Seyahat", "Tıp"],
    },
  ];

  final List<Map<String, dynamic>> _receivedMatches = [
    {
      "id": 4,
      "candidateName": "Mehmet Ali Şen",
      "candidateAge": 30,
      "candidateImage":
          "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
      "status": "pending",
      "timestamp": DateTime.now().subtract(Duration(minutes: 30)),
      "selectorName": "Emine Teyze",
      "selectorRelation": "Aile Dostu",
      "bio": "Mühendis, teknoloji ve spor meraklısı.",
      "interests": ["Teknoloji", "Spor", "Sinema"],
    },
    {
      "id": 5,
      "candidateName": "Ahmet Yılmaz",
      "candidateAge": 32,
      "candidateImage":
          "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg",
      "status": "accepted",
      "timestamp": DateTime.now().subtract(Duration(hours: 5)),
      "selectorName": "Fatma Hanım",
      "selectorRelation": "Komşu",
      "bio": "İş insanı, müzik ve sanat seviyor.",
      "interests": ["Müzik", "Sanat", "İş"],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _currentUserRole == 'Selector' ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    List<Map<String, dynamic>> matches = [];

    if (_currentUserRole == 'Selector') {
      matches = _tabController.index == 0 ? _sentMatches : _receivedMatches;
    } else {
      matches = _receivedMatches;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      matches = matches.where((match) {
        final name = (match['candidateName'] as String).toLowerCase();
        final selector = (match['selectorName'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || selector.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      matches = matches.where((match) {
        return (match['status'] as String).toLowerCase() ==
            _selectedFilter.toLowerCase();
      }).toList();
    }

    return matches;
  }

  Future<void> _refreshMatches() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }

  void _onMatchAction(int matchId, String action) {
    setState(() {
      // Update match status based on action
      final allMatches = [..._sentMatches, ..._receivedMatches];
      final matchIndex =
          allMatches.indexWhere((match) => match['id'] == matchId);

      if (matchIndex != -1) {
        switch (action) {
          case 'accept':
            allMatches[matchIndex]['status'] = 'accepted';
            break;
          case 'reject':
          case 'decline':
            allMatches[matchIndex]['status'] = 'rejected';
            break;
          case 'withdraw':
            // Remove from sent matches
            _sentMatches.removeWhere((match) => match['id'] == matchId);
            break;
        }
      }
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getActionMessage(action)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getActionMessage(String action) {
    switch (action) {
      case 'accept':
        return 'Eşleşme kabul edildi';
      case 'reject':
      case 'decline':
        return 'Eşleşme reddedildi';
      case 'withdraw':
        return 'Eşleşme geri çekildi';
      default:
        return 'İşlem tamamlandı';
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/enhanced-selector-home-screen');
        break;
      case 1:
        // Already on matches screen
        break;
      case 2:
        Navigator.pushNamed(context, '/my-selectors-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile-screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Eşleşmeler',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showFilterDialog();
            },
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
          ),
        ],
        bottom: _currentUserRole == 'Selector'
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Gönderilen'),
                  Tab(text: 'Alınan'),
                ],
                labelColor: AppTheme.lightTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryLight,
                indicatorColor: AppTheme.lightTheme.primaryColor,
              )
            : PreferredSize(
                preferredSize: Size.zero,
                child: Container(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'İsim veya seçici ara...',
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.textSecondaryLight,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.lightTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.lightTheme.colorScheme.surface,
                ),
              ),
            ),

            // Content
            Expanded(
              child: _currentUserRole == 'Selector'
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMatchesList(),
                        _buildMatchesList(),
                      ],
                    )
                  : _buildMatchesList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryLight,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentBottomIndex == 0
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.textSecondaryLight,
              size: 24,
            ),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'favorite',
              color: _currentBottomIndex == 1
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.textSecondaryLight,
              size: 24,
            ),
            label: 'Eşleşmeler',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'people',
              color: _currentBottomIndex == 2
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.textSecondaryLight,
              size: 24,
            ),
            label: 'Seçicilerim',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentBottomIndex == 3
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.textSecondaryLight,
              size: 24,
            ),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _currentUserRole == 'Selector'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/enhanced-selector-home-screen');
              },
              backgroundColor: AppTheme.accentColor,
              child: CustomIconWidget(
                iconName: 'add',
                color: AppTheme.textPrimaryLight,
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildMatchesList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.primaryColor,
        ),
      );
    }

    final matches = _filteredMatches;

    if (matches.isEmpty) {
      return EmptyMatchesWidget(
        userRole: _currentUserRole,
        isFiltered: _searchQuery.isNotEmpty || _selectedFilter != 'All',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMatches,
      color: AppTheme.lightTheme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return MatchCardWidget(
            match: match,
            userRole: _currentUserRole,
            onAction: _onMatchAction,
            onTap: () {
              if (match['status'] == 'accepted') {
                Navigator.pushNamed(context, '/chat-screen');
              } else {
                Navigator.pushNamed(
                    context, '/candidate-profile-detail-screen');
              }
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Filtrele',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All', 'Tümü'),
              _buildFilterOption('Pending', 'Bekleyen'),
              _buildFilterOption('Accepted', 'Kabul Edilen'),
              _buildFilterOption('Rejected', 'Reddedilen'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (String? newValue) {
        setState(() {
          _selectedFilter = newValue ?? 'All';
        });
        Navigator.of(context).pop();
      },
      activeColor: AppTheme.lightTheme.primaryColor,
    );
  }
}
