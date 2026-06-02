// lib/features/trust/presentation/pages/trust_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/reputation_api_service.dart';
import '../../domain/entities/trust_badge.dart';
import '../../domain/entities/trust_event_log.dart';
import '../../domain/entities/user_trust.dart';
import '../../domain/services/reputation_service.dart';
import '../widgets/score_circle.dart';
import '../widgets/trust_badge_chip.dart';
import '../widgets/trust_stat_card.dart';
import '../widgets/recovery_mission_card.dart';

class TrustDashboardPage extends StatefulWidget {
  const TrustDashboardPage({
    super.key,
    this.userTrust,
    this.userName = 'You',
    this.userAvatar,
  });

  /// Pass null để dùng mock data
  final UserTrust? userTrust;
  final String userName;
  final String? userAvatar;

  @override
  State<TrustDashboardPage> createState() => _TrustDashboardPageState();
}

class _TrustDashboardPageState extends State<TrustDashboardPage> {
  late UserTrust _trust;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trust = widget.userTrust ?? mockUserTrust;
    if (widget.userTrust == null) {
      _loadTrust();
    }
  }

  Future<void> _loadTrust() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trust = await sl<ReputationApiService>().getMyTrust(
        userName: widget.userName,
        avatarUrl: widget.userAvatar,
      );
      if (!mounted) return;
      setState(() {
        _trust = trust;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load trust history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelData = ReputationService.getLevel(_trust.score);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : const Color(0xFFF5F7FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero SliverAppBar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: levelData.gradientColors.first,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => _showInfoSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroHeader(levelData, isDark),
            ),
          ),

          // ─── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(isDark),
                    const SizedBox(height: 20),
                  ],
                  // Restrict banner
                  if (_trust.isRestricted) ...[
                    _buildRestrictBanner(isDark),
                    const SizedBox(height: 20),
                  ],

                  // Stats row
                  _buildSectionLabel('📊 Thống kê hoạt động', isDark),
                  const SizedBox(height: 12),
                  _buildStatsGrid(isDark),
                  const SizedBox(height: 28),

                  // Badges
                  _buildSectionLabel('🏅 Huy hiệu uy tín', isDark),
                  const SizedBox(height: 12),
                  _buildBadgesGrid(),
                  const SizedBox(height: 28),

                  // History
                  _buildSectionLabel('📋 Lịch sử điểm', isDark),
                  const SizedBox(height: 12),
                  _buildHistory(isDark),
                  const SizedBox(height: 28),

                  // Recovery missions
                  if (_trust.score < 60) ...[
                    _buildSectionLabel('🎯 Nhiệm vụ phục hồi', isDark),
                    const SizedBox(height: 12),
                    RecoveryMissionCard(score: _trust.score),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader(TrustLevelData levelData, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: levelData.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: VibeAvatar(
                  name: _trust.userName,
                  imageUrl: _trust.userAvatar,
                  size: 72,
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 20),

              // Name + level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🛡️ Hộ chiếu uy tín',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _trust.userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            levelData.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            levelData.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Score circle
              ScoreCircle(score: _trust.score, size: 90, strokeWidth: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        TrustStatCard(
          icon: Icons.celebration_rounded,
          value: '${_trust.eventsJoined}',
          label: 'Sự kiện\nđã tham gia',
          color: const Color(0xFF3B82F6),
        ),
        TrustStatCard(
          icon: Icons.check_circle_outline_rounded,
          value: '${_trust.onTimeCheckins}',
          label: 'Check-in\nđúng giờ',
          color: const Color(0xFF22C55E),
        ),
        TrustStatCard(
          icon: Icons.cancel_outlined,
          value: '${_trust.lastMinuteCancels}',
          label: 'Hủy\nsát giờ',
          color: const Color(0xFFF97316),
        ),
        TrustStatCard(
          icon: Icons.warning_amber_rounded,
          value: '${_trust.noShows}',
          label: 'Leo cây\n(no-show)',
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  // ─── Rating ───────────────────────────────────────────────────────────────

  Widget buildRatingRow(bool isDark) {
    final rating = _trust.avgHostRating;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF1C2C58),
                  ),
                ),
                Text(
                  'Đánh giá trung bình từ host',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Star display
          Column(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = i < rating.floor();
                  final half = !filled && i < rating;
                  return Icon(
                    half
                        ? Icons.star_half_rounded
                        : (filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded),
                    color: const Color(0xFFF59E0B),
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_trust.eventsJoined} lượt',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Badges ───────────────────────────────────────────────────────────────

  Widget _buildBadgesGrid() {
    final badges = TrustBadge.all;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: badges.map((badge) {
        final isEarned = _trust.earnedBadges.contains(badge.type);
        return TrustBadgeChip(badge: badge, isEarned: isEarned);
      }).toList(),
    );
  }

  // ─── History ──────────────────────────────────────────────────────────────

  Widget _buildHistory(bool isDark) {
    final logs = _trust.history.take(6).toList();
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lịch sử',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: logs.asMap().entries.map((entry) {
          final i = entry.key;
          final log = entry.value;
          return _HistoryRow(
            log: log,
            isDark: isDark,
            showDivider: i < logs.length - 1,
          );
        }).toList(),
      ),
    );
  }

  // ─── Restrict Banner ──────────────────────────────────────────────────────

  Widget _buildRestrictBanner(bool isDark) {
    final daysLeft =
        _trust.restrictedUntil!.difference(DateTime.now()).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🚨', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài khoản đang bị hạn chế',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Còn $daysLeft ngày. Không thể đăng ký sự kiện mới.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? Colors.white : const Color(0xFF1C2C58),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cách tính điểm uy tín',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1C2C58),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                _ScoreRule('✅ Check-in đúng giờ', '+5 điểm'),
                _ScoreRule('⏰ Trễ dưới 15 phút', '+2 điểm'),
                _ScoreRule('⭐ Host đánh giá 5 sao', '+5 điểm'),
                _ScoreRule('👍 Host đánh giá 3-4 sao', '+2 điểm'),
                _ScoreRule('❌ Hủy sát giờ', '-5 điểm'),
                _ScoreRule('💀 Không đến, không báo', '-15 điểm'),
                _ScoreRule('👎 Host đánh giá < 3 sao', '-3 điểm'),
              ].map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.action,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        r.points,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: r.points.startsWith('+')
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRule {
  const _ScoreRule(this.action, this.points);
  final String action;
  final String points;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.log,
    required this.isDark,
    required this.showDivider,
  });

  final TrustEventLog log;
  final bool isDark;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isPositive = log.delta > 0;
    final isZero = log.delta == 0;
    final Color deltaColor = isPositive
        ? const Color(0xFF22C55E)
        : (isZero ? const Color(0xFF64748B) : const Color(0xFFEF4444));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : (isZero
                            ? Icons.horizontal_rule_rounded
                            : Icons.trending_down_rounded),
                  color: deltaColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.reason.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C2C58),
                      ),
                    ),
                    Text(
                      log.eventName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Delta + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log.delta == 0
                        ? '±0'
                        : (log.delta > 0 ? '+${log.delta}' : '${log.delta}'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: deltaColor,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM').format(log.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
      ],
    );
  }
}
