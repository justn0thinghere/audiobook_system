import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/i18n.dart';
import '../../models/content_item.dart';
import '../../services/database_service.dart';
import '../../state/profiles_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
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
  // Once the child has picked a mood today it stays locked until the next
  // calendar day. Stored in SharedPreferences per (child_id, YYYY-MM-DD) so
  // the lock survives app restarts and releases automatically at midnight.
  bool _moodLockedForToday = false;
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
    _loadTodayMood();
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

  /// SharedPreferences key for today's mood for [childId]. Date format is the
  /// device's local calendar day so a child who taps at 11 PM sees the
  /// selector unlock at midnight rather than 24 hours later.
  String _todayMoodKey(String childId) {
    final now = DateTime.now();
    final ymd = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'mood_${childId}_$ymd';
  }

  /// Restore today's mood from disk on page open so the lock survives a
  /// child-mode exit / re-entry within the same day.
  Future<void> _loadTodayMood() async {
    final profile = context.read<ProfilesState>().activeProfile;
    if (profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_todayMoodKey(profile.childId));
    if (saved == null || !mounted) return;
    setState(() {
      _selectedMood = saved;
      _moodLockedForToday = true;
    });
    // Make sure the next listening session still picks up the mood the child
    // chose earlier today (ProfilesState resets on enterChildMode).
    if (!mounted) return;
    context.read<ProfilesState>().setMood(saved);
  }

  /// Persist today's mood for [childId]. Safe to call multiple times — it
  /// overwrites the existing key (but the UI lock prevents that from
  /// happening within a single calendar day).
  Future<void> _saveMoodForToday(String childId, String moodId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayMoodKey(childId), moodId);
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
                  // Non-selected cards fade back once the lock is on so the
                  // child can still see what they chose but not be tempted to
                  // tap the others. Locked + selected stays at full opacity.
                  final dimmed = _moodLockedForToday && !selected;
                  return InkWell(
                    onTap: () {
                      if (_moodLockedForToday) {
                        // Already chose today — explain why nothing happens
                        // when they tap a different mood card.
                        final chosen = _selectedMood;
                        if (chosen != null) {
                          final chosenLabel = _moods
                              .firstWhere((x) => x.id == chosen)
                              .labelKey;
                          AppSnackbar.info(
                            context
                                .trRead('child.mood_locked')
                                .replaceAll('{mood}',
                                    context.trRead(chosenLabel)),
                            context: context,
                          );
                        }
                        return;
                      }
                      final childId = context
                          .read<ProfilesState>()
                          .activeProfile
                          ?.childId;
                      setState(() {
                        _selectedMood = m.id;
                        _moodLockedForToday = true;
                      });
                      context.read<ProfilesState>().setMood(m.id);
                      if (childId != null) _saveMoodForToday(childId, m.id);
                      AppSnackbar.success(
                        context.trRead('child.mood_saved').replaceAll(
                            '{mood}', context.trRead(m.labelKey)),
                        context: context,
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: dimmed ? 0.4 : 1.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: selected ? 1.04 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: m.color,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? AppColors.textPrimary
                                  : Colors.transparent,
                              // Thicker border on tap so the selection reads
                              // at a glance even at arm's length on a phone.
                              width: selected ? 4 : 0,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(m.emoji,
                                        style:
                                            const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 4),
                                    Text(context.tr(m.labelKey),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
          _StartStoryCard(
            story: _featured!,
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AudioPlayerPage(
                title: _featured!.title,
                audiobookId: _featured!.audiobookId,
              ),
            )),
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

/// Big "Today's pick" call-to-action on the child home. Solid gradient
/// background, solid white start button — no translucent pills, no pulsing
/// glow shadows. Those were what made the text look soft in the earlier
/// version: semi-transparent backgrounds don't antialias text sharply, and
/// a glow expanding behind the button blurs whatever's near it.
class _StartStoryCard extends StatelessWidget {
  final ContentItem story;
  final VoidCallback onStart;
  const _StartStoryCard({required this.story, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "TODAY'S PICK" label — plain white text, no translucent pill.
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('child.featured').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Cover thumbnail + story title.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StartStoryCover(url: story.coverImage),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Solid white start button — full width, centered, no glow.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        size: 28, color: AppColors.primaryBlueDark),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('child.start_story'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square cover thumbnail next to the title. Falls back to a soft pastel
/// book glyph when the story has no cover yet (e.g. AI generation still
/// running). Solid colors only — no translucent borders to soften the
/// edges.
class _StartStoryCover extends StatelessWidget {
  final String? url;
  const _StartStoryCover({this.url});

  @override
  Widget build(BuildContext context) {
    final src = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 70,
        height: 70,
        child: (src != null && src.isNotEmpty)
            ? Image.network(
                src,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.softLavender,
        alignment: Alignment.center,
        child: const Icon(Icons.menu_book_rounded,
            color: AppColors.textPrimary, size: 30),
      );
}
