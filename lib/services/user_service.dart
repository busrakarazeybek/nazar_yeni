import '../models/user_profile.dart';
import './supabase_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Get all candidates (for selectors)
  Future<List<UserProfile>> getCandidates({
    int? limit,
    int? offset,
    String? location,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    String? selectorId, // yeni parametre
  }) async {
    try {
      final client = await _supabaseService.client;
      var query = client
          .from('user_profiles')
          .select()
          .eq('role', 'candidate')
          .eq('is_active', true);

      if (location != null && location.isNotEmpty) {
        query = query.eq('location', location);
      }

      if (minAge != null) {
        query = query.gte('age', minAge);
      }

      if (maxAge != null) {
        query = query.lte('age', maxAge);
      }

      if (interests != null && interests.isNotEmpty) {
        query = query.overlaps('interests', interests);
      }

      // --- YENİ: Tüm matches tablosundan pending olmayan adayları hariç tut ---
      final matchRows = await client
          .from('matches')
          .select('candidate_id, target_candidate_id, status, target_status');
      final Set<String> excludedIds = {};
      for (final row in matchRows) {
        if (row['status'] != 'pending' && row['candidate_id'] != null) {
          excludedIds.add(row['candidate_id']);
        }
        if (row['target_status'] != 'pending' &&
            row['target_candidate_id'] != null) {
          excludedIds.add(row['target_candidate_id']);
        }
      }
      if (excludedIds.isNotEmpty) {
        query = query.not('id', 'in', excludedIds.toList());
      }
      // --- YENİ SONU ---

      var transformQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      if (offset != null) {
        transformQuery = transformQuery.range(
          offset,
          offset + (limit ?? 20) - 1,
        );
      }

      final response = await transformQuery;
      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get candidates: $error');
    }
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final client = await _supabaseService.client;
      final response =
          await client.from('user_profiles').select().eq('id', userId).single();

      return UserProfile.fromJson(response);
    } catch (error) {
      if (error.toString().contains('PGRST116')) {
        return null; // User not found
      }
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Get candidates for a specific selector
  Future<List<UserProfile>> getSelectorCandidates(String selectorId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client.from('selector_candidates').select('''
            candidate_id,
            user_profiles!candidate_id (*)
          ''').eq('selector_id', selectorId).eq('status', 'active');

      return response
          .map((item) => UserProfile.fromJson(item['user_profiles']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get selector candidates: $error');
    }
  }

  /// Add candidate to selector's list
  Future<void> addCandidateToSelector({
    required String selectorId,
    required String candidateId,
  }) async {
    try {
      final client = await _supabaseService.client;
      await client.from('selector_candidates').insert({
        'selector_id': selectorId,
        'candidate_id': candidateId,
        'status': 'active',
      });
    } catch (error) {
      throw Exception('Failed to add candidate to selector: $error');
    }
  }

  /// Remove candidate from selector's list
  Future<void> removeCandidateFromSelector({
    required String selectorId,
    required String candidateId,
  }) async {
    try {
      final client = await _supabaseService.client;
      await client
          .from('selector_candidates')
          .delete()
          .eq('selector_id', selectorId)
          .eq('candidate_id', candidateId);
    } catch (error) {
      throw Exception('Failed to remove candidate from selector: $error');
    }
  }

  /// Search users by name or email
  Future<List<UserProfile>> searchUsers({
    required String query,
    UserRole? role,
    int? limit,
  }) async {
    try {
      final client = await _supabaseService.client;
      var queryBuilder = client
          .from('user_profiles')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .eq('is_active', true);

      if (role != null) {
        queryBuilder = queryBuilder.eq('role', role.toString().split('.').last);
      }

      final transformQuery = queryBuilder;

      final response = limit != null
          ? await transformQuery.limit(limit)
          : await transformQuery;

      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to search users: $error');
    }
  }

  /// Get users by location
  Future<List<UserProfile>> getUsersByLocation(String location) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('user_profiles')
          .select()
          .eq('location', location)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get users by location: $error');
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final client = await _supabaseService.client;

      final results = await Future.wait([
        // Total candidates
        client
            .from('user_profiles')
            .select()
            .eq('role', 'candidate')
            .eq('is_active', true),

        // Total selectors
        client
            .from('user_profiles')
            .select()
            .eq('role', 'selector')
            .eq('is_active', true),

        // Total matches
        client.from('matches').select(),

        // Active conversations
        client.from('conversations').select(),
      ]);

      return {
        'total_candidates': results[0].length,
        'total_selectors': results[1].length,
        'total_matches': results[2].length,
        'active_conversations': results[3].length,
      };
    } catch (error) {
      throw Exception('Failed to get user statistics: $error');
    }
  }

  /// Get all selectors (for candidate to add as selector)
  Future<List<UserProfile>> getSelectors({
    int? limit,
    int? offset,
    String? location,
    int? minAge,
    int? maxAge,
    List<String>? interests,
  }) async {
    try {
      final client = await _supabaseService.client;
      var query = client
          .from('user_profiles')
          .select()
          .eq('role', 'selector')
          .eq('is_active', true);

      if (location != null && location.isNotEmpty) {
        query = query.eq('location', location);
      }

      if (minAge != null) {
        query = query.gte('age', minAge);
      }

      if (maxAge != null) {
        query = query.lte('age', maxAge);
      }

      if (interests != null && interests.isNotEmpty) {
        query = query.overlaps('interests', interests);
      }

      var transformQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      if (offset != null) {
        transformQuery = transformQuery.range(
          offset,
          offset + (limit ?? 20) - 1,
        );
      }

      final response = await transformQuery;
      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get selectors: $error');
    }
  }

  /// Get selectors associated with a candidate
  Future<List<UserProfile>> getCandidateSelectors(String candidateId) async {
    try {
      final client = await _supabaseService.client;
      final response = await client.from('selector_candidates').select('''
            selector_id,
            user_profiles!selector_id (*)
          ''').eq('candidate_id', candidateId).eq('status', 'active');

      return response
          .map((item) => UserProfile.fromJson(item['user_profiles']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get candidate selectors: $error');
    }
  }

  /// Get selector suggestions for a candidate
  Future<List<Map<String, dynamic>>> getSelectorSuggestions(
    String candidateId,
  ) async {
    try {
      final client = await _supabaseService.client;

      // Query for selector suggestions - this would be based on your database schema
      // For now, returning a structure that matches what the calling code expects
      final response = await client
          .from('selector_suggestions')
          .select('''
            id,
            selector_id,
            suggested_candidate_id,
            status,
            created_at,
            selector:user_profiles!selector_id (full_name, profile_image_url),
            suggested_candidate:user_profiles!suggested_candidate_id (full_name, age, bio, profile_image_url)
          ''')
          .eq('candidate_id', candidateId)
          .order('created_at', ascending: false);

      return response
          .map(
            (item) => {
              'id': item['id'],
              'selectorName': item['selector']['full_name'],
              'selectorImage': item['selector']['profile_image_url'] ?? '',
              'suggestedCandidateName': item['suggested_candidate']
                  ['full_name'],
              'suggestedCandidateAge': item['suggested_candidate']['age'],
              'suggestedCandidateImage':
                  item['suggested_candidate']['profile_image_url'] ?? '',
              'suggestedCandidateBio': item['suggested_candidate']['bio'] ?? '',
              'status': item['status'],
              'timestamp': DateTime.parse(item['created_at']),
            },
          )
          .toList();
    } catch (error) {
      // If table doesn't exist yet, return empty list
      return [];
    }
  }

  /// Add selector to candidate's selector list
  Future<void> addSelectorToCandidate({
    required String candidateId,
    required String selectorEmail,
  }) async {
    try {
      final client = await _supabaseService.client;

      // First, find the selector by email
      final selectorResponse = await client
          .from('user_profiles')
          .select('id')
          .eq('email', selectorEmail)
          .eq('role', 'selector')
          .eq('is_active', true)
          .single();

      final selectorId = selectorResponse['id'];

      // Check if the relationship already exists
      final existingResponse = await client
          .from('selector_candidates')
          .select('id')
          .eq('selector_id', selectorId)
          .eq('candidate_id', candidateId);

      if (existingResponse.isNotEmpty) {
        throw Exception('Bu seçici zaten ekli');
      }

      // Add the relationship
      await client.from('selector_candidates').insert({
        'selector_id': selectorId,
        'candidate_id': candidateId,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      if (error.toString().contains('PGRST116')) {
        throw Exception(
          'Seçici bulunamadı. Lütfen geçerli bir email adresi girin.',
        );
      }
      throw Exception('Seçici eklenirken hata oluştu: $error');
    }
  }

  /// Add filtered candidates by preferences
  Future<List<UserProfile>> getFilteredCandidatesByPreferences(
    String selectorId, {
    String? candidateId,
  }) async {
    try {
      final client = await _supabaseService.client;

      // Call the database function for preference-based filtering
      final response = await client.rpc(
        'get_filtered_candidates_by_preferences',
        params: {'selector_uuid': selectorId, 'candidate_uuid': candidateId},
      );

      if (response == null) return [];

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting filtered candidates by preferences: $e');
      return [];
    }
  }


  /// Get rejected candidates for a selector
  Future<Set<String>> getRejectedCandidatesForSelector({
    required String selectorId,
    required String candidateId,
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('target_candidate_id')
          .eq('selector_id', selectorId)
          .eq('candidate_id', candidateId)
          .eq('selector_status', 'rejected');
      
      return response
          .map((row) => row['target_candidate_id'] as String)
          .toSet();
    } catch (error) {
      print('Error getting rejected candidates: $error');
      return <String>{};
    }
  }

  /// Get approved candidates for a selector
  Future<Set<String>> getApprovedCandidatesForSelector({
    required String selectorId,
    required String candidateId,
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client
          .from('matches')
          .select('target_candidate_id')
          .eq('selector_id', selectorId)
          .eq('candidate_id', candidateId)
          .eq('selector_status', 'approved');
      
      return response
          .map((row) => row['target_candidate_id'] as String)
          .toSet();
    } catch (error) {
      print('Error getting approved candidates: $error');
      return <String>{};
    }
  }
}
