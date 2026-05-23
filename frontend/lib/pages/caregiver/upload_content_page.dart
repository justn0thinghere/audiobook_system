import 'package:flutter/material.dart';

import '../../models/content_item.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';

enum _Mode { write, ai }

class UploadContentPage extends StatefulWidget {
  const UploadContentPage({super.key});

  @override
  State<UploadContentPage> createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage> {
  _Mode _mode = _Mode.write;

  // Manual ("write") form
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  String _difficulty = 'Easy';
  bool _submitting = false;

  // AI ("generate") form
  final _aiTopicCtrl = TextEditingController();
  final _aiBaseTextCtrl = TextEditingController();
  String _aiAge = '7-9';
  String _aiDifficulty = 'Easy';
  bool _aiGenerateImage = true;
  bool _generating = false;

  static const _ages = ['5-6', '7-9', '8-11', '9-12'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _tagsCtrl.dispose();
    _textCtrl.dispose();
    _aiTopicCtrl.dispose();
    _aiBaseTextCtrl.dispose();
    super.dispose();
  }

  // ---------- manual submit ----------

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      AppSnackbar.warning('Title is required', context: context);
      return;
    }
    setState(() => _submitting = true);
    final resp = await DatabaseService.createContent({
      'title': _titleCtrl.text.trim(),
      'topic': _topicCtrl.text.trim(),
      'difficulty': _difficulty,
      'type': 'Text',
      'tags': _tagsCtrl.text.trim(),
      'content_text': _textCtrl.text.trim(),
      'is_generated': false,
      'is_user_uploaded': true,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (resp.success) {
      AppSnackbar.success('Story added to library', context: context);
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(resp.message, context: context);
    }
  }

  // ---------- AI generate ----------

  Future<void> _generateAi() async {
    final topic = _aiTopicCtrl.text.trim();
    if (topic.isEmpty) {
      AppSnackbar.warning('Please enter a topic or idea for the story',
          context: context);
      return;
    }
    setState(() => _generating = true);
    final ApiResponse resp = await DatabaseService.generateAiContent(
      topic: topic,
      ageGroup: _aiAge,
      difficulty: _aiDifficulty,
      sourceText: _aiBaseTextCtrl.text.trim(),
      generateImage: _aiGenerateImage,
    );
    if (!mounted) return;
    setState(() => _generating = false);

    if (resp.success && resp.data is ContentItem) {
      await _showResultDialog(resp.data as ContentItem, resp.message);
      if (mounted) Navigator.of(context).pop();
    } else {
      AppSnackbar.error(resp.message, context: context);
    }
  }

  Future<void> _showResultDialog(ContentItem item, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.iconCirclePurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 20, color: AppColors.primaryBlueDark),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Story created',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (item.coverImage != null && item.coverImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.coverImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.contentText ?? item.description ?? '',
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 10),
                Text(message,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const BackPill(),
            const SizedBox(height: 16),
            const Text(
              'Upload Content',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a new story for your children',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _ModeToggle(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: 16),
            if (_mode == _Mode.write) _buildWriteForm() else _buildAiForm(),
          ],
        ),
      ),
    );
  }

  // ---------- write form ----------

  Widget _buildWriteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Title'),
              TextField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(hintText: 'e.g. The Gentle Dragon')),
              const SizedBox(height: 14),
              const _Label('Topic'),
              TextField(
                  controller: _topicCtrl,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Fantasy, Animals')),
              const SizedBox(height: 14),
              const _Label('Difficulty'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Easy', 'Medium', 'Hard'].map((d) {
                  return SoftChip(
                    label: d,
                    selected: _difficulty == d,
                    onTap: () => setState(() => _difficulty = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const _Label('Tags'),
              TextField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                      hintText: 'comma, separated, tags')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Story Text'),
              TextField(
                controller: _textCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Paste or type the story here…',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Content',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tip: to add a pre-recorded audiobook or video file, use the upload '
          'option (coming soon). AI video generation is not available on the '
          'free tier.',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  // ---------- AI form ----------

  Widget _buildAiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.iconCirclePurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 18, color: AppColors.primaryBlueDark),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Generate with Gemini AI',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Describe a topic and AI will write a calm, autism-friendly '
                'story for you to review.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              const _Label('Topic / idea'),
              TextField(
                controller: _aiTopicCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. A shy turtle who makes a new friend',
                ),
              ),
              const SizedBox(height: 14),
              const _Label('Age range'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ages.map((a) {
                  return SoftChip(
                    label: a,
                    selected: _aiAge == a,
                    selectedColor: AppColors.softMint,
                    onTap: () => setState(() => _aiAge = a),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const _Label('Difficulty'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Easy', 'Medium', 'Hard'].map((d) {
                  return SoftChip(
                    label: d,
                    selected: _aiDifficulty == d,
                    onTap: () => setState(() => _aiDifficulty = d),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Base text (optional)'),
              TextField(
                controller: _aiBaseTextCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Paste existing text to rewrite into a gentle story, or leave empty.',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _aiGenerateImage,
                activeThumbColor: AppColors.primaryBlueDark,
                onChanged: (v) => setState(() => _aiGenerateImage = v),
                title: const Text('Generate a cover image',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Uses Gemini image generation (may be skipped on the free tier).',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlueDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _generating ? null : _generateAi,
            icon: _generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(
              _generating ? 'Generating…' : 'Generate with AI',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        if (_generating) ...[
          const SizedBox(height: 10),
          const Text(
            'This can take 10–30 seconds. Please keep the app open.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _segment('Write', Icons.edit_outlined, _Mode.write),
          _segment('Generate with AI', Icons.auto_awesome, _Mode.ai),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, _Mode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
