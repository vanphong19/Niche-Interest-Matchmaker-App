// lib/features/trust/presentation/widgets/host_review_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/services/reputation_service.dart';

/// Má»Ÿ HostReviewForm dÆ°á»›i dáº¡ng bottom sheet
Future<void> showHostReviewForm(
  BuildContext context, {
  required String userId,
  required String userName,
  String? userAvatarUrl,
  required void Function(int stars, bool actuallyAttended) onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HostReviewForm(
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      onSubmit: onSubmit,
    ),
  );
}

class HostReviewForm extends StatefulWidget {
  const HostReviewForm({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.onSubmit,
  });

  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final void Function(int stars, bool actuallyAttended) onSubmit;

  @override
  State<HostReviewForm> createState() => _HostReviewFormState();
}

class _HostReviewFormState extends State<HostReviewForm> {
  int _stars = 0;
  bool _actuallyAttended = true;
  bool _submitted = false;

  void _submit() {
    if (_stars == 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lÃ²ng chá»n sá»‘ sao Ä‘Ã¡nh giÃ¡'),
          backgroundColor: Color(0xFFF97316),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);

    final (delta, _) = ReputationService.calculateReviewDelta(_stars);
    final noShowDelta = _actuallyAttended ? 0 : -15;
    final total = delta + noShowDelta;

    widget.onSubmit(_stars, _actuallyAttended);

    // Show result then close
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          total > 0
              ? 'ÄÃ£ gá»­i Ä‘Ã¡nh giÃ¡. ${widget.userName} nháº­n +$total Ä‘iá»ƒm!'
              : 'ÄÃ£ gá»­i Ä‘Ã¡nh giÃ¡. ${widget.userName} bá»‹ $total Ä‘iá»ƒm.',
        ),
        backgroundColor: total > 0
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User info
                Row(
                  children: [
                    VibeAvatar(
                      name: widget.userName,
                      imageUrl: widget.userAvatarUrl,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ÄÃ¡nh giÃ¡ ngÆ°á»i tham gia',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C2C58),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (_submitted) ...[
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ÄÃ£ gá»­i Ä‘Ã¡nh giÃ¡!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1C2C58),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Attendance toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NgÆ°á»i nÃ y cÃ³ máº·t thá»±c sá»±?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C2C58),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _actuallyAttended
                                    ? 'CÃ³ máº·t â€“ Ä‘iá»ƒm sáº½ Ä‘Æ°á»£c tÃ­nh bÃ¬nh thÆ°á»ng'
                                    : 'Váº¯ng máº·t â€“ bá»‹ trá»« 15 Ä‘iá»ƒm uy tÃ­n',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _actuallyAttended
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _actuallyAttended,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _actuallyAttended = v);
                          },
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? const Color(0xFF22C55E)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Star rating
                  if (_actuallyAttended) ...[
                    Text(
                      'ÄÃ¡nh giÃ¡ tráº£i nghiá»‡m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1C2C58),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < _stars;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _stars = i + 1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                key: ValueKey('star-$i-$filled'),
                                size: 40,
                                color: filled
                                    ? const Color(0xFFF59E0B)
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black.withValues(alpha: 0.16)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        key: ValueKey(_stars),
                        _stars == 0
                            ? 'Cháº¡m vÃ o sao Ä‘á»ƒ Ä‘Ã¡nh giÃ¡'
                            : _starLabel(_stars),
                        style: TextStyle(
                          fontSize: 13,
                          color: _stars > 0
                              ? const Color(0xFFF59E0B)
                              : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_stars > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _deltaColor(_stars).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_stars == 5 ? '+5' : (_stars >= 3 ? '+2' : '-3')} Ä‘iá»ƒm uy tÃ­n sáº½ Ä‘Æ°á»£c cá»™ng/trá»«',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _deltaColor(_stars),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'â­  Gá»­i Ä‘Ã¡nh giÃ¡',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1: return 'ðŸ˜” Ráº¥t tá»‡';
      case 2: return 'ðŸ˜ ChÆ°a tá»‘t';
      case 3: return 'ðŸ™‚ Táº¡m Ä‘Æ°á»£c';
      case 4: return 'ðŸ˜Š KhÃ¡ tá»‘t';
      case 5: return 'ðŸ¤© Tuyá»‡t vá»i!';
      default: return '';
    }
  }

  Color _deltaColor(int stars) {
    if (stars == 5) return const Color(0xFF22C55E);
    if (stars >= 3) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
