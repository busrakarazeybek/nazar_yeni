import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CandidateCardWidget extends StatefulWidget {
  final Map<String, dynamic> candidate;
  final VoidCallback onTap;
  final Function(String) onSwipe;

  const CandidateCardWidget({
    super.key,
    required this.candidate,
    required this.onTap,
    required this.onSwipe,
  });

  @override
  State<CandidateCardWidget> createState() => _CandidateCardWidgetState();
}

class _CandidateCardWidgetState extends State<CandidateCardWidget> {
  double _dragDistance = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _dragDistance += details.delta.dx;
        });
      },
      onPanEnd: (details) {
        if (_dragDistance.abs() > 50.w) {
          widget.onSwipe(_dragDistance > 0 ? 'like' : 'pass');
        }
        setState(() {
          _dragDistance = 0;
          _isDragging = false;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragDistance * 0.3, 0),
        child: Transform.rotate(
          angle: _dragDistance * 0.0005,
          child: Container(
            width: double.infinity,
            height: 70.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.w),
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: CustomImageWidget(
                      imageUrl: widget.candidate["profileImage"] as String,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name and age
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.candidate["name"]}, ${widget.candidate["age"]}',
                                  style: AppTheme
                                      .lightTheme.textTheme.headlineSmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(12.w),
                                ),
                                child: Text(
                                  widget.candidate["profession"] as String,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 1.h),

                          // Location
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'location_on',
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                widget.candidate["location"] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 2.h),

                          // Bio
                          Text(
                            widget.candidate["bio"] as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 2.h),

                          // Interest tags
                          _buildInterestTags(),
                        ],
                      ),
                    ),
                  ),

                  // Drag indicators
                  if (_isDragging && _dragDistance.abs() > 20.w)
                    Positioned(
                      top: 20.h,
                      left: _dragDistance > 0 ? 60.w : 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _dragDistance > 0
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName:
                                  _dragDistance > 0 ? 'favorite' : 'close',
                              color: Colors.white,
                              size: 20.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _dragDistance > 0 ? 'BEĞENDİ' : 'GEÇTİ',
                              style: AppTheme.lightTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestTags() {
    final interests = widget.candidate["interests"] as List;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: interests.take(4).map((interest) {
          return Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.w),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              interest as String,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
