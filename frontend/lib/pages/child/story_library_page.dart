import 'package:flutter/material.dart';

import '../../models/content_item.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';
import 'audio_player_page.dart';

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

  List<ContentItem> _stories = const [];
  bool _loading = true;
  String? _error;

  static const _filters = [
    _CategoryFilter('All', 'all', Icons.menu_book_outlined),
    _CategoryFilter('Fantasy', 'fantasy', Icons.auto_awesome),
    _CategoryFilter('Animals', 'animals', Icons.pets),
    _CategoryFilter('Nature', 'nature', Icons.eco_outlined),
    _CategoryFilter('Adventure', 'adventure', Icons.flag_outlined),
    _CategoryFilter('Science', 'science', Icons.science_outlined),
  ];

  static const _ageRanges = ['all', '7-9', '8-11', '9-12'];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ApiResponse resp = await DatabaseService.getContentList();
    if (!mounted) return;
    if (resp.success && resp.data is List<ContentItem>) {
      setState(() {
        _stories = resp.data as List<ContentItem>;
        _loading = false;
      });
    } else {
      setState(() {
        _stories = const [];
        _error = resp.message;
        _loading = false;
      });
      AppSnackbar.error('Could not load stories: ${resp.message}',
          context: context);
    }
  }

  List<ContentItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _stories.where((s) {
      if (_category != 'all') {
        final c = (s.category ?? '').toLowerCase();
        if (c != _category) return false;
      }
      if (_ageRange != 'all') {
        final age = (s.ageGroup ?? '').toLowerCase();
        if (age != _ageRange) return false;
      }
      if (q.isNotEmpty) {
        final hay = '${s.title} ${s.author ?? ''} ${s.topic ?? ''} '
                '${s.category ?? ''} ${s.tags ?? ''}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  bool get _filtersActive =>
      _category != 'all' ||
      _ageRange != 'all' ||
      _searchCtrl.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _category = 'all';
      _ageRange = 'all';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stories = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStories,
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
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _filtersOpen = !_filtersOpen),
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
                            onTap: () =>
                                setState(() => _category = f.value),
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
              if (_loading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else if (_stories.isEmpty) ...[
                EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No stories yet',
                  subtitle: _error != null
                      ? 'We could not reach the library right now.\nPull down to try again.'
                      : 'Ask a caregiver to upload a story\nfrom the Content Management page.',
                  iconBackground: AppColors.softPink,
                  iconColor: AppColors.primaryBlueDark,
                ),
              ] else if (stories.isEmpty) ...[
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No stories match your filters',
                  subtitle:
                      'Try a different category, age range, or search word.',
                  iconBackground: AppColors.softPeach,
                  iconColor: AppColors.warning,
                  action: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _filtersActive ? _clearFilters : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear filters'),
                  ),
                ),
              ] else ...[
                Text(
                  '${stories.length} stor${stories.length == 1 ? "y" : "ies"} found',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stories.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, i) {
                    final s = stories[i];
                    return _StoryGridTile(
                      story: s,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AudioPlayerPage(
                            title: s.title,
                            audiobookId: s.audiobookId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryGridTile extends StatelessWidget {
  final ContentItem story;
  final VoidCallback onTap;
  const _StoryGridTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ageLabel = (story.ageGroup ?? '').trim().isEmpty
        ? null
        : 'Age ${story.ageGroup}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                child: _CoverArt(
                  imageUrl: story.coverImage,
                  category: story.category,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                story.title,
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
                  if (ageLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AppColors.softPeach.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ageLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    story.isGenerated ? 'AI' : 'Library',
                    style: const TextStyle(
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
  }
}

class _CoverArt extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  const _CoverArt({this.imageUrl, this.category});

  static const _categoryStyle = <String, (Color, String)>{
    'fantasy': (AppColors.softLavender, '🐉'),
    'animals': (AppColors.softMint, '🦊'),
    'nature': (AppColors.softYellow, '🌿'),
    'adventure': (AppColors.softPeach, '⛵'),
    'science': (AppColors.iconCircleBlue, '🤖'),
  };

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(loading: true);
          },
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) {
    final key = (category ?? '').toLowerCase();
    final style = _categoryStyle[key] ?? (AppColors.iconCirclePurple, '📖');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator()
          : Text(style.$2, style: const TextStyle(fontSize: 48)),
    );
  }
}
