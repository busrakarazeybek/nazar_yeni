import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/match_service.dart';

class MatchProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();

  List<Match> _matches = [];
  List<Match> _pendingMatches = [];
  List<Match> _acceptedMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Match> get matches => _matches;
  List<Match> get pendingMatches => _pendingMatches;
  List<Match> get acceptedMatches => _acceptedMatches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get match by ID
  Match? getMatchById(String matchId) {
    try {
      return _matches.firstWhere((match) => match.id == matchId);
    } catch (e) {
      return null;
    }
  }

  // Load matches for current user
  Future<void> loadMatches({String? userId}) async {
    try {
      _setLoading(true);
      _clearError();

      final matches = await _matchService.getMatches(userId: userId!);
      _matches = matches;

      // Filter matches by status
      _pendingMatches = matches.where((match) => match.isPending).toList();
      _acceptedMatches = matches.where((match) => match.isAccepted).toList();

      notifyListeners();
    } catch (e) {
      _setError('Eşleşmeler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Accept a match
  Future<bool> acceptMatch(String matchId) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedMatch = await _matchService.updateMatchStatus(
        matchId: matchId,
        status: MatchStatus.accepted,
      );

      // Update local state
      final matchIndex = _matches.indexWhere((match) => match.id == matchId);
      if (matchIndex != -1) {
        _matches[matchIndex] = updatedMatch;

        // Update filtered lists
        _pendingMatches.removeWhere((match) => match.id == matchId);
        _acceptedMatches.add(updatedMatch);

        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Eşleşme kabul edilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject a match
  Future<bool> rejectMatch(String matchId) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedMatch = await _matchService.updateMatchStatus(
        matchId: matchId,
        status: MatchStatus.rejected,
      );

      // Update local state
      final matchIndex = _matches.indexWhere((match) => match.id == matchId);
      if (matchIndex != -1) {
        _matches[matchIndex] = updatedMatch;

        // Update filtered lists
        _pendingMatches.removeWhere((match) => match.id == matchId);

        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Eşleşme reddedilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create a new match
  Future<Match?> createMatch({
    required String selectorId,
    required String candidateId,
    required String targetCandidateId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final match = await _matchService.createMatch(
        selectorId: selectorId,
        candidateId: candidateId,
        targetCandidateId: targetCandidateId,
      );

      _matches.add(match);
      _pendingMatches.add(match);
      notifyListeners();

      return match;
    } catch (e) {
      _setError('Eşleşme oluşturulurken hata oluştu: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get matches for a specific user
  Future<List<Match>> getMatchesForUser(String userId) async {
    try {
      return await _matchService.getMatchesForUser(userId);
    } catch (e) {
      _setError('Kullanıcı eşleşmeleri yüklenirken hata oluştu: $e');
      return [];
    }
  }

  // Refresh matches
  Future<void> refreshMatches({String? userId}) async {
    await loadMatches(userId: userId);
  }

  // Clear all matches
  void clearMatches() {
    _matches.clear();
    _pendingMatches.clear();
    _acceptedMatches.clear();
    _clearError();
    notifyListeners();
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

  // Get accepted matches count
  int get acceptedMatchesCount => _acceptedMatches.length;

  // Get pending matches count
  int get pendingMatchesCount => _pendingMatches.length;

  // Check if there's a match between two users
  bool hasMatchBetween(String userId1, String userId2) {
    return _matches.any((match) =>
        (match.candidateId == userId1 && match.targetCandidateId == userId2) ||
        (match.candidateId == userId2 && match.targetCandidateId == userId1) ||
        (match.selectorId == userId1 && match.candidateId == userId2) ||
        (match.selectorId == userId2 && match.candidateId == userId1));
  }

  // Get mutual matches (both users accepted)
  List<Match> getMutualMatches() {
    return _acceptedMatches.where((match) => match.isAccepted).toList();
  }
}
