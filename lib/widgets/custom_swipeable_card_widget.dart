import 'package:flutter/material.dart';

enum SwipeDirection { left, right, up, down }

class CustomSwipeableCard extends StatefulWidget {
  final List<Widget> cards;
  final Function(SwipeDirection direction, int index)? onSwipe;
  final Function(DragUpdateDetails details, int index)? onUpdate;
  final double swipeThreshold;
  final int stackSize;
  final EdgeInsets cardPadding;
  final Duration animationDuration;

  const CustomSwipeableCard({
    super.key,
    required this.cards,
    this.onSwipe,
    this.onUpdate,
    this.swipeThreshold = 0.25,
    this.stackSize = 3,
    this.cardPadding = const EdgeInsets.all(8.0),
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CustomSwipeableCard> createState() => _CustomSwipeableCardState();
}

class _CustomSwipeableCardState extends State<CustomSwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    setState(() {
      _cardOffset += details.delta;
      _cardRotation = _cardOffset.dx / 1000;
    });

    widget.onUpdate?.call(details, _currentIndex);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * widget.swipeThreshold;

    SwipeDirection? direction;
    Offset targetOffset = Offset.zero;

    if (_cardOffset.dx.abs() > swipeThreshold) {
      if (_cardOffset.dx > 0) {
        direction = SwipeDirection.right;
        targetOffset = Offset(screenWidth * 2, _cardOffset.dy);
      } else {
        direction = SwipeDirection.left;
        targetOffset = Offset(-screenWidth * 2, _cardOffset.dy);
      }
    } else if (_cardOffset.dy.abs() > swipeThreshold) {
      if (_cardOffset.dy > 0) {
        direction = SwipeDirection.down;
        targetOffset =
            Offset(_cardOffset.dx, MediaQuery.of(context).size.height * 2);
      } else {
        direction = SwipeDirection.up;
        targetOffset =
            Offset(_cardOffset.dx, -MediaQuery.of(context).size.height * 2);
      }
    }

    if (direction != null) {
      _animateCardExit(targetOffset, direction);
    } else {
      _animateCardReturn();
    }
  }

  void _animateCardExit(Offset targetOffset, SwipeDirection direction) {
    _isAnimating = true;

    _offsetAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: direction == SwipeDirection.right ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      widget.onSwipe?.call(direction, _currentIndex);
      _nextCard();
    });
  }

  void _animateCardReturn() {
    _isAnimating = true;

    _offsetAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward().then((_) {
      setState(() {
        _cardOffset = Offset.zero;
        _cardRotation = 0.0;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex++;
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
      _isAnimating = false;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty || _currentIndex >= widget.cards.length) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Background cards
        for (int i = 1;
            i < widget.stackSize && _currentIndex + i < widget.cards.length;
            i++)
          Transform.scale(
            scale: 1.0 - (i * 0.05),
            child: Transform.translate(
              offset: Offset(0, i * 8.0),
              child: Opacity(
                opacity: 1.0 - (i * 0.2),
                child: Container(
                  margin: widget.cardPadding,
                  child: widget.cards[_currentIndex + i],
                ),
              ),
            ),
          ),

        // Top card
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final offset = _isAnimating ? _offsetAnimation.value : _cardOffset;
            final rotation =
                _isAnimating ? _rotationAnimation.value : _cardRotation;
            final scale = _isAnimating ? _scaleAnimation.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: rotation,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      margin: widget.cardPadding,
                      child: widget.cards[_currentIndex],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
