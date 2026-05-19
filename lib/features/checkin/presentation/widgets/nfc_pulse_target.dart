import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class NfcPulseTarget extends StatefulWidget {
  const NfcPulseTarget({
    super.key,
    this.resultMode = false,
  });

  final bool resultMode;

  @override
  State<NfcPulseTarget> createState() => _NfcPulseTargetState();
}

class _NfcPulseTargetState extends State<NfcPulseTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = widget.resultMode
        ? Icons.check_circle_rounded
        : Icons.nfc_rounded;
    final color = widget.resultMode ? AppColors.success : AppColors.primary;

    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 0.62 + i * 0.22 + (_controller.value * 0.08),
                  child: Opacity(
                    opacity: (0.42 - i * 0.1) * (1 - _controller.value * 0.35),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 178,
                height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 46,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 82),
              ),
            ],
          );
        },
      ),
    );
  }
}
