import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/i18n.dart';
import '../../models/content_item.dart';
import '../../services/database_service.dart';
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
  ContentItem? _featured;

  // Mood `labelKey` is a translation key; resolved at render via context.tr().
  static const List<_Mood> _moods = [
    _Mood('happy', 'child.mood_happy', '😊', AppColors.moodHappy),
    _Mood('calm', 'child.mood_calm', '😌', AppColors.moodCalm),
    _Mood('curious', 'child.mood_curious', '🤔', AppColors.moodCurious),
    _Mood('sleepy', 'child.mood_sleepy', '😴', AppColors.moodSleepy),
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final resp = await DatabaseService.getContentList();
    if (!mounted) return;
    if (resp.success && resp.data is List<ContentItem>) {
      final items = resp.data as List<ContentItem>;
      // Only feature a finished book (skip ones still generating pictures).
      final ready = items.where((i) => i.status != 'processing').toList();
      setState(() => _featured = ready.isNotEmpty ? ready.first : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfilesState>().activeProfile;
    final name = profile?.name ?? context.tr('child.default_name');
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
              Center(
                child: Text(
                  context.tr('child.mood_question'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
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
                    onTap: () {
                      setState(() => _selectedMood = m.id);
                      context.read<ProfilesState>().setMood(m.id);
                    },
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
                          Text(context.tr(m.labelKey),
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

        if (_featured != null) ...[
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AudioPlayerPage(
                title: _featured!.title,
                audiobookId: _featured!.audiobookId,
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
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 38),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('child.start_story'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _featured!.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('child.browse_library'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(context.tr('child.browse_library_sub'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
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
  /// Translation key for the mood label.
  final String labelKey;
  final String emoji;
  final Color color;
  const _Mood(this.id, this.labelKey, this.emoji, this.color);
}
