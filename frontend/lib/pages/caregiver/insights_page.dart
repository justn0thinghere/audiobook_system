import 'package:flutter/material.dart';

import '../../models/insights_overview.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
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
    final ApiResponse resp = await DatabaseService.getInsightsOverview();
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

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String _moodLabel(String? mood) {
    if (mood == null) return '—';
    return mood[0].toUpperCase() + mood.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Insights',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Listening activity and engagement reports',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load insights',
              subtitle: 'Pull down to try again.',
              iconBackground: AppColors.softPeach,
              iconColor: AppColors.warning,
            )
          else if (_data.totalSessions == 0)
            EmptyState(
              icon: Icons.insights_rounded,
              title: 'No listening activity yet',
              subtitle:
                  'Enter Child Mode and play a story.\nInsights will appear here afterwards.',
              iconBackground: AppColors.iconCircleGreen,
              iconColor: AppColors.success,
            )
          else ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                StatCard(
                  icon: Icons.headphones,
                  iconBackground: AppColors.iconCircleBlue,
                  value: _formatMinutes(_data.totalListeningMinutes),
                  label: 'Total listening\ntime',
                ),
                StatCard(
                  icon: Icons.play_circle_outline,
                  iconBackground: AppColors.iconCircleGreen,
                  value: '${_data.totalSessions}',
                  label: 'Listening\nsessions',
                ),
                StatCard(
                  icon: Icons.task_alt,
                  iconBackground: AppColors.iconCirclePeach,
                  value: '${_data.completionRate}%',
                  label: 'Stories\ncompleted',
                ),
                StatCard(
                  icon: Icons.emoji_emotions_outlined,
                  iconBackground: AppColors.iconCirclePurple,
                  value: _data.topMood != null
                      ? '${_moodEmoji[_data.topMood] ?? ''} ${_moodLabel(_data.topMood)}'
                      : '—',
                  label: 'Most-felt\nmood',
                ),
              ],
            ),
            if (_hasMoodData) ...[
              const SizedBox(height: 20),
              const Text(
                'Mood breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SoftCard(child: _MoodBreakdown(breakdown: _data.moodBreakdown)),
            ],
            const SizedBox(height: 20),
            const Text(
              'Per-child summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final c in _data.children) ...[
              _ChildInsightCard(
                child: c,
                minutesLabel: _formatMinutes(c.listeningMinutes),
                moodEmoji: _moodEmoji[c.topMood],
                moodLabel: _moodLabel(c.topMood),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  bool get _hasMoodData =>
      _data.moodBreakdown.values.any((v) => v > 0);
}

class _MoodBreakdown extends StatelessWidget {
  final Map<String, int> breakdown;
  const _MoodBreakdown({required this.breakdown});

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
                width: 64,
                child: Text(
                  mood[0].toUpperCase() + mood.substring(1),
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

class _ChildInsightCard extends StatelessWidget {
  final ChildInsight child;
  final String minutesLabel;
  final String? moodEmoji;
  final String moodLabel;

  const _ChildInsightCard({
    required this.child,
    required this.minutesLabel,
    required this.moodEmoji,
    required this.moodLabel,
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
                      '$minutesLabel listened • ${child.sessions} session${child.sessions == 1 ? '' : 's'}',
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
                  label: 'Completion',
                  value: '${child.completionRate}%',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Finished',
                  value: '${child.completed}/${child.sessions}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Genre',
                  value: child.favoriteGenre ?? '—',
                ),
              ),
            ],
          ),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
