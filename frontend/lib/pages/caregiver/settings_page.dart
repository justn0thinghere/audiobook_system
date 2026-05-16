import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_settings.dart';
import '../../state/settings_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        BackPill(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 16),
        const Text(
          'Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customize your experience',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        const _NarrationCard(),
        const SizedBox(height: 14),
        const _SensoryCard(),
        const SizedBox(height: 14),
        const _PinChangeCard(),
      ],
    );
  }
}

class _NarrationCard extends StatelessWidget {
  const _NarrationCard();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.iconCircleBlue, shape: BoxShape.circle),
                child: const Icon(Icons.record_voice_over_outlined, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Narration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Narrator Voice', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _VoiceButton(label: 'Calm Female', value: NarratorVoice.calmFemale, current: settings.voice, onTap: settings.setVoice),
              _VoiceButton(label: 'Warm Male', value: NarratorVoice.warmMale, current: settings.voice, onTap: settings.setVoice),
              _VoiceButton(label: 'Friendly Child', value: NarratorVoice.friendlyChild, current: settings.voice, onTap: settings.setVoice),
              _VoiceButton(label: 'Soothing Elder', value: NarratorVoice.soothingElder, current: settings.voice, onTap: settings.setVoice),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.speed, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('Reading Speed', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${settings.readingSpeed.toStringAsFixed(1)}x',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: settings.readingSpeed,
            min: 0.5, max: 1.5, divisions: 10,
            activeColor: AppColors.primaryBlueDark,
            inactiveColor: AppColors.cardBorder,
            onChanged: settings.setReadingSpeed,
          ),
          const Row(
            children: [
              Text('Slower', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Spacer(),
              Text('Faster', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final String label;
  final NarratorVoice value;
  final NarratorVoice current;
  final void Function(NarratorVoice) onTap;
  const _VoiceButton({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.softPeach.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SensoryCard extends StatelessWidget {
  const _SensoryCard();
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.iconCircleGreen, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Sensory & Playback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryBlueDark,
            value: settings.reducedAnimations,
            onChanged: settings.setReducedAnimations,
            title: const Text('Reduced Animations', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Softer transitions and reduced motion',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryBlueDark,
            value: settings.autoPlayNext,
            onChanged: settings.setAutoPlayNext,
            title: const Text('Auto-Play Next Story', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Automatically start the next audiobook',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryBlueDark,
            value: settings.readAlong,
            onChanged: settings.setReadAlong,
            title: const Text('Read Along', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Highlight each word as the narrator speaks',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _PinChangeCard extends StatefulWidget {
  const _PinChangeCard();
  @override
  State<_PinChangeCard> createState() => _PinChangeCardState();
}

class _PinChangeCardState extends State<_PinChangeCard> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_next.text != _confirm.text) {
      AppSnackbar.warning('New PIN and confirmation do not match', context: context);
      return;
    }
    setState(() => _busy = true);
    final ok = await context.read<SettingsState>().changePin(
          currentPin: _current.text,
          newPin: _next.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      AppSnackbar.success('PIN updated', context: context);
      _current.clear();
      _next.clear();
      _confirm.clear();
    } else {
      AppSnackbar.error('Could not update PIN', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.iconCirclePeach,
                child: Icon(Icons.lock_outline, size: 18, color: AppColors.textPrimary),
              ),
              SizedBox(width: 10),
              Text('PIN Change', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          _pinField(_current, 'Current PIN'),
          const SizedBox(height: 10),
          _pinField(_next, 'New PIN'),
          const SizedBox(height: 10),
          _pinField(_confirm, 'Confirm PIN'),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.softPeach,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _busy ? null : _update,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Update PIN', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        suffixIcon: const Icon(Icons.remove_red_eye_outlined,
            color: AppColors.textMuted),
      ),
    );
  }
}
