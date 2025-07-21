import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
import './widgets/filter_options_widget.dart';
import './widgets/proposal_card_widget.dart';
import './widgets/success_metrics_widget.dart';

class MySelectionsScreen extends StatefulWidget {
  const MySelectionsScreen({super.key});

  @override
  State<MySelectionsScreen> createState() => _MySelectionsScreenState();
}

class _MySelectionsScreenState extends State<MySelectionsScreen> {
  bool _isLoading = true;
  List<MatchProposal> _proposals = [];
  String? _errorMessage;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyProposals();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    // Apply status filter
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((p) => p.isPending).toList();
        break;
      case 'accepted':
        filtered = filtered.where((p) => p.isCompleted).toList();
        break;
      case 'rejected':
        filtered = filtered.where((p) => p.isRejected).toList();
        break;
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((p) =>
              (p.candidate1Name?.toLowerCase().contains(searchTerm) ?? false) ||
              (p.candidate2Name?.toLowerCase().contains(searchTerm) ?? false))
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Önerilerim',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadMyProposals,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.primaryColor,
              size: 24.w,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyProposals,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_proposals.isEmpty) {
      return _buildEmptyScreen();
    }

    return Column(
      children: [
        // Success metrics section
        SuccessMetricsWidget(proposals: _proposals),

        // Filter and search section
        FilterOptionsWidget(
          selectedFilter: _selectedFilter,
          onFilterChanged: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          searchController: _searchController,
          onSearchChanged: (value) {
            setState(() {});
          },
        ),

        // Proposals list
        Expanded(
          child: _filteredProposals.isEmpty
              ? _buildNoFilteredResultsScreen()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  itemCount: _filteredProposals.length,
                  itemBuilder: (context, index) {
                    final proposal = _filteredProposals[index];
                    return ProposalCardWidget(
                      proposal: proposal,
                      onTap: () => _showProposalDetails(proposal),
                      onWithdraw: proposal.isPending
                          ? () => _withdrawProposal(proposal)
                          : null,
                    );
                  },
                ),
        ),
      ],
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
              onPressed: _loadMyProposals,
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

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'favorite_border',
              color: AppTheme.lightTheme.colorScheme.outline,
              size: 64.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Henüz Öneri Yok',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz hiç eşleşme öneriniz bulunmuyor.\nAdaylar arasında gezinerek öneriler oluşturun.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                    context, AppRoutes.enhancedSelectorHomeScreen);
              },
              icon: CustomIconWidget(
                iconName: 'search',
                color: Colors.white,
                size: 20.w,
              ),
              label: Text('Adayları Keşfet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilteredResultsScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.outline,
              size: 48.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Sonuç Bulunamadı',
              style: AppTheme.lightTheme.textTheme.headlineMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Arama kriterlerinize uygun öneri bulunamadı.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showProposalDetails(MatchProposal proposal) {
    Navigator.pushNamed(
      context,
      AppRoutes.mutualAcceptanceStatusScreen,
      arguments: {'proposalId': proposal.id},
    );
  }

  Future<void> _withdrawProposal(MatchProposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Öneriyi Geri Çek'),
        content: Text(
            '${proposal.candidate1Name} ve ${proposal.candidate2Name} arasındaki eşleşme önerinizi geri çekmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text('Geri Çek'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final matchProposalService = MatchProposalService();
        await matchProposalService.withdrawProposal(proposal.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri başarıyla geri çekildi'),
            backgroundColor: Colors.green,
          ),
        );

        _loadMyProposals();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri geri çekilirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
