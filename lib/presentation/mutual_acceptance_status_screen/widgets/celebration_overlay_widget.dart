import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CelebrationOverlayWidget extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback? onComplete;

  const CelebrationOverlayWidget({
    super.key,
    required this.controller,
    this.onComplete,
  });

  @override
  State<CelebrationOverlayWidget> createState() =>
      _CelebrationOverlayWidgetState();
}

class _CelebrationOverlayWidgetState extends State<CelebrationOverlayWidget> {
  late List<Confetti> confettiList;

  @override
  void initState() {
    super.initState();
    _initializeConfetti();

    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _initializeConfetti() {
    confettiList = List.generate(30, (index) => Confetti());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withAlpha(77),
          child: Stack(
            children: [
              // Confetti Animation
              ...confettiList.map((confetti) =>
                  _buildConfettiPiece(confetti, widget.controller.value)),

              // Celebration Message
              Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Celebration Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Congratulations Text
                      Text(
                        'Tebrikler! 🎉',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.successColor,
                                ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Eşleşme başarıyla tamamlandı!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Her iki aday da birbirini kabul etti.\nArtık sohbet başlatabilirsiniz.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Cultural Blessing
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: AppTheme.accentColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Allah mübarek etsin',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hayırlısı olsun 🤲',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfettiPiece(Confetti confetti, double progress) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final yPosition = (screenHeight + 100) * progress + confetti.startY;
    final xPosition = confetti.startX +
        math.sin(progress * math.pi * 4 + confetti.phase) * confetti.amplitude;

    final rotation = progress * math.pi * 4 + confetti.rotationOffset;
    final opacity = math.max(0.0, 1.0 - progress);

    return Positioned(
      left: xPosition,
      top: yPosition - 100,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: confetti.size,
            height: confetti.size,
            decoration: BoxDecoration(
              color: confetti.color,
              shape: confetti.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: confetti.isCircle ? null : BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class Confetti {
  final double startX;
  final double startY;
  final double amplitude;
  final double phase;
  final double size;
  final Color color;
  final bool isCircle;
  final double rotationOffset;

  Confetti()
      : startX = math.Random().nextDouble() * 400,
        startY = -math.Random().nextDouble() * 100,
        amplitude = 20 + math.Random().nextDouble() * 40,
        phase = math.Random().nextDouble() * math.pi * 2,
        size = 4 + math.Random().nextDouble() * 8,
        color = _getRandomColor(),
        isCircle = math.Random().nextBool(),
        rotationOffset = math.Random().nextDouble() * math.pi * 2;

  static Color _getRandomColor() {
    final colors = [
      AppTheme.primaryLight,
      AppTheme.accentColor,
      AppTheme.successColor,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}
