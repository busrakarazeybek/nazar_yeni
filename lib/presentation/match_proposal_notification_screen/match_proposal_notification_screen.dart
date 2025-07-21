import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_proposal_service.dart';
import './widgets/candidates_comparison_widget.dart';
import './widgets/decision_buttons_widget.dart';
import './widgets/proposal_header_widget.dart';

class MatchProposalNotificationScreen extends StatefulWidget {
  final String proposalId;

  const MatchProposalNotificationScreen({
    super.key,
    required this.proposalId,
  });

  @override
  State<MatchProposalNotificationScreen> createState() =>
      _MatchProposalNotificationScreenState();
}

class _MatchProposalNotificationScreenState
    extends State<MatchProposalNotificationScreen> {
  final MatchProposalService _proposalService = MatchProposalService();

  MatchProposal? _proposal;
  bool _isLoading = true;
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadProposal();
  }

  Future<void> _loadProposal() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Get all proposals and find the specific one
      final proposals =
          await _proposalService.getCandidateProposals(currentUser.id);
      final proposal = proposals.firstWhere((p) => p.id == widget.proposalId,
          orElse: () => throw Exception('Öneri bulunamadı'));

      setState(() {
        _proposal = proposal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptProposal() async {
    if (_proposal == null || _isProcessing) return;

    final currentUser = AuthProvider().currentUser;
    if (currentUser == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      await _proposalService.acceptProposal(
          proposalId: _proposal!.id, candidateId: currentUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Öneri kabul edildi! Karşı tarafın yanıtı bekleniyor.'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectProposal() async {
    if (_proposal == null || _isProcessing) return;

    final currentUser = AuthProvider().currentUser;
    if (currentUser == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      await _proposalService.rejectProposal(
          proposalId: _proposal!.id, candidateId: currentUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Öneri reddedildi.'),
            backgroundColor: Colors.orange));
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showThinkAboutItDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Düşünmek İster misiniz?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                content: Text(
                    'Bu eşleşme önerisini daha sonra değerlendirebilirsiniz. Bildirimler bölümünden tekrar ulaşabilirsiniz.',
                    style: GoogleFonts.inter()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('İptal',
                          style: GoogleFonts.inter(color: Colors.grey[600]))),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white),
                      child: Text('Tamam', style: GoogleFonts.inter())),
                ]));
  }

  void _viewFullProfiles() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.vertical()),
                child: Column(children: [
                  // Handle
                  Container(
                      margin: EdgeInsets.only(top: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey[300])),

                  // Header
                  Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text('Detaylı Profiller',
                          style: GoogleFonts.inter(
                              fontSize: 18.sp, fontWeight: FontWeight.w600))),

                  // Content
                  Expanded(
                      child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          children: [
                        if (_proposal != null) ...[
                          _buildDetailedProfile(
                              name: _proposal!.candidate1Name ?? 'Bilinmiyor',
                              imageUrl: _proposal!.candidate1ImageUrl,
                              bio:
                                  _proposal!.candidate1Bio ?? 'Bio bilgisi yok',
                              isCurrentUser: _proposal!.candidate1Id ==
                                  AuthProvider().currentUser?.id),
                          SizedBox(height: 24.h),
                          _buildDetailedProfile(
                              name: _proposal!.candidate2Name ?? 'Bilinmiyor',
                              imageUrl: _proposal!.candidate2ImageUrl,
                              bio:
                                  _proposal!.candidate2Bio ?? 'Bio bilgisi yok',
                              isCurrentUser: _proposal!.candidate2Id ==
                                  AuthProvider().currentUser?.id),
                        ],
                      ])),
                ]))));
  }

  Widget _buildDetailedProfile({
    required String name,
    String? imageUrl,
    required String bio,
    required bool isCurrentUser,
  }) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(),
        child: Padding(
            padding: EdgeInsets.all(16.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? Icon(Icons.person, size: 30.sp)
                        : null),
                SizedBox(width: 12.w),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(name,
                            style: GoogleFonts.inter(
                                fontSize: 18.sp, fontWeight: FontWeight.w600)),
                        if (isCurrentUser) ...[
                          SizedBox(width: 8.w),
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration:
                                  BoxDecoration(color: Colors.purple[100]),
                              child: Text('Siz',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w500))),
                        ],
                      ]),
                    ])),
              ]),
              SizedBox(height: 12.h),
              Text('Hakkında',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              SizedBox(height: 4.h),
              Text(bio,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey[600], height: 1.4)),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.error_outline,
                            size: 64.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text('Bir hata oluştu',
                            style: GoogleFonts.inter(
                                fontSize: 18.sp, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        Text(_error!,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: Colors.grey[600]),
                            textAlign: TextAlign.center),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                            onPressed: _loadProposal,
                            child: const Text('Tekrar Dene')),
                      ]))
                : _proposal == null
                    ? const Center(child: Text('Öneri bulunamadı'))
                    : Column(children: [
                        // Header with close button
                        ProposalHeaderWidget(
                            proposal: _proposal!,
                            onClose: () => Navigator.of(context).pop()),

                        // Scrollable content
                        Expanded(
                            child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 16.h),

                                      // Candidates comparison
                                      CandidatesComparisonWidget(
                                          proposal: _proposal!),

                                      SizedBox(height: 24.h),

                                      SizedBox(height: 24.h),

                                      // View full profiles button
                                      Center(
                                          child: TextButton.icon(
                                              onPressed: _viewFullProfiles,
                                              icon: const Icon(
                                                  Icons.person_outline),
                                              label: const Text(
                                                  'Detaylı Profilleri Görüntüle'),
                                              style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.purple,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 8.h)))),

                                      SizedBox(height: 32.h),
                                    ]))),

                        // Decision buttons (fixed at bottom)
                        DecisionButtonsWidget(
                            proposal: _proposal!,
                            isProcessing: _isProcessing,
                            onAccept: _acceptProposal,
                            onReject: _rejectProposal,
                            onThinkAboutIt: _showThinkAboutItDialog),
                      ]));
  }
}
