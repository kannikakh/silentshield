import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SOSButtonWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeUp;

  const SOSButtonWidget({
    super.key,
    required this.isActive,
    required this.onLongPress,
    required this.onSwipeUp,
  });

  @override
  State<SOSButtonWidget> createState() => _SOSButtonWidgetState();
}

class _SOSButtonWidgetState extends State<SOSButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLongPressing = false;
  double _longPressProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SOSButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isLongPressing = true);
    HapticFeedback.mediumImpact();

    Future.delayed(Duration(milliseconds: 100), () {
      if (_isLongPressing) {
        _updateProgress();
      }
    });
  }

  void _updateProgress() {
    if (!_isLongPressing) return;

    setState(() {
      _longPressProgress += 0.05;
      if (_longPressProgress >= 1.0) {
        _longPressProgress = 1.0;
        HapticFeedback.heavyImpact();
        widget.onLongPress();
        _isLongPressing = false;
        _longPressProgress = 0.0;
        return;
      }
    });

    HapticFeedback.selectionClick();
    Future.delayed(Duration(milliseconds: 50), _updateProgress);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -500) {
          widget.onSwipeUp();
        }
      },
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onLongPressStart: _handleLongPressStart,
                  onLongPressEnd: _handleLongPressEnd,
                  child: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.emergencyColor,
                          AppTheme.emergencyColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emergencyColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isLongPressing)
                          CircularProgressIndicator(
                            value: _longPressProgress,
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'emergency',
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'SOS',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Long press to activate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'swipe_up',
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                'Swipe up for options',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
