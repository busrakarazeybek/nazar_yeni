import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onDataChanged;
  final VoidCallback onAccountDeletion;

  const SettingsSectionWidget({
    super.key,
    required this.userData,
    required this.onDataChanged,
    required this.onAccountDeletion,
  });

  @override
  State<SettingsSectionWidget> createState() => _SettingsSectionWidgetState();
}

class _SettingsSectionWidgetState extends State<SettingsSectionWidget> {
  late bool _notificationsEnabled;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled =
        widget.userData["notificationsEnabled"] as bool? ?? true;
    _selectedLanguage = widget.userData["language"] as String? ?? 'Türkçe';
  }

  void _updateNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    widget.userData["notificationsEnabled"] = value;
    widget.onDataChanged();
  }

  void _updateLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    widget.userData["language"] = language;
    widget.onDataChanged();
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Dil Seçimi',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Türkçe'),
              _buildLanguageOption('English'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(
        language,
        style: AppTheme.lightTheme.textTheme.bodyMedium,
      ),
      value: language,
      groupValue: _selectedLanguage,
      onChanged: (String? value) {
        if (value != null) {
          _updateLanguage(value);
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Gizlilik Bilgileri',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Veri Kullanımı',
                  style: AppTheme.lightTheme.textTheme.titleSmall,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Kişisel verileriniz KVKK (Kişisel Verilerin Korunması Kanunu) kapsamında korunmaktadır. Verileriniz sadece eşleşme hizmeti için kullanılır.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Veri Paylaşımı',
                  style: AppTheme.lightTheme.textTheme.titleSmall,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Verileriniz üçüncü taraflarla paylaşılmaz. Sadece seçiciler ve adaylar arasında eşleşme amacıyla kullanılır.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Veri Silme',
                  style: AppTheme.lightTheme.textTheme.titleSmall,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir. Bu işlem geri alınamaz.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anladım'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required String iconName,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.secondaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: titleColor ?? AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.textSecondaryLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Hesap Ayarları',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Notifications
          _buildSettingTile(
            title: 'Bildirimler',
            subtitle: 'Eşleşme ve mesaj bildirimleri',
            iconName: 'notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _updateNotifications,
            ),
          ),

          // Language
          _buildSettingTile(
            title: 'Dil',
            subtitle: _selectedLanguage,
            iconName: 'language',
            onTap: _showLanguageDialog,
          ),

          // Privacy
          _buildSettingTile(
            title: 'Gizlilik',
            subtitle: 'Veri kullanımı ve gizlilik politikası',
            iconName: 'privacy_tip',
            onTap: _showPrivacyInfo,
          ),

          // Help & Support
          _buildSettingTile(
            title: 'Yardım ve Destek',
            subtitle: 'SSS ve iletişim',
            iconName: 'help',
            onTap: () {
              // Navigate to help screen
            },
          ),

          // About
          _buildSettingTile(
            title: 'Hakkında',
            subtitle: 'Uygulama sürümü ve bilgileri',
            iconName: 'info',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Goricu Matchmaker',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sürüm: 1.0.0',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Geleneksel Türk görücü usulü ile modern teknoloji bir araya geliyor.',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 2.h),

          // Logout
          _buildSettingTile(
            title: 'Çıkış Yap',
            iconName: 'logout',
            titleColor: AppTheme.warningColor,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Çıkış Yap',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  content: const Text(
                      'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(
                            context, '/login-screen');
                      },
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Delete Account
          _buildSettingTile(
            title: 'Hesabı Sil',
            subtitle: 'Hesabınızı kalıcı olarak silin',
            iconName: 'delete_forever',
            titleColor: AppTheme.errorColor,
            onTap: widget.onAccountDeletion,
          ),
        ],
      ),
    );
  }
}
