import '../core/app_export.dart';
import '../models/match_proposal.dart';

class MatchProposalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  /// Create a new match proposal
  Future<MatchProposal> createProposal({
    required String selectorId,
    required String candidateId,
    required String targetCandidateId,
    String? message,
    String selectorStatus = 'approved',
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client.from('matches').insert({
        'selector_id': selectorId,
        'candidate_id': candidateId,
        'target_candidate_id': targetCandidateId,
        'selector_message': message,
        'selector_status': selectorStatus,
        'status': 'pending',
        'target_status': 'pending',
      }).select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''').single();

      return MatchProposal.fromJson(response);
    } catch (error) {
      throw Exception('Eşleşme önerisi oluşturulamadı: $error');
    }
  }

  /// Alias for createProposal method for backward compatibility
  Future<MatchProposal> createMatchProposal({
    required String selectorId,
    required String candidateId,
    required String targetCandidateId,
    String? message,
    String selectorStatus = 'approved',
  }) async {
    return createProposal(
      selectorId: selectorId,
      candidateId: candidateId,
      targetCandidateId: targetCandidateId,
      message: message,
      selectorStatus: selectorStatus,
    );
  }

  /// Get proposals for a candidate
  Future<List<MatchProposal>> getCandidateProposals(String candidateId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''')
          .or('candidate_id.eq.$candidateId,target_candidate_id.eq.$candidateId')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => MatchProposal.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Eşleşme önerileri yüklenemedi: $error');
    }
  }

  /// Get pending proposals for a candidate
  Future<List<MatchProposal>> getPendingProposals(String candidateId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''')
          .or('candidate_id.eq.$candidateId,target_candidate_id.eq.$candidateId')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => MatchProposal.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Bekleyen öneriler yüklenemedi: $error');
    }
  }

  /// Get proposals created by a selector
  Future<List<MatchProposal>> getSelectorProposals(String selectorId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''')
          .eq('selector_id', selectorId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => MatchProposal.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Seçici önerileri yüklenemedi: $error');
    }
  }

  /// Update candidate response to a proposal
  Future<MatchProposal> updateCandidateResponse({
    required String proposalId,
    required String candidateId,
    required AcceptanceStatus status,
  }) async {
    try {
      final client = await _supabaseService.client;

      // First get the current proposal to determine which candidate is responding
      final currentProposal = await client
          .from('matches')
          .select('candidate_id, target_candidate_id, status, target_status')
          .eq('id', proposalId)
          .single();

      Map<String, dynamic> updateData = {};
      String newStatus;
      String newTargetStatus;

      if (currentProposal['candidate_id'] == candidateId) {
        // Candidate is responding
        newStatus = status.toString().split('.').last;
        newTargetStatus = currentProposal['target_status'] ?? 'pending';
        updateData['status'] = newStatus;
      } else if (currentProposal['target_candidate_id'] == candidateId) {
        // Target candidate is responding
        newStatus = currentProposal['status'] ?? 'pending';
        newTargetStatus = status.toString().split('.').last;
        updateData['target_status'] = newTargetStatus;
      } else {
        throw Exception('Bu öneriye yanıt verme yetkiniz yok');
      }

      // Check for match after update - both candidates must accept
      if (newStatus == 'accepted' && newTargetStatus == 'accepted') {
        updateData['overall_status'] = 'matched';
      } else if (newStatus == 'rejected' || newTargetStatus == 'rejected') {
        updateData['overall_status'] = 'rejected';
      } else {
        updateData['overall_status'] = 'pending';
      }

      final response = await client
          .from('matches')
          .update(updateData)
          .eq('id', proposalId)
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''').single();

      return MatchProposal.fromJson(response);
    } catch (error) {
      throw Exception('Yanıt güncellenemedi: $error');
    }
  }

  /// Accept a proposal
  Future<MatchProposal> acceptProposal({
    required String proposalId,
    required String candidateId,
  }) async {
    return updateCandidateResponse(
      proposalId: proposalId,
      candidateId: candidateId,
      status: AcceptanceStatus.accepted,
    );
  }

  /// Reject a proposal
  Future<MatchProposal> rejectProposal({
    required String proposalId,
    required String candidateId,
  }) async {
    return updateCandidateResponse(
      proposalId: proposalId,
      candidateId: candidateId,
      status: AcceptanceStatus.rejected,
    );
  }

  /// Get matched proposals for a candidate
  Future<List<MatchProposal>> getMatchedProposals(String candidateId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''')
          .or('candidate_id.eq.$candidateId,target_candidate_id.eq.$candidateId')
          .eq('status', 'matched')
          .order('updated_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => MatchProposal.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Eşleşmeler yüklenemedi: $error');
    }
  }

  /// Get proposal statistics for a user
  Future<Map<String, int>> getProposalStatistics(String userId) async {
    try {
      final client = await _supabaseService.client;

      final results = await Future.wait([
        // Pending proposals
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'pending'),

        // Matched proposals
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'matched'),

        // Rejected proposals
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'rejected'),
      ]);

      final pendingCount = (results[0] as List).length;
      final matchedCount = (results[1] as List).length;
      final rejectedCount = (results[2] as List).length;

      return {
        'pending_proposals': pendingCount,
        'matched_proposals': matchedCount,
        'rejected_proposals': rejectedCount,
        'total_proposals': pendingCount + matchedCount + rejectedCount,
      };
    } catch (error) {
      throw Exception('İstatistikler yüklenemedi: $error');
    }
  }

  /// Delete a proposal (admin or creator only)
  Future<void> deleteProposal(String proposalId) async {
    try {
      final client = await _supabaseService.client;
      await client.from('matches').delete().eq('id', proposalId);
    } catch (error) {
      throw Exception('Öneri silinemedi: $error');
    }
  }

  /// Get proposals by selector
  Future<List<MatchProposal>> getProposalsBySelector(String selectorId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            selector:selector_id(full_name, image_url),
            candidate:candidate_id(full_name, image_url, bio),
            target_candidate:target_candidate_id(full_name, image_url, bio)
          ''')
          .eq('selector_id', selectorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MatchProposal.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load proposals by selector: $e');
    }
  }

  /// Get proposals for a candidate
  Future<List<MatchProposal>> getProposalsForCandidate(
      String candidateId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            selector:selector_id(full_name, image_url),
            candidate:candidate_id(full_name, image_url, bio),
            target_candidate:target_candidate_id(full_name, image_url, bio)
          ''')
          .or('candidate_id.eq.$candidateId,target_candidate_id.eq.$candidateId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MatchProposal.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load proposals for candidate: $e');
    }
  }

  /// Withdraw a proposal
  Future<void> withdrawProposal(String proposalId) async {
    try {
      await _supabase.from('matches').update({
        'status': 'rejected',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', proposalId);
    } catch (e) {
      throw Exception('Failed to withdraw proposal: $e');
    }
  }

  /// Respond to a proposal
  Future<void> respondToProposal(String proposalId,
      {required bool isAccepted}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current proposal
      final proposalResponse = await _supabase
          .from('matches')
          .select('*')
          .eq('id', proposalId)
          .single();

      final proposal = MatchProposal.fromJson(proposalResponse);

      // Determine which candidate is responding
      final isCandidate1 = proposal.candidateId == currentUser.id;
      final isCandidate2 = proposal.targetCandidateId == currentUser.id;

      if (!isCandidate1 && !isCandidate2) {
        throw Exception('User is not part of this proposal');
      }

      // Update status
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isCandidate1) {
        updates['status'] = isAccepted ? 'accepted' : 'rejected';
      } else {
        updates['target_status'] = isAccepted ? 'accepted' : 'rejected';
      }

      // Calculate final status
      final newstatus = isCandidate1
          ? (isAccepted ? AcceptanceStatus.accepted : AcceptanceStatus.rejected)
          : proposal.status;
      final newtargetStatus = isCandidate2
          ? (isAccepted ? AcceptanceStatus.accepted : AcceptanceStatus.rejected)
          : proposal.targetStatus;

      if (!isAccepted) {
        updates['status'] = 'rejected';
      } else if (newstatus == AcceptanceStatus.accepted &&
          newtargetStatus == AcceptanceStatus.accepted) {
        updates['status'] = 'matched';
      } else if (newstatus == AcceptanceStatus.accepted) {
        updates['status'] = 'candidateaccepted';
      } else if (newtargetStatus == AcceptanceStatus.accepted) {
        updates['status'] = 'targetcandidateaccepted';
      }

      await _supabase.from('matches').update(updates).eq('id', proposalId);
    } catch (e) {
      throw Exception('Failed to respond to proposal: $e');
    }
  }
}
