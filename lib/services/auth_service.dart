import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import './supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = await _supabaseService.client;
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  /// Sign up new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final client = await _supabaseService.client;

      // Prepare user metadata
      final userData = {
        'full_name': fullName,
        'role': role.toString().split('.').last,
        ...?additionalData,
      };

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      // Wait a moment for the trigger to create the profile
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Update the profile with additional data if provided
        if (additionalData != null && additionalData.isNotEmpty) {
          try {
            await _updateUserProfileAfterSignup(
                response.user!.id, additionalData);
          } catch (e) {
            // Profile update failed, but signup was successful
            // This is not critical for the initial registration
            print('Profile update after signup failed: $e');
          }
        }
      }

      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  /// Update user profile after signup with additional data
  Future<void> _updateUserProfileAfterSignup(
      String userId, Map<String, dynamic> additionalData) async {
    try {
      final client = await _supabaseService.client;

      final updateData = <String, dynamic>{};

      // Map the additional data to profile fields
      if (additionalData['age'] != null) {
        updateData['age'] = additionalData['age'];
      }
      if (additionalData['gender'] != null) {
        updateData['gender'] = additionalData['gender'];
      }
      if (additionalData['bio'] != null) {
        updateData['bio'] = additionalData['bio'];
      }
      if (additionalData['interests'] != null) {
        updateData['interests'] = additionalData['interests'];
      }
      if (additionalData['location'] != null) {
        updateData['location'] = additionalData['location'];
      }
      if (additionalData['profession'] != null) {
        updateData['profession'] = additionalData['profession'];
      }
      if (additionalData['image_url'] != null) {
        updateData['image_url'] = additionalData['image_url'];
      }
      if (additionalData['phone'] != null) {
        updateData['phone'] = additionalData['phone'];
      }

      if (updateData.isNotEmpty) {
        await client.from('user_profiles').update(updateData).eq('id', userId);
      }
    } catch (error) {
      throw Exception('Failed to update profile after signup: $error');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      final client = await _supabaseService.client;
      await client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  /// Get current user
  User? getCurrentUser() {
    if (!_supabaseService.isInitialized) return null;
    return _supabaseService.syncClient.auth.currentUser;
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final client = await _supabaseService.client;
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    String? fullName,
    int? age,
    GenderType? gender,
    String? bio,
    List<String>? interests,
    String? location,
    String? profession,
    String? imageUrl,
    String? phone,
  }) async {
    try {
      final client = await _supabaseService.client;
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (age != null) updateData['age'] = age;
      if (gender != null) {
        updateData['gender'] = gender.toString().split('.').last;
      }
      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;
      if (location != null) updateData['location'] = location;
      if (profession != null) updateData['profession'] = profession;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (phone != null) updateData['phone'] = phone;

      final response = await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      final client = await _supabaseService.client;
      await client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateStream {
    if (!_supabaseService.isInitialized) {
      return Stream.empty();
    }
    return _supabaseService.syncClient.auth.onAuthStateChange;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final user = getCurrentUser();
    return user != null;
  }
}
