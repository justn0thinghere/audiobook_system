import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import 'audio_player_page.dart';
import 'story_library_page.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  String? _selectedMood;

  static const List<_Mood> _moods = [
    _Mood('happy', 'Happy', '😊', AppColors.moodHappy),
    _Mood('calm', 'Calm', '😌', AppColors.moodCalm),
    _Mood('curious', 'Curious', '🤔', AppColors.moodCurious),
    _Mood('sleepy', 'Sleepy', '😴', AppColors.moodSleepy),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfilesState>().activeProfile;
    final name = profile?.name ?? 'Friend';
    final emoji = profile?.avatarEmoji ?? '🌸';
    final avatarColor = profile?.avatarColor ?? AppColors.softPink;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌅 ', style: TextStyle(fontSize: 24)),
            Text(
              '$name!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: _moods.map((m) {
                  final selected = _selectedMood == m.id;
                  return InkWell(
                    onTap: () => setState(() => _selectedMood = m.id),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 4),
                          Text(m.label,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AudioPlayerPage(
              title: 'The Gentle Dragon',
              audiobookId: null,
            ),
          )),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 38),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Continue Listening',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'The Gentle Dragon — Chapter 1',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        SoftCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoryLibraryPage()),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.softMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_outlined),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browse Story Library',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Find a new favorite story',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mood {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  const _Mood(this.id, this.label, this.emoji, this.color);
}
