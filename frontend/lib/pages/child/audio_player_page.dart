import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_engine.dart';
import '../../models/audiobook.dart';
import '../../models/user_settings.dart';
import '../../services/database_service.dart';
import '../../state/profiles_state.dart';
import '../../state/settings_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/soft_card.dart';

class AudioPlayerPage extends StatefulWidget {
  final String title;
  final String? audiobookId;
  const AudioPlayerPage({super.key, required this.title, this.audiobookId});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioEngine _engine = AudioEngine.instance;
  final FlutterTts _flutterTts = FlutterTts();
  final PageController _pageController = PageController();

  Audiobook? _audiobook;
  List<_PlayerPage> _pages = [];
  bool _loading = true;
  bool _audioReady = false;
  bool _playingAudio = false;
  bool _ttsSpeaking = false;
  bool _useTts = true;
  bool _ttsReady = false;
  int _page = 0;

  int _highlightStart = 0;
  int _highlightEnd = 0;

  // Listening-session tracking (UC-8 -> records into listening_history).
  final Stopwatch _listenWatch = Stopwatch();
  String? _activeChildId;
  String? _sessionMood;
  bool _reachedEnd = false;
  bool _sessionRecorded = false;

  static const _defaultStoryText =
      'A gentle dragon lives in a quiet meadow where every day feels warm and safe. '
      'The dragon waves to friends with soft, slow wings. '
      'Birds sing kind little songs in the tall green trees. '
      'A small rabbit hops over to say a friendly hello. '
      'The sun glows gently across the bright blue sky. '
      'Together they share a picnic of sweet berries and warm tea. '
      'Everyone is calm. Everyone is safe. Everyone is happy.';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadAudiobook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the active child + their selected mood while a context is
    // available, so we can still record the session from dispose().
    final profiles = context.read<ProfilesState>();
    _activeChildId ??= profiles.activeProfile?.childId;
    _sessionMood = profiles.currentMood;
  }

  @override
  void dispose() {
    _listenWatch.stop();
    _recordSessionIfNeeded();
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  /// Persists the just-finished listening session. Fire-and-forget — safe to
  /// call from dispose() because it uses captured values and the static
  /// DatabaseService (no BuildContext needed).
  void _recordSessionIfNeeded() {
    if (_sessionRecorded) return;
    final childId = _activeChildId;
    final audiobookId = widget.audiobookId;
    final seconds = _listenWatch.elapsed.inSeconds;
    // Skip the built-in demo story (no real UUID) and trivially short visits.
    if (childId == null || audiobookId == null || seconds < 3) return;
    _sessionRecorded = true;
    DatabaseService.recordListeningSession(
      childId: childId,
      audiobookId: audiobookId,
      durationSeconds: seconds,
      lastPositionSeconds: seconds,
      mood: _sessionMood,
      completed: _reachedEnd,
    );
  }

  Future<void> _initTts() async {
    try {
      _flutterTts.setStartHandler(() {
        if (!mounted) return;
        setState(() => _ttsSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        _listenWatch.stop();
        if (_page >= _pages.length - 1) _reachedEnd = true;
        setState(() {
          _ttsSpeaking = false;
          _highlightStart = 0;
          _highlightEnd = 0;
        });
        final autoNext = context.read<SettingsState>().autoPlayNext;
        if (autoNext && _page < _pages.length - 1) {
          _changePage(_page + 1, autoSpeak: true);
        }
      });
      _flutterTts.setCancelHandler(() {
        if (!mounted) return;
        _listenWatch.stop();
        setState(() {
          _ttsSpeaking = false;
          _highlightStart = 0;
          _highlightEnd = 0;
        });
      });
      _flutterTts.setErrorHandler((message) {
        debugPrint('TTS error: $message');
        if (!mounted) return;
        _listenWatch.stop();
        setState(() {
          _ttsSpeaking = false;
          _highlightStart = 0;
          _highlightEnd = 0;
        });
      });
      _flutterTts.setProgressHandler((text, startOffset, endOffset, word) {
        if (!mounted) return;
        setState(() {
          _highlightStart = startOffset;
          _highlightEnd = endOffset;
        });
      });

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
      }
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.45);

      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _ttsReady = false;
    }
  }

  Future<void> _loadAudiobook() async {
    if (widget.audiobookId == null) {
      _pages = _pagesFromText(_defaultStoryText, null);
      if (mounted) setState(() => _loading = false);
      return;
    }

    final settings = context.read<SettingsState>();
    final resp = await DatabaseService.getAudiobookData(widget.audiobookId!);
    if (!mounted) return;

    // getAudiobookData returns an already-parsed Audiobook in resp.data.
    if (resp.success && resp.data is Audiobook) {
      final book = resp.data as Audiobook;
      _audiobook = book;
      _page = 0;
      if (book.pages.isNotEmpty) {
        // Caregiver-built storybook: one image + text per page.
        _pages = book.pages
            .map((p) => _PlayerPage(
                  text: (p.text ?? '').trim(),
                  imageUrl: p.image,
                ))
            .toList();
      } else {
        // Plain story text: paginate by sentences, share the cover image.
        _pages = _pagesFromText(
          book.contentText ?? _defaultStoryText,
          book.coverImage,
        );
      }
      if (book.audioFile != null && book.audioFile!.isNotEmpty) {
        try {
          await _engine.loadAudio(book.audioFile!);
          await _engine.setSpeed(settings.readingSpeed);
          _audioReady = true;
          _useTts = false;
        } catch (_) {
          _audioReady = false;
          _useTts = true;
        }
      }
    } else {
      _pages = _pagesFromText(_defaultStoryText, null);
      _page = 0;
    }

    if (mounted) setState(() => _loading = false);
  }

  /// Split a long story into sentence-based pages, each sharing [imageUrl].
  List<_PlayerPage> _pagesFromText(String text, String? imageUrl) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final chunks = <String>[];
    final buffer = StringBuffer();
    var sentenceCount = 0;
    for (final sentence in sentences) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentence);
      sentenceCount++;
      if (sentenceCount >= 2 || buffer.length > 220) {
        chunks.add(buffer.toString());
        buffer.clear();
        sentenceCount = 0;
      }
    }
    if (buffer.isNotEmpty) chunks.add(buffer.toString());
    if (chunks.isEmpty) chunks.add(text);
    return chunks.map((c) => _PlayerPage(text: c, imageUrl: imageUrl)).toList();
  }

  Future<void> _togglePlayPause() async {
    if (_useTts) {
      if (_ttsSpeaking) {
        await _flutterTts.stop();
      } else {
        await _speakPage();
      }
      return;
    }
    if (_playingAudio) {
      await _engine.pause();
      _listenWatch.stop();
    } else {
      await _engine.play();
      _listenWatch.start();
    }
    if (mounted) setState(() => _playingAudio = !_playingAudio);
  }

  Future<void> _speakPage() async {
    if (_pages.isEmpty) return;
    if (!_ttsReady) {
      await _initTts();
    }
    if (!_ttsReady) {
      if (mounted) {
        AppSnackbar.error(
          'Text-to-speech is not ready on this device. '
          'Please install or enable a TTS engine in system settings.',
          context: context,
        );
      }
      return;
    }
    final text = _pages[_page].text;
    if (text.isEmpty) return;
    if (!mounted) return;
    final speed = context.read<SettingsState>().readingSpeed;
    final mappedRate = (0.30 + (speed - 0.7) * 0.30).clamp(0.25, 0.65);

    try {
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(mappedRate);
      setState(() {
        _ttsSpeaking = true;
        _highlightStart = 0;
        _highlightEnd = 0;
      });
      _listenWatch.start();
      final result = await _flutterTts.speak(text);
      debugPrint('TTS speak result: $result');
      if (result != 1) {
        if (!mounted) return;
        _listenWatch.stop();
        setState(() => _ttsSpeaking = false);
        AppSnackbar.warning(
          'Could not start narration. Check device volume and TTS engine.',
          context: context,
        );
      }
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      if (mounted) {
        setState(() => _ttsSpeaking = false);
      }
    }
  }

  Future<void> _changePage(int next, {bool autoSpeak = false}) async {
    if (next < 0 || next >= _pages.length || next == _page) return;
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() => _page = next);
    }
    if (autoSpeak && _useTts && mounted) {
      await _speakPage();
    }
  }

  Future<void> _onPageChanged(int next) async {
    if (!mounted || next == _page) return;
    final wasSpeaking = _ttsSpeaking;
    if (wasSpeaking) {
      await _flutterTts.stop();
    }
    setState(() {
      _page = next;
      _highlightStart = 0;
      _highlightEnd = 0;
      _ttsSpeaking = false;
    });
    if (wasSpeaking && _useTts && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) await _speakPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildStorybook(),
              const SizedBox(height: 14),
              _buildPageIndicator(),
              const SizedBox(height: 18),
              _buildControlBar(),
              const SizedBox(height: 16),
              _buildSettingsPanel(),
              const SizedBox(height: 8),
              const Text(
                'Tap Listen to hear the story. Words light up as they are read.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        BackPill(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 56),
      ],
    );
  }

  Widget _buildStorybook() {
    final reduced = context.watch<SettingsState>().reducedAnimations;
    final readAlongEnabled = context.watch<SettingsState>().readAlong;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.softPeach, AppColors.softLavender],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 460,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final page = _StorybookPage(
                  imageUrl: _pages[index].imageUrl ?? _audiobook?.coverImage,
                  text: _pages[index].text,
                  highlightStart: (readAlongEnabled && index == _page && _ttsSpeaking)
                      ? _highlightStart
                      : 0,
                  highlightEnd: (readAlongEnabled && index == _page && _ttsSpeaking)
                      ? _highlightEnd
                      : 0,
                  pageNumber: index + 1,
                  totalPages: _pages.length,
                  author: _audiobook?.author,
                );
                if (reduced) return page;
                return AnimatedBuilder(
                  animation: _pageController,
                  child: page,
                  builder: (context, child) {
                    double offset = 0;
                    if (_pageController.positions.isNotEmpty &&
                        _pageController.position.hasContentDimensions) {
                      offset = index - (_pageController.page ?? 0);
                    } else {
                      offset = (index - _page).toDouble();
                    }
                    final clamped = offset.clamp(-1.0, 1.0);
                    final rotation = clamped * (math.pi / 2.6);
                    final fade =
                        (1 - clamped.abs() * 0.45).clamp(0.0, 1.0).toDouble();
                    return Transform(
                      alignment: offset >= 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(rotation),
                      child: Opacity(opacity: fade, child: child),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    final total = _pages.length;
    if (total <= 1) return const SizedBox.shrink();
    final showDots = total <= 12;
    if (!showDots) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            'Page ${_page + 1} of $total',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlueDark : AppColors.cardBorder,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildControlBar() {
    final isPlaying = _useTts ? _ttsSpeaking : _playingAudio;
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          label: 'Back',
          color: AppColors.softLavender,
          enabled: _page > 0,
          onTap: () => _changePage(_page - 1),
        ),
        const SizedBox(width: 12),
        Expanded(child: _BigPlayButton(playing: isPlaying, onTap: _togglePlayPause)),
        const SizedBox(width: 12),
        _RoundIconButton(
          icon: Icons.chevron_right_rounded,
          label: 'Next',
          color: AppColors.softMint,
          enabled: _page < _pages.length - 1,
          onTap: () => _changePage(_page + 1),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    final speed = context.watch<SettingsState>().readingSpeed;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Read Along',
                  active: _useTts,
                  icon: Icons.record_voice_over_rounded,
                  onTap: () {
                    setState(() {
                      _useTts = true;
                      _playingAudio = false;
                    });
                    _engine.pause();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeButton(
                  label: 'Audio',
                  active: !_useTts && _audioReady,
                  icon: Icons.headphones_rounded,
                  enabled: _audioReady,
                  onTap: _audioReady
                      ? () {
                          _flutterTts.stop();
                          setState(() {
                            _useTts = false;
                            _ttsSpeaking = false;
                            _highlightStart = 0;
                            _highlightEnd = 0;
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
          if (_useTts) ...[
            const SizedBox(height: 16),
            const Text('Narrator Voice',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NarratorVoice.values.map((voice) {
                final selected = voice == context.watch<SettingsState>().voice;
                return ChoiceChip(
                  label: Text(voice.label),
                  selected: selected,
                  selectedColor: AppColors.primaryBlueDark,
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryBlueDark
                          : AppColors.cardBorder,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => _setVoice(voice),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reading Speed',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${speed.toStringAsFixed(1)}x',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryBlueDark,
              thumbColor: AppColors.primaryBlueDark,
              overlayColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              inactiveTrackColor: AppColors.cardBorder,
            ),
            child: Slider(
              value: speed,
              min: 0.7,
              max: 1.4,
              divisions: 7,
              label: '${speed.toStringAsFixed(1)}x',
              onChanged: (value) async {
                await context.read<SettingsState>().setReadingSpeed(value);
                if (!_useTts && _audioReady) {
                  await _engine.setSpeed(value);
                } else if (_useTts && _ttsSpeaking) {
                  await _flutterTts.stop();
                  await _speakPage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setVoice(NarratorVoice voice) async {
    await context.read<SettingsState>().setVoice(voice);
    switch (voice) {
      case NarratorVoice.calmFemale:
        await _flutterTts.setPitch(1.10);
        break;
      case NarratorVoice.warmMale:
        await _flutterTts.setPitch(0.80);
        break;
      case NarratorVoice.friendlyChild:
        await _flutterTts.setPitch(1.40);
        break;
      case NarratorVoice.soothingElder:
        await _flutterTts.setPitch(0.95);
        break;
    }
    await _flutterTts.setLanguage('en-US');
    if (_ttsSpeaking) {
      await _flutterTts.stop();
      await _speakPage();
    }
  }
}

/// One renderable storybook page: its narration text and (optional) image.
class _PlayerPage {
  final String text;
  final String? imageUrl;
  const _PlayerPage({required this.text, this.imageUrl});
}

class _StorybookPage extends StatelessWidget {
  final String? imageUrl;
  final String text;
  final int highlightStart;
  final int highlightEnd;
  final int pageNumber;
  final int totalPages;
  final String? author;

  const _StorybookPage({
    required this.imageUrl,
    required this.text,
    required this.highlightStart,
    required this.highlightEnd,
    required this.pageNumber,
    required this.totalPages,
    this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Illustration(imageUrl: imageUrl),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Page $pageNumber of $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (author != null && author!.isNotEmpty)
                Flexible(
                  child: Text(
                    author!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _HighlightedText(
                text: text,
                highlightStart: highlightStart,
                highlightEnd: highlightEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final String? imageUrl;
  const _Illustration({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(loading: true);
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.softLavender, AppColors.softPeach],
        ),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.auto_stories_rounded,
                size: 84,
                color: AppColors.primaryBlueDark,
              ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final int highlightStart;
  final int highlightEnd;

  const _HighlightedText({
    required this.text,
    required this.highlightStart,
    required this.highlightEnd,
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 20,
      height: 1.7,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    final valid = highlightEnd > highlightStart &&
        highlightStart >= 0 &&
        highlightEnd <= text.length;

    if (!valid) {
      return Text(text, style: baseStyle);
    }

    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      background: Paint()..color = AppColors.softYellow,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, highlightStart)),
          TextSpan(
            text: text.substring(highlightStart, highlightEnd),
            style: highlightStyle,
          ),
          TextSpan(text: text.substring(highlightEnd)),
        ],
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  const _BigPlayButton({required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 78,
        decoration: BoxDecoration(
          color: playing ? AppColors.primaryBlueDark : AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlueDark.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 6),
            Text(
              playing ? 'Pause' : 'Listen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: AppColors.textPrimary),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlueDark : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? AppColors.cardBorder
                : AppColors.cardBorder.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20, color: active ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
