import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ValueChanged<bool> onTypingChanged;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onTypingChanged,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _showEmojiPicker = false;
  bool _isTyping = false;

  final List<String> _quickEmojis = [
    '😊',
    '😍',
    '👍',
    '❤️',
    '😂',
    '🙏',
    '👏',
    '🎉'
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final bool currentlyTyping = widget.controller.text.trim().isNotEmpty;
    if (currentlyTyping != _isTyping) {
      setState(() {
        _isTyping = currentlyTyping;
      });
      widget.onTypingChanged(currentlyTyping);
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      widget.focusNode.unfocus();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _addEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: 'camera_alt',
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    // Camera functionality
                  },
                ),
                _buildImageOption(
                  icon: 'photo_library',
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    // Gallery functionality
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 28,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emoji Picker
        if (_showEmojiPicker)
          Container(
            height: 8.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _addEmoji(_quickEmojis[index]),
                  child: Container(
                    width: 12.w,
                    height: 6.h,
                    margin: EdgeInsets.only(right: 2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _quickEmojis[index],
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Input Area
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Attachment Button
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: 'attach_file',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),

              // Text Input
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 6.h,
                    maxHeight: 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle:
                          AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                    ),
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                  ),
                ),
              ),

              // Emoji Button
              GestureDetector(
                onTap: _toggleEmojiPicker,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: _showEmojiPicker ? 'keyboard' : 'emoji_emotions',
                    color: _showEmojiPicker
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),

              // Send Button
              GestureDetector(
                onTap: _isTyping ? widget.onSend : null,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'send',
                      color: _isTyping
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
