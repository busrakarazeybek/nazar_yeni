import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  UserProfile? _currentUserProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Constructor
  AuthProvider() {
    _initialize();
  }

  // Initialize auth state
  Future<void> _initialize() async {
    try {
      _setLoading(true);

      // Listen to auth state changes
      _authService.authStateStream.listen((authState) {
        _onAuthStateChange(authState);
      });

      // Get current user
      _currentUser = _authService.getCurrentUser();

      if (_currentUser != null) {
        await _loadUserProfile();
      }

      _isInitialized = true;
    } catch (e) {
      _setError('Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Handle auth state changes
  void _onAuthStateChange(AuthState authState) async {
    final user = authState.session?.user;

    if (user != null && _currentUser?.id != user.id) {
      _currentUser = user;
      await _loadUserProfile();
    } else if (user == null) {
      _currentUser = null;
      _currentUserProfile = null;
    }

    notifyListeners();
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      _currentUserProfile = await _authService.getCurrentUserProfile();
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      _currentUserProfile = null;
    }
    notifyListeners();
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.signIn(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        fullName: fullName.trim(),
        role: role,
        additionalData: additionalData,
      );

      if (response.user != null) {
        _currentUser = response.user;
        // Profile will be created automatically by trigger
        await _loadUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signOut();

      _currentUser = null;
      _currentUserProfile = null;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile({
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
    if (_currentUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final updatedProfile = await _authService.updateUserProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        age: age,
        gender: gender,
        bio: bio,
        interests: interests,
        location: location,
        profession: profession,
        imageUrl: imageUrl,
        phone: phone,
      );

      _currentUserProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email.trim().toLowerCase());
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user profile
  Future<void> refreshUserProfile() async {
    if (_currentUser != null) {
      await _loadUserProfile();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Hatalı e-posta veya şifre. Lütfen kontrol edin.';
    } else if (error.contains('Email not confirmed')) {
      return 'E-posta adresinizi doğrulamanız gerekiyor.';
    } else if (error.contains('User already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    } else if (error.contains('Unable to validate email address')) {
      return 'Geçerli bir e-posta adresi giriniz.';
    } else if (error.contains('Network request failed')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
