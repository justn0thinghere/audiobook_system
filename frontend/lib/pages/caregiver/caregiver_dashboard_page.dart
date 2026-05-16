import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/child_profile.dart';
import '../../state/auth_state.dart';
import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/stat_card.dart';
import '../child/child_shell.dart';
import 'add_child_dialog.dart';

class CaregiverDashboardPage extends StatelessWidget {
  final ValueChanged<int>? onJumpToTab;
  const CaregiverDashboardPage({super.key, this.onJumpToTab});

  void _enterChildMode(BuildContext context, ChildProfile profile) {
    context.read<ProfilesState>().enterChildMode(profile);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChildShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Caregiver\nDashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const _LogoutDialog(),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage profiles and monitor learning progress',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: [
            StatCard(
              icon: Icons.people_outline,
              iconBackground: AppColors.iconCircleBlue,
              value: '${profiles.totalChildren}',
              label: 'Total Children',
            ),
            StatCard(
              icon: Icons.access_time,
              iconBackground: AppColors.iconCircleGreen,
              value: '${profiles.totalListeningMinutes}',
              label: 'Total Listening\nMinutes',
            ),
            const StatCard(
              icon: Icons.menu_book_outlined,
              iconBackground: AppColors.iconCirclePeach,
              value: '6',
              label: 'Total\nAudiobooks',
            ),
            StatCard(
              icon: Icons.psychology_outlined,
              iconBackground: AppColors.iconCirclePurple,
              value: '${profiles.averageEngagement}%',
              label: 'Average\nEngagement',
            ),
          ],
        ),

        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Child Profiles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddChildDialog(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Child'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (final profile in profiles.profiles) ...[
          _ChildProfileCard(
            profile: profile,
            onEnterChildMode: () => _enterChildMode(context, profile),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  final ChildProfile profile;
  final VoidCallback onEnterChildMode;
  const _ChildProfileCard({required this.profile, required this.onEnterChildMode});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: profile.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Age ${profile.age}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.iconCircleBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Listening time:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              Text(
                '${profile.listeningMinutes} min',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Favorite genre:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              Text(
                profile.favoriteGenre ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEnterChildMode,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Enter Child Mode',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Logout?'),
      content: const Text('You can sign back in at any time.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            await context.read<AuthState>().logout();
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
