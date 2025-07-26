import 'package:flutter/material.dart';

import '../presentation/candidate_home_screen/candidate_home_screen.dart';
import '../presentation/candidate_profile_detail_screen/candidate_profile_detail_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/chat_screen/improved_chat_screen.dart';
import '../presentation/dual_candidate_selection_screen/dual_candidate_selection_screen.dart';
import '../presentation/enhanced_selector_home_screen/enhanced_selector_home_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/match_proposal_notification_screen/match_proposal_notification_screen.dart';
import '../presentation/matches_screen/matches_screen.dart';
import '../presentation/mutual_acceptance_status_screen/mutual_acceptance_status_screen.dart';
import '../presentation/my_selections_screen/my_selections_screen.dart';
import '../presentation/my_selectors_screen/my_selectors_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/role_selection_screen/role_selection_screen.dart';
import '../presentation/selector_home_screen/selector_home_screen.dart';
import '../presentation/selector_registration_screen/selector_registration_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String roleSelectionScreen = '/role-selection-screen';
  static const String homeScreen = '/home-screen';
  static const String selectorHomeScreen = '/selector-home-screen';
  static const String enhancedSelectorHomeScreen =
      '/enhanced-selector-home-screen';
  static const String candidateHomeScreen = '/candidate-home-screen';
  static const String candidateProfileDetailScreen =
      '/candidate-profile-detail-screen';
  static const String matchesScreen = '/matches-screen';
  static const String registrationScreen = '/registration-screen';
  static const String selectorRegistrationScreen =
      '/selector-registration-screen';
  static const String chatScreen = '/chat-screen';
  static const String improvedChatScreen = '/improved-chat-screen';
  static const String mySelectorsScreen = '/my-selectors-screen';
  static const String mySelectionsScreen = '/my-selections-screen';
  static const String profileScreen = '/profile-screen';
  static const String dualCandidateSelectionScreen =
      '/dual-candidate-selection-screen';
  static const String matchProposalNotificationScreen =
      '/match-proposal-notification-screen';
  static const String mutualAcceptanceStatusScreen =
      '/mutual-acceptance-status-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    roleSelectionScreen: (context) => const RoleSelectionScreen(),
    homeScreen: (context) => const HomeScreen(),
    selectorHomeScreen: (context) => const SelectorHomeScreen(),
    enhancedSelectorHomeScreen: (context) => const EnhancedSelectorHomeScreen(),
    candidateHomeScreen: (context) => const CandidateHomeScreen(),
    candidateProfileDetailScreen: (context) =>
        const CandidateProfileDetailScreen(),
    matchesScreen: (context) => const MatchesScreen(),
    registrationScreen: (context) => const RegistrationScreen(),
    selectorRegistrationScreen: (context) => const SelectorRegistrationScreen(),
    chatScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final matchId = args?['matchId'] as String?;
      return ChatScreen(matchId: matchId);
    },
    improvedChatScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final matchId = args?['matchId'] as String? ?? '';
      final partnerName = args?['partnerName'] as String?;
      final partnerImageUrl = args?['partnerImageUrl'] as String?;
      final partnerId = args?['partnerId'] as String?;
      return ImprovedChatScreen(
        matchId: matchId,
        partnerName: partnerName,
        partnerImageUrl: partnerImageUrl,
        partnerId: partnerId,
      );
    },
    mySelectorsScreen: (context) => const MySelectorsScreen(),
    mySelectionsScreen: (context) => const MySelectionsScreen(),
    profileScreen: (context) => const ProfileScreen(),
    dualCandidateSelectionScreen: (context) =>
        const DualCandidateSelectionScreen(),
    matchProposalNotificationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final proposalId = args?['proposalId'] as String? ?? '';
      return MatchProposalNotificationScreen(proposalId: proposalId);
    },
    mutualAcceptanceStatusScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final proposalId = args?['proposalId'] as String? ?? '';
      return MutualAcceptanceStatusScreen(proposalId: proposalId);
    },
    // TODO: Add your other routes here
  };
}
