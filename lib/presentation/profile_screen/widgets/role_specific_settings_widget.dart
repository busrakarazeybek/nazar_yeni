import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RoleSpecificSettingsWidget extends StatefulWidget {
  final String userRole;
  final Map<String, dynamic> userData;
  final VoidCallback onDataChanged;

  const RoleSpecificSettingsWidget({
    super.key,
    required this.userRole,
    required this.userData,
    required this.onDataChanged,
  });

  @override
  State<RoleSpecificSettingsWidget> createState() =>
      _RoleSpecificSettingsWidgetState();
}

class _RoleSpecificSettingsWidgetState
    extends State<RoleSpecificSettingsWidget> {
  late double _searchRadius;
  late String _privacyLevel;
  late bool _allowSelectorRequests;
  late bool _showOnlineStatus;

  @override
  void initState() {
    super.initState();
    _searchRadius = (widget.userData["searchRadius"] ?? 50).toDouble();
    _privacyLevel = widget.userData["privacyLevel"] as String? ?? 'Orta';
    _allowSelectorRequests =
        widget.userData["allowSelectorRequests"] as bool? ?? true;
    _showOnlineStatus = widget.userData["showOnlineStatus"] as bool? ?? true;
  }

  void _updateData() {
    widget.userData["searchRadius"] = _searchRadius.round();
    widget.userData["privacyLevel"] = _privacyLevel;
    widget.userData["allowSelectorRequests"] = _allowSelectorRequests;
    widget.userData["showOnlineStatus"] = _showOnlineStatus;
    widget.onDataChanged();
  }

  void _showAgeWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yaş 18-100 arasında olmalıdır'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSelectorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seçici Ayarları',
          style: AppTheme.lightTheme.textTheme.labelMedium,
        ),
        SizedBox(height: 2.h),

        // Service Preferences
        _buildSettingTile(
          'Aktif Hizmet',
          'Yeni adayları otomatik olarak görüntüle',
          _showOnlineStatus,
          (value) {
            setState(() {
              _showOnlineStatus = value;
            });
            _updateData();
          },
          'trending_up',
        ),
      ],
    );
  }

  Widget _buildCandidateSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seçici İzinleri',
          style: AppTheme.lightTheme.textTheme.labelMedium,
        ),
        SizedBox(height: 2.h),

        _buildSettingTile(
          'Seçici İsteklerini Kabul Et',
          'Yeni seçicilerin size ulaşmasına izin ver',
          _allowSelectorRequests,
          (value) {
            setState(() {
              _allowSelectorRequests = value;
            });
            _updateData();
          },
          'person_add',
        ),
        SizedBox(height: 2.h),


        // Privacy Level
        Text(
          'Gizlilik Seviyesi',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _privacyLevel,
              isExpanded: true,
              items: ['Düşük', 'Orta', 'Yüksek'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _privacyLevel = newValue;
                  });
                  _updateData();
                }
              },
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          _getPrivacyDescription(_privacyLevel),
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _getPrivacyDescription(String level) {
    switch (level) {
      case 'Düşük':
        return 'Profiliniz tüm seçiciler tarafından görülebilir';
      case 'Orta':
        return 'Profiliniz onaylanmış seçiciler tarafından görülebilir';
      case 'Yüksek':
        return 'Profiliniz sadece davet ettiğiniz seçiciler tarafından görülebilir';
      default:
        return '';
    }
  }

  Widget _buildGenderSelection() {
    final selectedGenders = (widget.userData['preferredGenders'] as List?)?.cast<String>() ?? [];
    final genderOptions = {
      'male': 'Erkek',
      'female': 'Kadın',
      'other': 'Diğer',
      'preferNotToSay': 'Belirtmek istemiyorum'
    };

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: genderOptions.entries.map((entry) {
        final isSelected = selectedGenders.contains(entry.key);
        return FilterChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            List<String> newGenders = List.from(selectedGenders);
            if (selected) {
              if (!newGenders.contains(entry.key)) {
                newGenders.add(entry.key);
              }
            } else {
              newGenders.remove(entry.key);
            }
            widget.userData['preferredGenders'] = newGenders;
            widget.onDataChanged();
            setState(() {});
          },
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          selectedColor: AppTheme.lightTheme.colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected 
                ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                : AppTheme.lightTheme.colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    String iconName,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.lightTheme.textTheme.bodyMedium),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
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
                iconName: widget.userRole == 'selector'
                    ? 'admin_panel_settings'
                    : 'security',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                widget.userRole == 'selector' ? 'Seçici Ayarları' : 'Aday Ayarları',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 3.h),
          widget.userRole == 'selector'
              ? _buildSelectorSettings()
              : _buildCandidateSettings(),
        ],
      ),
    );
  }
}
