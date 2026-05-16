import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';
import 'audio_player_page.dart';

class _Story {
  final String id;
  final String title;
  final String category;
  final String ageRange;
  final Color color;
  final String emoji;
  const _Story(
    this.id,
    this.title,
    this.category,
    this.ageRange,
    this.color,
    this.emoji,
  );
}

class _CategoryFilter {
  final String label;
  final String value;
  final IconData icon;
  const _CategoryFilter(this.label, this.value, this.icon);
}

class StoryLibraryPage extends StatefulWidget {
  const StoryLibraryPage({super.key});

  @override
  State<StoryLibraryPage> createState() => _StoryLibraryPageState();
}

class _StoryLibraryPageState extends State<StoryLibraryPage> {
  final _searchCtrl = TextEditingController();
  String _category = 'all';
  String _ageRange = 'all';
  bool _filtersOpen = true;

  static const _filters = [
    _CategoryFilter('All', 'all', Icons.menu_book_outlined),
    _CategoryFilter('Fantasy', 'fantasy', Icons.auto_awesome),
    _CategoryFilter('Animals', 'animals', Icons.pets),
    _CategoryFilter('Nature', 'nature', Icons.eco_outlined),
    _CategoryFilter('Adventure', 'adventure', Icons.flag_outlined),
    _CategoryFilter('Science', 'science', Icons.science_outlined),
  ];

  static const _ageRanges = ['all', '7-9', '8-11', '9-12'];

  static const _stories = <_Story>[
    _Story(
      '1',
      'The Gentle Dragon',
      'fantasy',
      '7-9',
      AppColors.softLavender,
      '🐉',
    ),
    _Story('2', 'Forest Friends', 'animals', '7-9', AppColors.softMint, '🦊'),
    _Story(
      '3',
      'Stargazer Sophie',
      'nature',
      '8-11',
      AppColors.softYellow,
      '🌟',
    ),
    _Story(
      '4',
      'Brave Little Boat',
      'adventure',
      '8-11',
      AppColors.softPeach,
      '⛵',
    ),
    _Story(
      '5',
      'Tiny Robot Friend',
      'science',
      '9-12',
      AppColors.iconCircleBlue,
      '🤖',
    ),
    _Story(
      '6',
      'Whale Song Lullaby',
      'animals',
      '7-9',
      AppColors.iconCirclePurple,
      '🐳',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Story> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _stories.where((s) {
      if (_category != 'all' && s.category != _category) return false;
      if (_ageRange != 'all' && s.ageRange != _ageRange) return false;
      if (q.isNotEmpty && !s.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stories = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            BackPill(onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Story Library',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.softPink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🌸', style: TextStyle(fontSize: 32)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Find your next favorite story',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search for stories...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Filters',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Icon(
                          _filtersOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                  if (_filtersOpen) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters.map((f) {
                        return SoftChip(
                          label: f.label,
                          icon: f.icon,
                          selected: _category == f.value,
                          selectedColor: f.value == 'all'
                              ? AppColors.primaryBlue
                              : AppColors.softMint,
                          onTap: () => setState(() => _category = f.value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Age Range',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: _ageRanges.map((a) {
                        return SoftChip(
                          label: a == 'all' ? 'All' : a,
                          selected: _ageRange == a,
                          selectedColor: AppColors.softMint,
                          onTap: () => setState(() => _ageRange = a),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${stories.length} stor${stories.length == 1 ? "y" : "ies"} found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, i) {
                final s = stories[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AudioPlayerPage(title: s.title, audiobookId: s.id),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softPeach
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Age ${s.ageRange}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Library',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
