import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/i18n.dart';
import '../../models/insights_overview.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/stat_card.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  InsightsOverview _data = InsightsOverview.empty();
  bool _loading = true;
  String? _error;
  // null = all children (the default); otherwise the child whose stats we're
  // scoped to. Stays across rebuilds so chip selection persists.
  String? _selectedChildId;

  static const _moodEmoji = {
    'happy': '😊',
    'calm': '😌',
    'curious': '🤔',
    'sleepy': '😴',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ApiResponse resp = await DatabaseService.getInsightsOverview(
      childId: _selectedChildId,
    );
    if (!mounted) return;
    if (resp.success && resp.data is InsightsOverview) {
      setState(() {
        _data = resp.data as InsightsOverview;
        _loading = false;
      });
    } else {
      setState(() {
        _data = InsightsOverview.empty();
        _error = resp.message;
        _loading = false;
      });
    }
  }

  void _selectChild(String? childId) {
    if (_selectedChildId == childId) return;
    setState(() => _selectedChildId = childId);
    _load();
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String _formatAvg(double minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 1) return '<1m';
    return '${minutes.toStringAsFixed(minutes >= 10 ? 0 : 1)}m';
  }

  String _moodLabel(BuildContext context, String? mood) {
    if (mood == null) return '—';
    return context.tr('insights.mood.$mood');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            context.tr('insights.title'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('insights.subtitle'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _ChildScopeSelector(
            selectedChildId: _selectedChildId,
            onSelect: _selectChild,
            viewingLabel: context.tr('insights.viewing'),
            allLabel: context.tr('insights.viewing_all'),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: context.tr('insights.load_error_title'),
              subtitle: context.tr('insights.load_error_body'),
              iconBackground: AppColors.softPeach,
              iconColor: AppColors.warning,
            )
          else if (_data.totalSessions == 0)
            EmptyState(
              icon: Icons.insights_rounded,
              title: context.tr('insights.empty_title'),
              subtitle: context.tr('insights.empty_body'),
              iconBackground: AppColors.iconCircleGreen,
              iconColor: AppColors.success,
            )
          else ...[
            _buildOverviewGrid(context),
            const SizedBox(height: 20),
            _SectionHeader(
              title: context.tr('insights.this_week'),
              subtitle: context.tr('insights.this_week_sub'),
            ),
            const SizedBox(height: 10),
            SoftCard(
              child: _WeekChart(
                days: _data.lastSevenDays,
                minutesShort: context.tr('insights.minutes_short'),
              ),
            ),
            if (_hasMoodData) ...[
              const SizedBox(height: 20),
              _SectionHeader(title: context.tr('insights.mood_breakdown')),
              const SizedBox(height: 10),
              SoftCard(
                child: _MoodBreakdown(
                  breakdown: _data.moodBreakdown,
                  label: (m) => _moodLabel(context, m),
                ),
              ),
            ],
            if (_data.topStories.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                title: context.tr('insights.top_stories'),
                subtitle: context.tr('insights.top_stories_sub'),
              ),
              const SizedBox(height: 10),
              SoftCard(
                child: _TopStoriesList(
                  stories: _data.topStories,
                  minutesShort: context.tr('insights.minutes_short'),
                  playsShort: context.tr('insights.plays_short'),
                ),
              ),
            ],
            if (_data.recentSessions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                title: context.tr('insights.recent_activity'),
                subtitle: context.tr('insights.recent_activity_sub'),
              ),
              const SizedBox(height: 10),
              SoftCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: _RecentList(
                  sessions: _data.recentSessions,
                  completedLabel:
                      context.tr('insights.completed_badge'),
                  leftOffLabel: context.tr('insights.left_off_badge'),
                  minutesShort: context.tr('insights.minutes_short'),
                  moodLabel: (m) => _moodLabel(context, m),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _SectionHeader(title: context.tr('insights.per_child')),
            const SizedBox(height: 10),
            for (final c in _data.children) ...[
              _ChildInsightCard(
                child: c,
                minutesLabel: _formatMinutes(c.listeningMinutes),
                avgLabel: _formatAvg(c.avgSessionMinutes),
                moodEmoji: _moodEmoji[c.topMood],
                moodLabel: _moodLabel(context, c.topMood),
                streakDaysShort: context.tr('insights.streak_days_short'),
                completionLabel: context.tr('insights.completion'),
                finishedLabel: context.tr('insights.finished'),
                genreLabel: context.tr('insights.genre'),
                avgLabelText: context.tr('insights.avg_session'),
                streakLabelText: context.tr('insights.streak'),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context) {
    final cards = <_StatSpec>[
      _StatSpec(
        icon: Icons.headphones,
        iconBackground: AppColors.iconCircleBlue,
        value: _formatMinutes(_data.totalListeningMinutes),
        label: context.tr('insights.total_minutes'),
      ),
      _StatSpec(
        icon: Icons.play_circle_outline,
        iconBackground: AppColors.iconCircleGreen,
        value: '${_data.totalSessions}',
        label: context.tr('insights.total_sessions'),
      ),
      _StatSpec(
        icon: Icons.task_alt,
        iconBackground: AppColors.iconCirclePeach,
        value: '${_data.completionRate}%',
        label: context.tr('insights.stories_completed'),
      ),
      _StatSpec(
        icon: Icons.emoji_emotions_outlined,
        iconBackground: AppColors.iconCirclePurple,
        value: _data.topMood != null
            ? '${_moodEmoji[_data.topMood] ?? ''} ${_moodLabel(context, _data.topMood)}'
            : '—',
        label: context.tr('insights.top_mood'),
      ),
      _StatSpec(
        icon: Icons.access_time_rounded,
        iconBackground: AppColors.softMint,
        value: _formatAvg(_data.avgSessionMinutes),
        label: context.tr('insights.avg_session'),
      ),
      _StatSpec(
        icon: Icons.local_fire_department_rounded,
        iconBackground: AppColors.softPeach,
        value:
            '${_data.streakDays}${context.tr('insights.streak_days_short')}',
        label: context.tr('insights.streak'),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: cards
          .map((s) => StatCard(
                icon: s.icon,
                iconBackground: s.iconBackground,
                value: s.value,
                label: s.label,
              ))
          .toList(),
    );
  }

  bool get _hasMoodData => _data.moodBreakdown.values.any((v) => v > 0);
}

/// Horizontal child-scope selector — "All children" + one chip per child.
/// Tapping a chip refetches the insights for just that child.
class _ChildScopeSelector extends StatelessWidget {
  final String? selectedChildId;
  final void Function(String? childId) onSelect;
  final String viewingLabel;
  final String allLabel;
  const _ChildScopeSelector({
    required this.selectedChildId,
    required this.onSelect,
    required this.viewingLabel,
    required this.allLabel,
  });

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesState>().profiles;
    if (profiles.isEmpty) return const SizedBox.shrink();
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(viewingLabel,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ScopeChip(
                  emoji: '👨‍👩‍👧',
                  label: allLabel,
                  color: AppColors.iconCircleBlue,
                  selected: selectedChildId == null,
                  onTap: () => onSelect(null),
                ),
                const SizedBox(width: 8),
                for (final p in profiles) ...[
                  _ScopeChip(
                    emoji: p.avatarEmoji,
                    label: p.name,
                    color: p.avatarColor,
                    selected: selectedChildId == p.childId,
                    onTap: () => onSelect(p.childId),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlueDark
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSpec {
  final IconData icon;
  final Color iconBackground;
  final String value;
  final String label;
  const _StatSpec({
    required this.icon,
    required this.iconBackground,
    required this.value,
    required this.label,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ],
    );
  }
}

/// Small bar chart of the last 7 days' listening minutes.
class _WeekChart extends StatelessWidget {
  final List<DayMinutes> days;
  final String minutesShort;
  const _WeekChart({required this.days, required this.minutesShort});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(context.tr('insights.no_activity'),
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    final maxMinutes = days
        .map((d) => d.minutes)
        .fold<int>(0, (a, b) => b > a ? b : a)
        .clamp(1, 1 << 30);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final frac = d.minutes / maxMinutes;
          final isToday = d == days.last;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.minutes == 0 ? '' : '${d.minutes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Bar — grows from the bottom.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final height = (c.maxHeight * frac).clamp(2.0, c.maxHeight);
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: height,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primaryBlueDark
                                  : AppColors.primaryBlue,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MoodBreakdown extends StatelessWidget {
  final Map<String, int> breakdown;
  final String Function(String) label;
  const _MoodBreakdown({required this.breakdown, required this.label});

  static const _order = ['happy', 'calm', 'curious', 'sleepy'];
  static const _emoji = {
    'happy': '😊',
    'calm': '😌',
    'curious': '🤔',
    'sleepy': '😴',
  };
  static const _color = {
    'happy': AppColors.moodHappy,
    'calm': AppColors.moodCalm,
    'curious': AppColors.moodCurious,
    'sleepy': AppColors.moodSleepy,
  };

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);
    return Column(
      children: _order.map((mood) {
        final count = breakdown[mood] ?? 0;
        final fraction = total == 0 ? 0.0 : count / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(_emoji[mood] ?? '', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                child: Text(
                  label(mood),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.background,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_color[mood]!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopStoriesList extends StatelessWidget {
  final List<TopStory> stories;
  final String minutesShort;
  final String playsShort;
  const _TopStoriesList({
    required this.stories,
    required this.minutesShort,
    required this.playsShort,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stories.length, (i) {
        final s = stories[i];
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlueDark,
                    fontSize: 18,
                  ),
                ),
              ),
              _CoverThumb(url: s.coverImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.minutes} $minutesShort • ${s.plays} $playsShort',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<RecentSession> sessions;
  final String completedLabel;
  final String leftOffLabel;
  final String minutesShort;
  final String Function(String) moodLabel;
  const _RecentList({
    required this.sessions,
    required this.completedLabel,
    required this.leftOffLabel,
    required this.minutesShort,
    required this.moodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < sessions.length; i++) ...[
          _RecentTile(
            session: sessions[i],
            completedLabel: completedLabel,
            leftOffLabel: leftOffLabel,
            minutesShort: minutesShort,
            moodLabel: moodLabel,
          ),
          if (i != sessions.length - 1)
            const Divider(height: 18, color: AppColors.cardBorder),
        ],
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final RecentSession session;
  final String completedLabel;
  final String leftOffLabel;
  final String minutesShort;
  final String Function(String) moodLabel;
  const _RecentTile({
    required this.session,
    required this.completedLabel,
    required this.leftOffLabel,
    required this.minutesShort,
    required this.moodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final completed = session.completed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Child avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: session.childColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(session.childEmoji,
              style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.childName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 1),
              Text(
                session.audiobookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniChip(
                    icon: Icons.access_time,
                    text: '${session.durationMinutes} $minutesShort',
                  ),
                  _MiniChip(
                    icon: completed
                        ? Icons.check_circle_outline
                        : Icons.adjust_rounded,
                    text: completed ? completedLabel : leftOffLabel,
                    color: completed
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  if (session.mood != null)
                    _MiniChip(
                      icon: Icons.emoji_emotions_outlined,
                      text: moodLabel(session.mood!),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _shortWhen(session.at),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _shortWhen(String iso) {
    // "2026-05-29 13:14" → "May 29, 13:14"; keeps it compact in the trailing slot.
    try {
      final parts = iso.split(' ');
      if (parts.length != 2) return iso;
      final date = DateTime.parse('${parts[0]}T${parts[1]}:00');
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${parts[1]}';
    } catch (_) {
      return iso;
    }
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MiniChip({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final String? url;
  const _CoverThumb({this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.softLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book_outlined,
          size: 18, color: AppColors.textPrimary),
    );
    final src = url;
    if (src == null || src.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        src,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        cacheWidth: 120,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _ChildInsightCard extends StatelessWidget {
  final ChildInsight child;
  final String minutesLabel;
  final String avgLabel;
  final String? moodEmoji;
  final String moodLabel;
  final String streakDaysShort;
  final String completionLabel;
  final String finishedLabel;
  final String genreLabel;
  final String avgLabelText;
  final String streakLabelText;

  const _ChildInsightCard({
    required this.child,
    required this.minutesLabel,
    required this.avgLabel,
    required this.moodEmoji,
    required this.moodLabel,
    required this.streakDaysShort,
    required this.completionLabel,
    required this.finishedLabel,
    required this.genreLabel,
    required this.avgLabelText,
    required this.streakLabelText,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: child.avatarColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(child.avatarEmoji,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '$minutesLabel • ${child.sessions} session${child.sessions == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (child.topMood != null)
                _Badge(
                  label: '${moodEmoji ?? ''} $moodLabel',
                  color: AppColors.iconCirclePurple,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: completionLabel,
                  value: '${child.completionRate}%',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: finishedLabel,
                  value: '${child.completed}/${child.sessions}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: avgLabelText.replaceAll('\n', ' '),
                  value: avgLabel,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: streakLabelText.replaceAll('\n', ' '),
                  value: '${child.streakDays}$streakDaysShort',
                ),
              ),
            ],
          ),
          if ((child.favoriteGenre ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$genreLabel: ${child.favoriteGenre}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
