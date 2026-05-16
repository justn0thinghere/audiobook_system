import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chip.dart';

class UploadContentPage extends StatefulWidget {
  const UploadContentPage({super.key});

  @override
  State<UploadContentPage> createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage> {
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  String _difficulty = 'Easy';
  bool _aiAssist = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _tagsCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

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
      'tags': _tagsCtrl.text.trim(),
      'content_text': _textCtrl.text.trim(),
      'is_generated': _aiAssist,
      'is_user_uploaded': true,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (resp.success) {
      AppSnackbar.success('Uploaded successfully', context: context);
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(resp.message, context: context);
    }
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
            const SizedBox(height: 20),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Title'),
                  TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. The Gentle Dragon')),
                  const SizedBox(height: 14),
                  const _Label('Topic'),
                  TextField(controller: _topicCtrl, decoration: const InputDecoration(hintText: 'e.g. Fantasy, Animals')),
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
                  TextField(controller: _tagsCtrl, decoration: const InputDecoration(hintText: 'comma, separated, tags')),
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
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _aiAssist,
                    onChanged: (v) => setState(() => _aiAssist = v),
                    activeThumbColor: AppColors.primaryBlueDark,
                    title: const Text('Use AI to generate audiobook',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Auto-narrate with a calm voice (coming soon).',
                      style: TextStyle(color: AppColors.textSecondary),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Content',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
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
