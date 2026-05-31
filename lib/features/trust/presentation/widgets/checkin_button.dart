// lib/features/trust/presentation/widgets/checkin_button.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/services/reputation_service.dart';

enum _CheckInState { tooEarly, canCheckIn, tooLate, done }

/// Nút check-in sự kiện với countdown timer và 4 trạng thái
class CheckInButton extends StatefulWidget {
  const CheckInButton({
    super.key,
    required this.eventStart,
    required this.eventName,
    this.eventEnd,
    this.checkedIn = false,
    this.onCheckInPressed,
    this.onCheckedIn,
  });

  final DateTime eventStart;
  final String eventName;
  final DateTime? eventEnd;
  final bool checkedIn;
  final FutureOr<void> Function()? onCheckInPressed;
  final void Function(int delta)? onCheckedIn;

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton>
    with SingleTickerProviderStateMixin {
  _CheckInState _state = _CheckInState.tooEarly;
  Timer? _timer;
  Duration _timeUntilOpen = Duration.zero;
  Duration _timeUntilClose = Duration.zero;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _fallbackCheckinWindow = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _updateState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateState() {
    if (!mounted) return;
    if (widget.checkedIn) {
      if (_state != _CheckInState.done) {
        setState(() => _state = _CheckInState.done);
      }
      return;
    }

    final now = DateTime.now();
    final openAt = widget.eventStart;
    final closeAt =
        widget.eventEnd ?? widget.eventStart.add(_fallbackCheckinWindow);

    _CheckInState newState;
    if (now.isBefore(openAt)) {
      newState = _CheckInState.tooEarly;
      _timeUntilOpen = openAt.difference(now);
    } else if (now.isAfter(closeAt)) {
      newState = _CheckInState.tooLate;
    } else {
      newState = _CheckInState.canCheckIn;
      _timeUntilClose = closeAt.difference(now);
    }

    if (_state == _CheckInState.done) return; // Already checked in
    if (newState != _state) {
      setState(() => _state = newState);
    } else if (_state == _CheckInState.tooEarly ||
        _state == _CheckInState.canCheckIn) {
      setState(() {
        _timeUntilOpen = openAt.difference(now);
        _timeUntilClose = closeAt.difference(now);
      });
    }
  }

  void _checkIn() {
    if (_state != _CheckInState.canCheckIn) return;
    HapticFeedback.heavyImpact();

    final customAction = widget.onCheckInPressed;
    if (customAction != null) {
      customAction();
      return;
    }

    final now = DateTime.now();
    final (delta, _) = ReputationService.calculateCheckinDelta(
      now,
      widget.eventStart,
    );

    setState(() => _state = _CheckInState.done);
    _timer?.cancel();

    if (delta > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✅ ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check-in successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '+$delta points of trust 🎉',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    widget.onCheckedIn?.call(delta);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return _buildButton();
  }

  Widget _buildButton() {
    switch (_state) {
      case _CheckInState.tooEarly:
        return _ButtonShell(
          color: const Color(0xFF64748B),
          gradient: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in opens at start time, time remaining:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(_timeUntilOpen),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case _CheckInState.canCheckIn:
        return ScaleTransition(
          scale: _pulseAnim,
          child: _ButtonShell(
            color: null,
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: _checkIn,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check-in now!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Time remaining: ${_formatDuration(_timeUntilClose)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case _CheckInState.tooLate:
        return _ButtonShell(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          gradient: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.timer_off_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 10),
              Text(
                'Time for check-in has passed',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

      case _CheckInState.done:
        return _ButtonShell(
          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
          gradient: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Check-in successfully',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _ButtonShell extends StatelessWidget {
  const _ButtonShell({
    required this.child,
    required this.color,
    required this.gradient,
    this.onTap,
  });
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
