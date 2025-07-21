import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';

class ActionButtonWidget extends StatelessWidget {
  final MatchProposal proposal;
  final VoidCallback? onStartChat;
  final VoidCallback? onWithdraw;

  const ActionButtonWidget({
    super.key,
    required this.proposal,
    this.onStartChat,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Primary Action Button
      if (proposal.canStartChat) ...[
        ElevatedButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.chat_bubble),
            label: const Text('Sohbet Başlat'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)))),

        const SizedBox(height: 12),

        // Secondary Action - Send appreciation
        OutlinedButton.icon(
            onPressed: () => _showAppreciationOptions(context),
            icon: const Icon(Icons.favorite_border),
            label: const Text('Teşekkür Mesajı Gönder'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.successColor,
                side: const BorderSide(color: AppTheme.successColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)))),
      ] else if (proposal.isPending) ...[
        // Waiting state - show gentle reminder option
        OutlinedButton.icon(
            onPressed: () => _showReminderOptions(context),
            icon: const Icon(Icons.notification_add),
            label: const Text('Nazik Hatırlatma Gönder'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                side: const BorderSide(color: AppTheme.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)))),

        const SizedBox(height: 12),

        // Withdraw option
        TextButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Eşleşmeyi Geri Çek'),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 12))),
      ] else if (proposal.isRejected) ...[
        // Rejected state - show new search options
        ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.enhancedSelectorHomeScreen),
            icon: const Icon(Icons.search),
            label: const Text('Yeni Arama Yap'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)))),

        const SizedBox(height: 12),

        OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.homeScreen),
            icon: const Icon(Icons.home),
            label: const Text('Ana Sayfaya Dön'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                side: const BorderSide(color: AppTheme.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)))),
      ],

      // Help and Information
      const SizedBox(height: 16),

      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_getHelpText(),
                    style: theme.textTheme.bodySmall?.copyWith())),
          ])),
    ]);
  }

  void _showAppreciationOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Teşekkür Mesajı Seç',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ..._getAppreciationMessages().map((message) => ListTile(
                      leading: const Icon(Icons.favorite,
                          color: AppTheme.accentColor),
                      title: Text(message),
                      onTap: () {
                        Navigator.pop(context);
                        _sendAppreciationMessage(context, message);
                      })),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal')),
                ])));
  }

  void _showReminderOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nazik Hatırlatma',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text(
                      'Adaylara nazik bir hatırlatma göndermek ister misiniz? Bu, onları rahatsız etmeyecek şekilde tasarlanmıştır.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendGentleReminder(context);
                      },
                      child: const Text('Hatırlatma Gönder')),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal')),
                ])));
  }

  List<String> _getAppreciationMessages() {
    return [
      'Bu güzel eşleşme için çok teşekkür ederim! 🙏',
      'Böyle özel bir tanışma için minnettarım 💝',
      'Bu fırsatı yaratığınız için çok sağ olun ✨',
      'Hayatımıza getirdiğiniz bu güzellik için teşekkürler 🌸',
      'Bu anlamlı buluşma için yürekten teşekkürler 💖',
    ];
  }

  void _sendAppreciationMessage(BuildContext context, String message) {
    // TODO: Implement sending appreciation message to selector
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Teşekkür mesajınız gönderildi'),
        backgroundColor: AppTheme.successColor));
  }

  void _sendGentleReminder(BuildContext context) {
    // TODO: Implement sending gentle reminder
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Nazik hatırlatma gönderildi'),
        backgroundColor: AppTheme.primaryLight));
  }

  String _getHelpText() {
    if (proposal.canStartChat) {
      return 'Artık karşılıklı sohbet edebilirsiniz. Saygılı ve samimi bir iletişim kurmayı unutmayın.';
    } else if (proposal.isPending) {
      return 'Yanıt süreleri kişiden kişiye değişebilir. Sabırlı olmak, olumlu sonuçlar almanın anahtarıdır.';
    } else if (proposal.isRejected) {
      return 'Her eşleşme doğru eşleşme olmayabilir. Aramaya devam etmek daha uygun seçenekler bulmanızı sağlar.';
    } else {
      return 'Sorularınız için destek ekibimizle iletişime geçebilirsiniz.';
    }
  }
}
