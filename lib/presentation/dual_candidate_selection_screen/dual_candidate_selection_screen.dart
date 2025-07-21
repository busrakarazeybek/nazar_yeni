import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/match_proposal_service.dart';
import './widgets/candidate_stack_widget.dart';
import './widgets/dual_selection_preview_widget.dart';
import './widgets/recipient_selection_widget.dart';

class DualCandidateSelectionScreen extends StatefulWidget {
  const DualCandidateSelectionScreen({super.key});

  @override
  State<DualCandidateSelectionScreen> createState() =>
      _DualCandidateSelectionScreenState();
}

class _DualCandidateSelectionScreenState
    extends State<DualCandidateSelectionScreen> {
  final UserService _userService = UserService();
  final MatchProposalService _proposalService = MatchProposalService();

  UserProfile? _selectedRecipient;
  UserProfile? _selectedCandidate;
  List<UserProfile> _assignedCandidates = [];
  List<UserProfile> _availableCandidates = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Load selector's assigned candidates
      final assignedCandidates =
          await _userService.getSelectorCandidates(currentUser.id);

      // Load all available candidates for selection
      final allCandidates = await _userService.getCandidates(limit: 50);

      setState(() {
        _assignedCandidates = assignedCandidates;
        _availableCandidates = allCandidates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onRecipientSelected(UserProfile? recipient) {
    setState(() {
      _selectedRecipient = recipient;
      // Clear candidate selection if recipient changes
      if (_selectedCandidate?.id == recipient?.id) {
        _selectedCandidate = null;
      }
    });
  }

  void _onCandidateSelected(UserProfile candidate) {
    setState(() {
      // Prevent selecting the same person as recipient
      if (candidate.id != _selectedRecipient?.id) {
        _selectedCandidate = candidate;
      }
    });
  }

  bool get _canCreateMatch {
    return _selectedRecipient != null &&
        _selectedCandidate != null &&
        _selectedRecipient!.id != _selectedCandidate!.id;
  }

  Future<void> _createMatch() async {
    if (!_canCreateMatch) return;

    try {
      final currentUser = AuthProvider().currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Show loading
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));

      await _proposalService.createMatchProposal(
          selectorId: currentUser.id,
          candidateId: _selectedRecipient!.id,
          targetCandidateId: _selectedCandidate!.id,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Eşleşme önerisi başarıyla oluşturuldu!'),
          backgroundColor: Colors.green));

      Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
            title: Text('Çift Eşleştirme',
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87)),
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
                            onPressed: _loadData,
                            child: const Text('Tekrar Dene')),
                      ]))
                : Column(children: [
                    // Recipient Selection Section
                    Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16.w),
                        child: RecipientSelectionWidget(
                            assignedCandidates: _assignedCandidates,
                            selectedRecipient: _selectedRecipient,
                            onRecipientSelected: _onRecipientSelected)),

                    // Divider
                    Container(height: 1.h, color: Colors.grey[200]),

                    // Main Content Area
                    Expanded(
                        child: _selectedRecipient == null
                            ? Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Icon(Icons.person_search,
                                        size: 64.sp, color: Colors.grey[400]),
                                    SizedBox(height: 16.h),
                                    Text(
                                        'Kimin için eşleştirme yapacağınızı seçin',
                                        style: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            color: Colors.grey[600]),
                                        textAlign: TextAlign.center),
                                  ]))
                            : Row(children: [
                                // Selected Recipient Profile (Left)
                                Expanded(
                                    flex: 1,
                                    child: Container(
                                        color: Colors.white,
                                        child: DualSelectionPreviewWidget(
                                            title: 'Kimin İçin',
                                            selectedUser: _selectedRecipient!,
                                            isRecipient: true))),

                                // Vertical Divider
                                Container(width: 1.w, color: Colors.grey[200]),

                                // Candidate Stack (Right)
                                Expanded(
                                    flex: 1,
                                    child: CandidateStackWidget(
                                        candidates: _availableCandidates
                                            .where((c) =>
                                                c.id != _selectedRecipient?.id)
                                            .toList(),
                                        selectedCandidate: _selectedCandidate,
                                        onCandidateSelected:
                                            _onCandidateSelected)),
                              ])),

                    // Message Input Section
                    if (_selectedRecipient != null &&
                        _selectedCandidate != null)
                      Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Özel Mesaj (İsteğe Bağlı)',
                                    style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700])),
                                SizedBox(height: 8.h),
                                TextField(
                                    controller: _messageController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                        hintText:
                                            'Bu eşleştirme hakkında notunuzu yazın...',
                                        border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!)),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.purple)),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 8.h)),
                                    style: GoogleFonts.inter(fontSize: 14.sp)),
                              ])),

                    // Create Match Button
                    Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16.w),
                        child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed:
                                    _canCreateMatch ? _createMatch : null,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _canCreateMatch
                                        ? Colors.purple
                                        : Colors.grey[300],
                                    foregroundColor: Colors.white,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(),
                                    elevation: 0),
                                child: Text(
                                    _canCreateMatch
                                        ? 'Eşleştirmeyi Öner'
                                        : 'İki Kişi Seçin',
                                    style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600))))),
                  ]));
  }
}
