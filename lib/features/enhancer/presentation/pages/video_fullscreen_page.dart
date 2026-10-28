import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../data/enhancer_debug_log.dart';
import '../widgets/enhancement_loading_indicator.dart';

/// Full-screen video comparison page.
///
/// Opens via [VideoFullscreenPage.open] and forces landscape mode while shown,
/// with a semi-transparent overlay UI that auto-hides after 3 seconds of
/// inactivity. Contains:
/// - Before / After animated pill switcher at the top.
/// - Playback progress bar and play/pause button at the bottom.
/// - Close button (top-left corner).
class VideoFullscreenPage extends StatefulWidget {
  const VideoFullscreenPage._({
    required this.afterUrl,
    this.beforeUrl,
    this.hasOriginal = true,
  });

  final String afterUrl;
  final String? beforeUrl;
  final bool hasOriginal;

  /// Opens [VideoFullscreenPage] as a full-screen route.
  static Future<void> open(
    BuildContext context, {
    required String afterUrl,
    String? beforeUrl,
    bool hasOriginal = true,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => VideoFullscreenPage._(
          afterUrl: afterUrl,
          beforeUrl: beforeUrl,
          hasOriginal: hasOriginal,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _before;
  late VideoPlayerController _after;

  bool _enhanced = true;
  bool _ready = false;
  bool _error = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  late final AnimationController _fadeController;

  VideoPlayerController get _active =>
      _enhanced || _before == null ? _after : _before!;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _enterFullscreen();
    _initializeControllers();
    _resetHideTimer();
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _initializeControllers() async {
    try {
      if (widget.hasOriginal && widget.beforeUrl != null) {
        _before =
            VideoPlayerController.networkUrl(Uri.parse(widget.beforeUrl!));
      }
      _after = VideoPlayerController.networkUrl(Uri.parse(widget.afterUrl));

      await Future.wait([
        if (_before != null) _before!.initialize(),
        _after.initialize(),
      ]);

      _before?.addListener(_onPlayerUpdate);
      _after.addListener(_onPlayerUpdate);

      if (mounted) setState(() => _ready = true);
    } catch (e) {
      EnhancerDebugLog.failure('fullscreen video init', e);
      if (mounted) setState(() => _error = true);
    }
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      _fadeController.forward();
    }
    _hideTimer = Timer(const Duration(seconds: 3), _hideControls);
  }

  void _hideControls() {
    if (!mounted) return;
    _fadeController.reverse().then((_) {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      _fadeController.reverse().then((_) {
        if (mounted) setState(() => _controlsVisible = false);
      });
    } else {
      _resetHideTimer();
    }
  }

  Future<void> _switchSide(bool enhanced) async {
    if (_enhanced == enhanced || !_ready) return;
    final position = _active.value.position;
    final wasPlaying = _active.value.isPlaying;
    await _active.pause();
    setState(() => _enhanced = enhanced);
    final dur = _active.value.duration;
    await _active.seekTo(position < dur ? position : Duration.zero);
    if (wasPlaying) await _active.play();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    _before?.removeListener(_onPlayerUpdate);
    _after.removeListener(_onPlayerUpdate);
    _before?.dispose();
    _after.dispose();
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_ready && !_error)
              const Center(child: EnhancementLoadingIndicator())
            else if (_error)
              Center(
                child: Text(
                  'Video preview unavailable',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              )
            else
              _VideoLayer(controller: _active),

            if (_ready)
              FadeTransition(
                opacity: _fadeController,
                child: _OverlayUi(
                  enhanced: _enhanced,
                  hasOriginal: widget.hasOriginal,
                  active: _active,
                  onTogglePlay: () {
                    _active.value.isPlaying
                        ? _active.pause()
                        : _active.play();
                    _resetHideTimer();
                  },
                  onSwitchSide: _switchSide,
                  onClose: () => Navigator.of(context).pop(),
                  onScrub: _resetHideTimer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _OverlayUi extends StatelessWidget {
  const _OverlayUi({
    required this.enhanced,
    required this.hasOriginal,
    required this.active,
    required this.onTogglePlay,
    required this.onSwitchSide,
    required this.onClose,
    required this.onScrub,
  });

  final bool enhanced;
  final bool hasOriginal;
  final VideoPlayerController active;
  final VoidCallback onTogglePlay;
  final Future<void> Function(bool) onSwitchSide;
  final VoidCallback onClose;
  final VoidCallback onScrub;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 8;
    final botPad = MediaQuery.of(context).padding.bottom + 10;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Top gradient
        Positioned(
          top: 0, left: 0, right: 0, height: 120,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB2000000), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0, height: 110,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),

        // Close button
        Positioned(
          top: topPad,
          left: 16,
          child: _GlassButton(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
        ),

        // Before / After pill
        if (hasOriginal)
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: Center(
              child: _BeforeAfterPill(
                enhanced: enhanced,
                onSwitchSide: onSwitchSide,
              ),
            ),
          ),

        // Center play button
        if (!active.value.isPlaying)
          Center(
            child: GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: botPad,
          left: 16,
          right: 16,
          child: _BottomControls(
            active: active,
            onTogglePlay: onTogglePlay,
            onScrub: onScrub,
          ),
        ),
      ],
    );
  }
}

class _BeforeAfterPill extends StatelessWidget {
  const _BeforeAfterPill({
    required this.enhanced,
    required this.onSwitchSide,
  });

  final bool enhanced;
  final Future<void> Function(bool) onSwitchSide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillItem(label: 'Before', selected: !enhanced,
              onTap: () => onSwitchSide(false)),
          const SizedBox(width: 2),
          _PillItem(label: 'After', selected: enhanced,
              onTap: () => onSwitchSide(true)),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.active,
    required this.onTogglePlay,
    required this.onScrub,
  });

  final VideoPlayerController active;
  final VoidCallback onTogglePlay;
  final VoidCallback onScrub;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final position = active.value.position;
    final duration = active.value.duration;
    return Row(
      children: [
        _GlassButton(
          onTap: onTogglePlay,
          child: Icon(
            active.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _fmt(position),
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => onScrub(),
            onHorizontalDragUpdate: (_) => onScrub(),
            child: VideoProgressIndicator(
              active,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _fmt(duration),
          style: GoogleFonts.inter(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.50),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
