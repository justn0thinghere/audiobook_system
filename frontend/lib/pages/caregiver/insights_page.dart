import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/stat_card.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesState>().profiles;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Insights',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sensory patterns and engagement reports',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: const [
            StatCard(icon: Icons.show_chart, iconBackground: AppColors.iconCircleGreen, value: '+12%', label: 'Engagement\nthis week'),
            StatCard(icon: Icons.bedtime_outlined, iconBackground: AppColors.iconCirclePurple, value: '2', label: 'Sensory\ntriggers softened'),
            StatCard(icon: Icons.headphones, iconBackground: AppColors.iconCircleBlue, value: '5h 12m', label: 'Total listening\nthis week'),
            StatCard(icon: Icons.emoji_emotions_outlined, iconBackground: AppColors.iconCirclePeach, value: 'Calm', label: 'Most-felt mood'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Per-child summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final p in profiles) ...[
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: p.avatarColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${p.listeningMinutes} min • ${p.favoriteGenre}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                _Badge(label: 'Stable', color: AppColors.iconCircleGreen),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
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
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
