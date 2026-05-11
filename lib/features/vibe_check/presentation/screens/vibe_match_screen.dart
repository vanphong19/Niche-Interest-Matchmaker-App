import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/vibe_match_bloc.dart';
import '../bloc/vibe_match_event.dart';
import '../bloc/vibe_match_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/header_section.dart';
import '../widgets/item_tile.dart';
import '../widgets/participants_stack.dart';
import 'group_vibe_screen.dart';
import 'match_details_screen.dart';
import 'user_detail_screen.dart';
import 'vibe_join_summary_screen.dart';

@RoutePage()
class VibeMatchScreen extends StatelessWidget {
  const VibeMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VibeMatchBloc>()..add(const VibeMatchEvent.started()),
      child: ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.localeNotifier,
        builder: (context, localeCode, _) {
          return _VibeMatchView(localeCode: localeCode);
        },
      ),
    );
  }
}

class _VibeMatchView extends StatefulWidget {
  const _VibeMatchView({required this.localeCode});

  final String localeCode;

  @override
  State<_VibeMatchView> createState() => _VibeMatchViewState();
}

class _VibeMatchViewState extends State<_VibeMatchView>
    with TickerProviderStateMixin {
  late final AnimationController _listController;
  late final AnimationController _heroPulseController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _heroPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _VibeMatchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeCode != widget.localeCode) {
      context.read<VibeMatchBloc>().add(const VibeMatchEvent.started());
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    _heroPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VibeMatchBloc, VibeMatchState>(
      listenWhen: (previous, current) => previous.uiAction != current.uiAction,
      listener: (context, state) {
        if (state.uiAction == VibeMatchUiAction.openJoinSummary) {
          Navigator.of(context).push(VibeJoinSummaryScreen.route());
          context.read<VibeMatchBloc>().add(
            const VibeMatchEvent.navigationHandled(),
          );
        }

        if (state.uiAction == VibeMatchUiAction.openUserMatchList) {
          context.router.push(const UserMatchListRoute());
          context.read<VibeMatchBloc>().add(
            const VibeMatchEvent.navigationHandled(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: SafeArea(
          child: BlocBuilder<VibeMatchBloc, VibeMatchState>(
            builder: (context, state) {
              return ResponsiveLayout(
                small: (context, info) => _VibeAdaptiveContent(
                  info: info,
                  state: state,
                  listController: _listController,
                  heroPulse: _heroPulseController,
                  onSettingsPressed: () {
                    context.router.push(const SettingsRoute());
                  },
                  onJoinPressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.primaryPressed(),
                    );
                  },
                  onExplorePressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.secondaryPressed(),
                    );
                  },
                  onGroupVibePressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupVibeScreen(),
                      ),
                    );
                  },
                  onUserDetailPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UserDetailScreen(),
                      ),
                    );
                  },
                  onMatchDetailsPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatchDetailsScreen(),
                      ),
                    );
                  },
                ),
                medium: (context, info) => _VibeAdaptiveContent(
                  info: info,
                  state: state,
                  listController: _listController,
                  heroPulse: _heroPulseController,
                  onSettingsPressed: () {
                    context.router.push(const SettingsRoute());
                  },
                  onJoinPressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.primaryPressed(),
                    );
                  },
                  onExplorePressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.secondaryPressed(),
                    );
                  },
                  onGroupVibePressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupVibeScreen(),
                      ),
                    );
                  },
                  onUserDetailPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UserDetailScreen(),
                      ),
                    );
                  },
                  onMatchDetailsPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatchDetailsScreen(),
                      ),
                    );
                  },
                ),
                large: (context, info) => _VibeAdaptiveContent(
                  info: info,
                  state: state,
                  listController: _listController,
                  heroPulse: _heroPulseController,
                  onSettingsPressed: () {
                    context.router.push(const SettingsRoute());
                  },
                  onJoinPressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.primaryPressed(),
                    );
                  },
                  onExplorePressed: () {
                    context.read<VibeMatchBloc>().add(
                      const VibeMatchEvent.secondaryPressed(),
                    );
                  },
                  onGroupVibePressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupVibeScreen(),
                      ),
                    );
                  },
                  onUserDetailPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UserDetailScreen(),
                      ),
                    );
                  },
                  onMatchDetailsPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatchDetailsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VibeAdaptiveContent extends StatelessWidget {
  const _VibeAdaptiveContent({
    required this.info,
    required this.state,
    required this.listController,
    required this.heroPulse,
    required this.onSettingsPressed,
    required this.onJoinPressed,
    required this.onExplorePressed,
    required this.onGroupVibePressed,
    required this.onUserDetailPressed,
    required this.onMatchDetailsPressed,
  });

  final ResponsiveInfo info;
  final VibeMatchState state;
  final Animation<double> listController;
  final Animation<double> heroPulse;
  final VoidCallback onSettingsPressed;
  final VoidCallback onJoinPressed;
  final VoidCallback onExplorePressed;
  final VoidCallback onGroupVibePressed;
  final VoidCallback onUserDetailPressed;
  final VoidCallback onMatchDetailsPressed;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = (info.width * 0.04).clamp(12.0, 34.0);
    final verticalPadding = (info.width * 0.04).clamp(12.0, 28.0);
    final cardPadding = EdgeInsets.all((info.width * 0.05).clamp(16.0, 26.0));

    if (info.isLarge) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          110,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeaderSection(
                      title: AppLocalizations.tr('vibe_match_title'),
                      onSettingsPressed: onSettingsPressed,
                    ),
                    _ScoreSection(
                      score: state.matchScore,
                      title: state.headerTitle,
                      subtitle: state.headerSubtitle,
                      pulse: heroPulse,
                    ),
                    SizedBox(height: (info.width * 0.04).clamp(16.0, 26.0)),
                    AppButton(
                      label: AppLocalizations.tr('vibe_match_join_event'),
                      icon: Icons.rocket_launch,
                      onPressed: onJoinPressed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: AppLocalizations.tr('vibe_match_explore_matches'),
                      filled: false,
                      icon: Icons.travel_explore,
                      onPressed: onExplorePressed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Open Group Vibe',
                      icon: Icons.diversity_3,
                      onPressed: onGroupVibePressed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Open User Detail',
                      filled: false,
                      icon: Icons.person,
                      onPressed: onUserDetailPressed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Open Match Details',
                      filled: false,
                      icon: Icons.analytics_outlined,
                      onPressed: onMatchDetailsPressed,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: (info.width * 0.03).clamp(12.0, 24.0)),
            Expanded(
              flex: 12,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppCard(
                      padding: cardPadding,
                      child: _MatchReasonSection(
                        reasons: state.reasons,
                        listController: listController,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      padding: cardPadding,
                      onTap: () {},
                      child: _GroupSummarySection(
                        summary: state.groupSummary,
                        attendeesCount: state.attendeesCount,
                        participantImages: state.participantImages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final maxWidth = math.min(info.width, 720.0);

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: maxWidth,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                110,
              ),
              sliver: SliverList.list(
                children: [
                  HeaderSection(
                    title: AppLocalizations.tr('vibe_match_title'),
                    onSettingsPressed: onSettingsPressed,
                  ),
                  _ScoreSection(
                    score: state.matchScore,
                    title: state.headerTitle,
                    subtitle: state.headerSubtitle,
                    pulse: heroPulse,
                  ),
                  SizedBox(height: (info.width * 0.05).clamp(16.0, 26.0)),
                  AppCard(
                    padding: cardPadding,
                    child: _MatchReasonSection(
                      reasons: state.reasons,
                      listController: listController,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: cardPadding,
                    onTap: () {},
                    child: _GroupSummarySection(
                      summary: state.groupSummary,
                      attendeesCount: state.attendeesCount,
                      participantImages: state.participantImages,
                    ),
                  ),
                  SizedBox(height: (info.width * 0.05).clamp(18.0, 28.0)),
                  AppButton(
                    label: AppLocalizations.tr('vibe_match_join_event'),
                    icon: Icons.rocket_launch,
                    onPressed: onJoinPressed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: AppLocalizations.tr('vibe_match_explore_matches'),
                    filled: false,
                    icon: Icons.travel_explore,
                    onPressed: onExplorePressed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Open Group Vibe',
                    icon: Icons.diversity_3,
                    onPressed: onGroupVibePressed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Open User Detail',
                    filled: false,
                    icon: Icons.person,
                    onPressed: onUserDetailPressed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Open Match Details',
                    filled: false,
                    icon: Icons.analytics_outlined,
                    onPressed: onMatchDetailsPressed,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({
    required this.score,
    required this.title,
    required this.subtitle,
    required this.pulse,
  });

  final int score;
  final String title;
  final String subtitle;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final outerSize = ResponsiveValue<double>(
          verySmall: 150,
          small: 176,
          medium: 206,
          large: 220,
        ).resolve(width);
        final ringSize = outerSize * 0.8;
        final centerSize = outerSize * 0.73;

        return Column(
          children: [
            SizedBox(
              width: outerSize,
              height: outerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) {
                      final spread = 8 + (pulse.value * 8);
                      return Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accentLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 32,
                              spreadRadius: spread,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    width: centerSize,
                    height: centerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgPrimary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: score.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              '${value.toInt()}%',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: ResponsiveValue<double>(
                                  verySmall: 24,
                                  small: 28,
                                  medium: 31,
                                  large: 32,
                                ).resolve(width),
                              ),
                            );
                          },
                        ),
                        Text(
                          AppLocalizations.tr('vibe_match_label'),
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: ResponsiveValue<double>(
                  verySmall: 22,
                  small: 24,
                  medium: 26,
                  large: 28,
                ).resolve(width),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: ResponsiveValue<double>(
                  verySmall: 13,
                  small: 14,
                  medium: 15,
                  large: 15,
                ).resolve(width),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

class _MatchReasonSection extends StatelessWidget {
  const _MatchReasonSection({
    required this.reasons,
    required this.listController,
  });

  final List<MatchReason> reasons;
  final Animation<double> listController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr('vibe_match_why'),
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm + 2,
          runSpacing: AppSpacing.sm + 2,
          children: [
            for (int i = 0; i < reasons.length; i++)
              _AnimatedReasonTile(
                index: i,
                total: reasons.length,
                progress: listController,
                reason: reasons[i],
              ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedReasonTile extends StatelessWidget {
  const _AnimatedReasonTile({
    required this.index,
    required this.total,
    required this.progress,
    required this.reason,
  });

  final int index;
  final int total;
  final Animation<double> progress;
  final MatchReason reason;

  @override
  Widget build(BuildContext context) {
    final start = (index / total) * 0.55;
    final end = math.min(1.0, start + 0.4);
    final interval = CurvedAnimation(
      parent: progress,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: interval,
      builder: (_, child) {
        final opacity = interval.value;
        final slideY = (1 - interval.value) * 12;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, slideY), child: child),
        );
      },
      child: ItemTile(
        icon: reason.icon,
        label: AppLocalizations.tr(reason.label),
        highlighted: reason.highlighted,
      ),
    );
  }
}

class _GroupSummarySection extends StatelessWidget {
  const _GroupSummarySection({
    required this.summary,
    required this.attendeesCount,
    required this.participantImages,
  });

  final String summary;
  final int attendeesCount;
  final List<String> participantImages;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tightLayout = width <= 420;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.tr('vibe_match_summary_title'),
              style: AppTextStyles.headingSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: tightLayout ? 5 : 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              runSpacing: AppSpacing.sm,
              spacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: tightLayout ? width : width * 0.5,
                  ),
                  child: Text(
                    '$attendeesCount ${AppLocalizations.tr('vibe_match_going')}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ParticipantsStack(
                  imageUrls: participantImages,
                  extraCount: math.max(
                    0,
                    attendeesCount - participantImages.length,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
