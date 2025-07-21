import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectorCardWidget extends StatelessWidget {
  final Map<String, dynamic> selector;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onToggleStatus;

  const SelectorCardWidget({
    super.key,
    required this.selector,
    required this.onTap,
    required this.onRemove,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = selector['isActive'] as bool;
    final bool isPaused = selector['isPaused'] as bool;
    final int totalSent = selector['totalSent'] as int;
    final int accepted = selector['accepted'] as int;
    final double successRate = selector['successRate'] as double;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.w),
                        child: CustomImageWidget(
                          imageUrl: selector['profileImage'] as String,
                          width: 12.w,
                          height: 12.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 3.w,
                          height: 3.w,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.surface,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selector['name'] as String,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPaused)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Duraklatıldı",
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'family_restroom',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              selector['relationshipType'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            CustomIconWidget(
                              iconName: 'access_time',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                selector['lastActivity'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      "Gönderilen",
                      totalSent.toString(),
                      AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 4.h,
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      "Kabul",
                      accepted.toString(),
                      AppTheme.successColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 4.h,
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      "Başarı",
                      "%${successRate.toStringAsFixed(0)}",
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              LinearProgressIndicator(
                value: totalSent > 0 ? accepted / totalSent : 0,
                backgroundColor: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                minHeight: 0.5.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: selector['isPaused'] as bool ? 'play_arrow' : 'pause',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                  selector['isPaused'] as bool ? "Aktifleştir" : "Duraklat"),
              onTap: () {
                Navigator.pop(context);
                onToggleStatus();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: const Text("Detayları Görüntüle"),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorColor,
                size: 24,
              ),
              title: const Text("Kaldır"),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
