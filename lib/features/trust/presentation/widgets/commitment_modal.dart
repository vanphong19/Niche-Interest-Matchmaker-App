// lib/features/trust/presentation/widgets/commitment_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_trust.dart';

/// Modal cam kết tham gia sự kiện
/// Hiện trước khi user confirm join event
Future<bool> showCommitmentModal(
  BuildContext context, {
  required String eventName,
  required DateTime eventStart,
  required String location,
  UserTrust? userTrust,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommitmentModal(
      eventName: eventName,
      eventStart: eventStart,
      location: location,
      userTrust: userTrust,
    ),
  );
  return result ?? false;
}

class CommitmentModal extends StatefulWidget {
  const CommitmentModal({
    super.key,
    required this.eventName,
    required this.eventStart,
    required this.location,
    this.userTrust,
  });

  final String eventName;
  final DateTime eventStart;
  final String location;
  final UserTrust? userTrust;

  @override
  State<CommitmentModal> createState() => _CommitmentModalState();
}

class _CommitmentModalState extends State<CommitmentModal>
    with SingleTickerProviderStateMixin {
  bool _agreed = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final day = days[dt.weekday % 7];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day, ${dt.day}/${dt.month}/${dt.year} lúc $h:$m';
  }

  void _handleConfirm() {
    if (!_agreed) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trust = widget.userTrust;
    final isLowTrust = (trust?.score ?? 100) < 40;
    final isRestricted = trust?.isRestricted ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cam kết tham gia',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C2C58),
                            ),
                          ),
                          const Text(
                            'Đọc kỹ trước khi xác nhận',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Event info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.celebration_rounded,
                        label: 'Sự kiện',
                        value: widget.eventName,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Thời gian',
                        value: _formatDateTime(widget.eventStart),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        label: 'Địa điểm',
                        value: widget.location,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Check-in rules
                _RuleCard(isDark: isDark),
                const SizedBox(height: 14),

                // No-show warning
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nếu không tham gia và không báo trước',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Bạn sẽ bị trừ 15 điểm uy tín. Nếu no-show ≥ 3 lần/30 ngày, tài khoản sẽ bị hạn chế đăng ký sự kiện trong 3 ngày.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Low trust / restricted extra warning
                if (isLowTrust || isRestricted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🚨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isRestricted
                                ? 'Tài khoản của bạn đang bị hạn chế. Host sẽ thấy trạng thái này.'
                                : 'Điểm uy tín của bạn đang thấp (<40). Host có quyền từ chối đơn của bạn.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Agreement checkbox
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _agreed = !_agreed);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _agreed
                            ? AppColors.primary.withValues(alpha: 0.07)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF8FAFF)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _agreed
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _agreed
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _agreed
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: _agreed
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tôi đã đọc và cam kết tuân thủ các quy định trên',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _agreed
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white54
                              : Colors.black54,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _agreed
                              ? AppColors.primaryGradient
                              : null,
                          color: _agreed
                              ? null
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton(
                          onPressed: _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            '🚀  Đồng ý tham gia',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _agreed ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C2C58),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rule_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Quy định check-in',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C2C58),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Rule(
            text: 'Check-in đúng giờ hoặc trước giờ bắt đầu → +5 điểm',
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 5),
          _Rule(
            text: 'Check-in trễ < 15 phút → +2 điểm',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 5),
          _Rule(
            text: 'Hủy sát giờ (< 12 tiếng trước) → -5 điểm',
            color: const Color(0xFFF97316),
          ),
          const SizedBox(height: 5),
          _Rule(
            text: 'Không đến, không báo → -15 điểm uy tín',
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
