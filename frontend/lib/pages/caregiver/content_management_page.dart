import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/i18n.dart';
import '../../models/content_item.dart';
import '../../models/content_summary.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/stat_card.dart';
import '../child/audio_player_page.dart';
import 'upload_content_page.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  ContentSummary _summary = ContentSummary.empty();
  List<ContentItem> _items = const [];
  bool _loading = false;
  String _filter = 'all';
  String _langFilter = 'all'; // 'all' | 'en' | 'ms'
  final TextEditingController _searchCtrl = TextEditingController();

  // While any book is still generating, quietly re-check until it's ready.
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final ApiResponse summaryResp = await DatabaseService.getContentSummary();
    final ApiResponse listResp = await DatabaseService.getContentList(
      filterType: _filter == 'all' ? null : _filter,
      search: _searchCtrl.text.trim(),
      language: _langFilter == 'all' ? null : _langFilter,
    );

    final summary = summaryResp.success && summaryResp.data is ContentSummary
        ? summaryResp.data as ContentSummary
        : ContentSummary.empty();

    final rawItems = listResp.success && listResp.data is List<ContentItem>
        ? listResp.data as List<ContentItem>
        : <ContentItem>[];

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _items = rawItems;
      _loading = false;
    });
    _syncPolling();
  }

  /// Open the audiobook in the same player the child uses, so the caregiver
  /// can preview exactly what the child will see and hear.
  void _openPreview(ContentItem item) {
    if (item.status == 'processing') {
      AppSnackbar.info(
        context.trRead('content.preview_still_generating'),
        context: context,
      );
      return;
    }
    final id = item.audiobookId;
    if (id == null || id.isEmpty) {
      AppSnackbar.warning(context.trRead('content.preview_no_book'),
          context: context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AudioPlayerPage(title: item.title, audiobookId: id, previewMode: true),
      ),
    );
  }

  /// Poll every few seconds while something is still "processing", and stop
  /// once everything is ready — so generated books appear without a manual pull.
  void _syncPolling() {
    final stillGenerating = _items.any((i) => i.status == 'processing');
    if (stillGenerating) {
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refresh(silent: true),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          BackPill(label: 'Back to Dashboard', onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('content.title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  // Wait for the upload / AI-generation page to pop, then
                  // refresh the library so the new book shows up immediately
                  // (otherwise the user would have to pull-down to see it
                  // unless polling happened to catch it).
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const UploadContentPage()),
                  );
                  if (mounted) await _refresh();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.upload, size: 18),
                label: Text(context.tr('common.upload')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('content.subtitle'),
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.2,
            children: [
              StatCard(icon: Icons.menu_book_outlined, iconBackground: AppColors.iconCircleBlue, value: '${_summary.totalItems}', label: context.tr('content.total_items')),
              StatCard(icon: Icons.headphones_outlined, iconBackground: AppColors.iconCircleGreen, value: '${_summary.audioFiles}', label: context.tr('content.audio_files')),
              StatCard(icon: Icons.description_outlined, iconBackground: AppColors.iconCirclePeach, value: '${_summary.textFiles}', label: context.tr('content.text_files')),
              StatCard(icon: Icons.auto_awesome, iconBackground: AppColors.iconCirclePurple, value: '${_summary.aiGenerated}', label: context.tr('content.ai_generated')),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _refresh(),
            decoration: InputDecoration(
              hintText: context.tr('content.search_hint'),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(context.tr('content.filter_by_type'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(label: context.tr('common.all'), selected: _filter == 'all', onTap: () { setState(() => _filter = 'all'); _refresh(); }),
              SoftChip(label: context.tr('content.filter_audio'), selected: _filter == 'audio', onTap: () { setState(() => _filter = 'audio'); _refresh(); }),
              SoftChip(label: context.tr('content.filter_text'), selected: _filter == 'text', onTap: () { setState(() => _filter = 'text'); _refresh(); }),
              SoftChip(label: context.tr('content.filter_ai'), selected: _filter == 'ai', onTap: () { setState(() => _filter = 'ai'); _refresh(); }),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.translate,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(context.tr('content.filter_by_language'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(
                label: context.tr('content.filter_lang_all'),
                selected: _langFilter == 'all',
                onTap: () {
                  setState(() => _langFilter = 'all');
                  _refresh();
                },
              ),
              SoftChip(
                label: context.tr('content.filter_lang_en'),
                selected: _langFilter == 'en',
                selectedColor: AppColors.softMint,
                onTap: () {
                  setState(() => _langFilter = 'en');
                  _refresh();
                },
              ),
              SoftChip(
                label: context.tr('content.filter_lang_ms'),
                selected: _langFilter == 'ms',
                selectedColor: AppColors.softMint,
                onTap: () {
                  setState(() => _langFilter = 'ms');
                  _refresh();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final item in _items) ...[
              _ContentTile(item: item, onTap: () => _openPreview(item)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  const _ContentTile({required this.item, this.onTap});

  static ({IconData icon, Color bg, String label}) _typeMetaFor(ContentItem item) {
    if (item.isGenerated) {
      return (icon: Icons.auto_awesome, bg: AppColors.iconCirclePurple, label: 'AI');
    }
    final type = (item.type ?? '').toLowerCase();
    if (type == 'audio') {
      return (icon: Icons.headphones_outlined, bg: AppColors.iconCircleGreen, label: 'Audio');
    }
    return (icon: Icons.description_outlined, bg: AppColors.iconCirclePeach, label: 'Text');
  }

  @override
  Widget build(BuildContext context) {
    final meta = _typeMetaFor(item);
    final processing = item.status == 'processing';
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          _Thumbnail(
            imageUrl: item.coverImage,
            meta: meta,
            processing: processing,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (item.topic != null || item.difficulty != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [item.topic, item.difficulty].whereType<String>().join(' • '),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                if (!processing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline,
                            size: 15, color: AppColors.primaryBlueDark),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('content.tap_to_preview'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          processing ? _generatingBadge(context) : _typeBadge(meta),
        ],
      ),
    );
  }

  Widget _typeBadge(({IconData icon, Color bg, String label}) meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: meta.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(meta.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _generatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softPeach,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Text(context.tr('content.generating'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Leading thumbnail for a content row: shows the cover image when present,
/// otherwise a coloured circle with the content-type icon.
class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  final ({IconData icon, Color bg, String label}) meta;
  final bool processing;
  const _Thumbnail({
    required this.imageUrl,
    required this.meta,
    this.processing = false,
  });

  @override
  Widget build(BuildContext context) {
    // While generating, the cover isn't ready yet — show a spinner tile.
    if (processing) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.softPeach,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 150, // tiny thumbnail; decode small to save memory
          errorBuilder: (_, _, _) => _iconCircle(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 48,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: meta.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _iconCircle();
  }

  Widget _iconCircle() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: meta.bg, shape: BoxShape.circle),
      child: Icon(meta.icon, size: 20, color: AppColors.textPrimary),
    );
  }
}
