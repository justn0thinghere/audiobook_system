import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/child_profile.dart';
import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import '../child/child_shell.dart';
import 'add_child_dialog.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  void _enterChildMode(BuildContext context, ChildProfile profile) {
    context.read<ProfilesState>().enterChildMode(profile);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChildShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesState>().profiles;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Child Profiles',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Child'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddChildDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final p in profiles) ...[
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: p.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Age ${p.age} • ${p.favoriteGenre}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('${p.listeningMinutes} min listened',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _enterChildMode(context, p),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enter',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
