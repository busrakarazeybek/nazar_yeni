import '../core/app_export.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Create a new match
  Future<Match> createMatch({
    required String selectorId,
    required String candidateId,
    required String targetCandidateId,
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .insert({
            'selector_id': selectorId,
            'candidate_id': candidateId,
            'target_candidate_id': targetCandidateId,
            'status': 'pending',
          })
          .select()
          .single();

      return Match.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create match: $error');
    }
  }

  /// Get matches for a user (either as candidate or target)
  Future<List<Match>> getUserMatches(String userId) async {
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
          .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get user matches: $error');
    }
  }

  /// Get matches created by a selector
  Future<List<Match>> getSelectorMatches(String selectorId) async {
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

      final List<dynamic> data = response;
      return data.map((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get selector matches: $error');
    }
  }

  /// Update match status
  Future<Match> updateMatchStatus({
    required String matchId,
    required MatchStatus status,
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .update({
            'status': status.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .select('''
            *,
            selector:user_profiles!selector_id (*),
            candidate:user_profiles!candidate_id (*),
            target_candidate:user_profiles!target_candidate_id (*)
          ''')
          .single();

      return Match.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update match status: $error');
    }
  }

  /// Accept a match
  Future<Match> acceptMatch(String matchId) async {
    return updateMatchStatus(matchId: matchId, status: MatchStatus.accepted);
  }

  /// Reject a match
  Future<Match> rejectMatch(String matchId) async {
    return updateMatchStatus(matchId: matchId, status: MatchStatus.rejected);
  }

  /// Get pending matches for a candidate
  Future<List<Match>> getPendingMatches(String candidateId) async {
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

      final List<dynamic> data = response;
      return data.map((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get pending matches: $error');
    }
  }

  /// Get accepted matches for a user
  Future<List<Match>> getAcceptedMatches(String userId) async {
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
          .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get accepted matches: $error');
    }
  }

  /// Delete a match (only for admin or match creator)
  Future<void> deleteMatch(String matchId) async {
    try {
      final client = await _supabaseService.client;
      await client.from('matches').delete().eq('id', matchId);
    } catch (error) {
      throw Exception('Failed to delete match: $error');
    }
  }

  /// Get match statistics for a user
  Future<Map<String, int>> getMatchStatistics(String userId) async {
    try {
      final client = await _supabaseService.client;

      final results = await Future.wait([
        // Pending matches
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'pending'),

        // Accepted matches
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'accepted'),

        // Rejected matches
        client
            .from('matches')
            .select('*')
            .or('candidate_id.eq.$userId,target_candidate_id.eq.$userId')
            .eq('status', 'rejected'),
      ]);

      return {
        'pending_matches': results[0].length,
        'accepted_matches': results[1].length,
        'rejected_matches': results[2].length,
        'total_matches':
            results[0].length + results[1].length + results[2].length,
      };
    } catch (error) {
      throw Exception('Failed to get match statistics: $error');
    }
  }

  /// Get matches for a user (alias for getUserMatches)
  Future<List<Match>> getMatches({required String userId}) async {
    return getUserMatches(userId);
  }

  /// Get matches for a specific user (alias for getUserMatches)
  Future<List<Match>> getMatchesForUser(String userId) async {
    return getUserMatches(userId);
  }

  Future<List<Match>> getTodayMatches(String userId) async {
    try {
      final client = await _supabaseService.client;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final response = await client
          .from('matches')
          .select(
              '*, selector:user_profiles!matches_selector_id_fkey(full_name, image_url), candidate:user_profiles!matches_candidate_id_fkey(full_name, image_url), target_candidate:user_profiles!matches_target_candidate_id_fkey(full_name, image_url)')
          .eq('selector_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return response.map<Match>((matchData) {
        return Match.fromJson(matchData);
      }).toList();
    } catch (e) {
      throw Exception('Bugünkü eşleşmeler yüklenirken hata: $e');
    }
  }

  Future<List<Match>> getIncomingMatches(String candidateId) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('matches')
          .select(
              '*, selector:user_profiles!matches_selector_id_fkey(full_name, image_url), candidate:user_profiles!matches_candidate_id_fkey(full_name, image_url), target_candidate:user_profiles!matches_target_candidate_id_fkey(full_name, image_url)')
          .eq('target_candidate_id', candidateId)
          .order('created_at', ascending: false);

      return response.map<Match>((matchData) {
        return Match.fromJson(matchData);
      }).toList();
    } catch (e) {
      throw Exception('Gelen eşleşmeler yüklenirken hata: $e');
    }
  }

  Future<void> acceptIncomingMatch(String matchId) async {
    try {
      final client = await _supabaseService.client;

      await client
          .from('matches')
          .update({'status': 'accepted'}).eq('id', matchId);
    } catch (e) {
      throw Exception('Eşleşme kabul edilirken hata: $e');
    }
  }

  Future<void> rejectIncomingMatch(String matchId) async {
    try {
      final client = await _supabaseService.client;

      await client
          .from('matches')
          .update({'status': 'rejected'}).eq('id', matchId);
    } catch (e) {
      throw Exception('Eşleşme reddedilirken hata: $e');
    }
  }
}
