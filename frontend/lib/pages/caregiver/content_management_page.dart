import 'package:flutter/material.dart';

import '../../models/content_item.dart';
import '../../models/content_summary.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/stat_card.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final ApiResponse summaryResp = await DatabaseService.getContentSummary();
    final ApiResponse listResp = await DatabaseService.getContentList(
      filterType: _filter == 'all' ? null : _filter,
      search: _searchCtrl.text.trim(),
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
              const Expanded(
                child: Text(
                  'Content\nManagement',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UploadContentPage()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Upload'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload and organize\neducational materials',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
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
              StatCard(icon: Icons.menu_book_outlined, iconBackground: AppColors.iconCircleBlue, value: '${_summary.totalItems}', label: 'Total Items'),
              StatCard(icon: Icons.headphones_outlined, iconBackground: AppColors.iconCircleGreen, value: '${_summary.audioFiles}', label: 'Audio Files'),
              StatCard(icon: Icons.description_outlined, iconBackground: AppColors.iconCirclePeach, value: '${_summary.textFiles}', label: 'Text Files'),
              StatCard(icon: Icons.auto_awesome, iconBackground: AppColors.iconCirclePurple, value: '${_summary.aiGenerated}', label: 'AI Generated'),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _refresh(),
            decoration: const InputDecoration(
              hintText: 'Search content...',
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Filter by type', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(label: 'All', selected: _filter == 'all', onTap: () { setState(() => _filter = 'all'); _refresh(); }),
              SoftChip(label: 'Audio', selected: _filter == 'audio', onTap: () { setState(() => _filter = 'audio'); _refresh(); }),
              SoftChip(label: 'Text', selected: _filter == 'text', onTap: () { setState(() => _filter = 'text'); _refresh(); }),
              SoftChip(label: 'AI Generated', selected: _filter == 'ai', onTap: () { setState(() => _filter = 'ai'); _refresh(); }),
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
              _ContentTile(item: item),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final ContentItem item;
  const _ContentTile({required this.item});

  ({IconData icon, Color bg, String label}) get _typeMeta {
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
    final meta = _typeMeta;
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: meta.bg, shape: BoxShape.circle),
            child: Icon(meta.icon, size: 20, color: AppColors.textPrimary),
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
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: meta.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(meta.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
