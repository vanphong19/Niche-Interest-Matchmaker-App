import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../constants/finder_ui_constants.dart';

class FinderParticipantAvatar extends StatefulWidget {
  const FinderParticipantAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 72,
    this.pulsing = false,
    this.accentColor = AppColors.primary,
  });

  final String imageUrl;
  final String name;
  final double size;
  final bool pulsing;
  final Color accentColor;

  @override
  State<FinderParticipantAvatar> createState() =>
      _FinderParticipantAvatarState();
}

class _FinderParticipantAvatarState extends State<FinderParticipantAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FinderUiConstants.pulse,
    );
    if (widget.pulsing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FinderParticipantAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 24,
      height: widget.size + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulsing)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Container(
                  width: widget.size + 24 * _controller.value,
                  height: widget.size + 24 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withValues(
                      alpha: 0.18 * (1 - _controller.value),
                    ),
                  ),
                );
              },
            ),
          VibeAvatar(
            imageUrl: widget.imageUrl,
            name: widget.name,
            size: widget.size,
            showBorder: true,
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
