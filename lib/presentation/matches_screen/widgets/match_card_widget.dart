import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class MatchCardWidget extends StatelessWidget {
  final Map<String, dynamic> match;
  final String userRole;
  final Function(int, String) onAction;
  final VoidCallback onTap;

  const MatchCardWidget({
    super.key,
    required this.match,
    required this.userRole,
    required this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = match['status'] as String;
    final timestamp = match['timestamp'] as DateTime;
    final candidateName = match['candidateName'] as String;
    final candidateAge = match['candidateAge'] as int;
    final candidateImage = match['candidateImage'] as String;
    final selectorName = match['selectorName'] as String?;
    final selectorRelation = match['selectorRelation'] as String?;

    return Dismissible(
      key: Key('match_${match['id']}'),
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Accept action
          if (userRole == 'Candidate' && status == 'pending') {
            onAction(match['id'] as int, 'accept');
          }
        } else {
          // Reject/Decline action
          if (userRole == 'Candidate' && status == 'pending') {
            onAction(match['id'] as int, 'decline');
          } else if (userRole == 'Selector' && status == 'pending') {
            onAction(match['id'] as int, 'withdraw');
          }
        }
      },
      confirmDismiss: (direction) async {
        return await _showConfirmDialog(context, direction);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CustomImageWidget(
                        imageUrl: candidateImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),

                    // Profile Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  candidateName,
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$candidateAge yaşında',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          if (selectorName != null &&
                              userRole == 'Candidate') ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'person',
                                  color: AppTheme.textSecondaryLight,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$selectorName ($selectorRelation)',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.textSecondaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Timestamp and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTimestamp(timestamp),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (status == 'pending') _buildActionButtons(),
                  ],
                ),

                // Interest Tags (if available)
                if (match['interests'] != null) ...[
                  SizedBox(height: 12),
                  _buildInterestTags(match['interests'] as List),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppTheme.warningColor.withValues(alpha: 0.1);
        textColor = AppTheme.warningColor;
        text = 'Bekliyor';
        break;
      case 'accepted':
        backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        text = 'Kabul';
        break;
      case 'rejected':
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
        text = 'Red';
        break;
      default:
        backgroundColor = AppTheme.textSecondaryLight.withValues(alpha: 0.1);
        textColor = AppTheme.textSecondaryLight;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (userRole == 'Candidate') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => onAction(match['id'] as int, 'decline'),
            icon: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.errorColor,
              size: 16,
            ),
            label: Text(
              'Reddet',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => onAction(match['id'] as int, 'accept'),
            icon: CustomIconWidget(
              iconName: 'check',
              color: Colors.white,
              size: 16,
            ),
            label: Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else {
      return TextButton.icon(
        onPressed: () => onAction(match['id'] as int, 'withdraw'),
        icon: CustomIconWidget(
          iconName: 'cancel',
          color: AppTheme.errorColor,
          size: 16,
        ),
        label: Text(
          'Geri Çek',
          style: TextStyle(color: AppTheme.errorColor),
        ),
      );
    }
  }

  Widget _buildInterestTags(List interests) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: (interests).take(3).map((interest) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            interest.toString(),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwipeBackground(bool isLeftSwipe) {
    return Container(
      alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      color: isLeftSwipe ? AppTheme.successColor : AppTheme.errorColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: isLeftSwipe ? 'check' : 'close',
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            isLeftSwipe ? 'Kabul Et' : 'Reddet',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, DismissDirection direction) {
    String title;
    String content;

    if (direction == DismissDirection.startToEnd) {
      title = 'Eşleşmeyi Kabul Et';
      content = 'Bu eşleşmeyi kabul etmek istediğinizden emin misiniz?';
    } else {
      title =
          userRole == 'Candidate' ? 'Eşleşmeyi Reddet' : 'Eşleşmeyi Geri Çek';
      content = userRole == 'Candidate'
          ? 'Bu eşleşmeyi reddetmek istediğinizden emin misiniz?'
          : 'Bu eşleşmeyi geri çekmek istediğinizden emin misiniz?';
    }

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
