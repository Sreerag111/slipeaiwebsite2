import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/enhancer_debug_log.dart';
import '../pages/video_fullscreen_page.dart';
import 'enhancement_loading_indicator.dart';

class VideoComparisonView extends StatefulWidget {
  const VideoComparisonView({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    this.hasOriginal = true,
    this.edgeToEdge = false,
    this.onRemove,
  });

  final String beforeUrl;
  final String afterUrl;
  final bool hasOriginal;
  final bool edgeToEdge;
  final VoidCallback? onRemove;

  @override
  State<VideoComparisonView> createState() => _VideoComparisonViewState();
}

class _VideoComparisonViewState extends State<VideoComparisonView> {
  VideoPlayerController? _before;
  late final VideoPlayerController _after;
  bool _enhanced = true;
  bool _ready = false;
  bool _error = false;
  bool _playerErrorLogged = false;

  VideoPlayerController get _active =>
      _enhanced || _before == null ? _after : _before!;

  @override
  void initState() {
    super.initState();
    if (widget.hasOriginal) {
      _before = VideoPlayerController.networkUrl(Uri.parse(widget.beforeUrl));
    }
    _after = VideoPlayerController.networkUrl(Uri.parse(widget.afterUrl));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        if (_before != null) _initializeController(_before!, 'original'),
        _initializeController(_after, 'enhanced'),
      ]);
      _before?.addListener(_refresh);
      _after.addListener(_refresh);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _initializeController(
    VideoPlayerController controller,
    String side,
  ) async {
    EnhancerDebugLog.event('video preview initialization started',
        detail: 'side=$side');
    try {
      await controller.initialize();
      EnhancerDebugLog.event('video preview initialization completed',
          detail: 'side=$side '
              'width=${controller.value.size.width.round()} '
              'height=${controller.value.size.height.round()} '
              'durationMs=${controller.value.duration.inMilliseconds}');
    } catch (error) {
      EnhancerDebugLog.playerFailure(
        'video preview initialization',
        error,
        side: side,
        description: controller.value.errorDescription,
      );
      rethrow;
    }
  }

  void _refresh() {
    if (!mounted) return;
    final beforeFailed = _before?.value.hasError ?? false;
    final afterFailed = _after.value.hasError;
    if (!_playerErrorLogged && (beforeFailed || afterFailed)) {
      _playerErrorLogged = true;
      final controller = afterFailed ? _after : _before!;
      EnhancerDebugLog.playerFailure(
        'video preview playback',
        StateError('Video player reported an error.'),
        side: afterFailed ? 'enhanced' : 'original',
        description: controller.value.errorDescription,
      );
    }
    setState(() => _error = beforeFailed || afterFailed);
  }

  Future<void> _select(bool enhanced) async {
    if (_enhanced == enhanced || !_ready) return;
    final position = _active.value.position;
    await _active.pause();
    setState(() => _enhanced = enhanced);
    final duration = _active.value.duration;
    await _active.seekTo(position < duration ? position : Duration.zero);
  }

  @override
  void dispose() {
    _before?.removeListener(_refresh);
    _after.removeListener(_refresh);
    _before?.dispose();
    _after.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) return const Center(child: Text('Video preview unavailable'));
    if (!_ready) {
      return const SizedBox(
        height: 220,
        child: EnhancementLoadingIndicator(),
      );
    }
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final maxVideoHeight = (screenSize.height * 0.38).clamp(220.0, 320.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hasOriginal) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(widget.edgeToEdge ? 16 : 0,
                widget.edgeToEdge ? 10 : 0, widget.edgeToEdge ? 16 : 0, 0),
            child: Row(children: [
              Expanded(
                  child: _Choice('Before', !_enhanced, () => _select(false))),
              const SizedBox(width: 10),
              Expanded(child: _Choice('After', _enhanced, () => _select(true))),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxVideoHeight,
          ),
          child: AspectRatio(
            aspectRatio: _active.value.aspectRatio > 0
                ? _active.value.aspectRatio
                : 16 / 9,
            child: ClipRRect(
              borderRadius: widget.edgeToEdge
                  ? BorderRadius.zero
                  : BorderRadius.circular(16),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(fit: StackFit.expand, children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _active.value.size.width,
                      height: _active.value.size.height,
                      child: VideoPlayer(_active),
                    ),
                  ),
                  if (widget.onRemove != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton.filledTonal(
                          tooltip: 'Remove video',
                          onPressed: widget.onRemove,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ),
                  if (!_active.value.isPlaying)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _active.play(),
                            customBorder: const CircleBorder(),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.edgeToEdge ? 12 : 0,
            vertical: 4,
          ),
          child: Row(children: [
            // Play / Pause button
            _ScrubberButton(
              dark: dark,
              onTap: () =>
                  _active.value.isPlaying ? _active.pause() : _active.play(),
              child: Icon(
                _active.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 20,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VideoProgressIndicator(
                _active,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmtDuration(_active.value.position),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 8),
            // Fullscreen button
            _ScrubberButton(
              dark: dark,
              onTap: () => VideoFullscreenPage.open(
                context,
                afterUrl: widget.afterUrl,
                beforeUrl: widget.hasOriginal ? widget.beforeUrl : null,
                hasOriginal: widget.hasOriginal,
              ),
              child: Icon(
                Icons.fullscreen_rounded,
                size: 22,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  /// mm:ss formatted duration label.
  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Compact circular icon button used in the scrubber / controls row.
class _ScrubberButton extends StatelessWidget {
  const _ScrubberButton({
    required this.dark,
    required this.onTap,
    required this.child,
  });

  final bool dark;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF26262D) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.10 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: selected
            ? (dark ? Colors.white : const Color(0xFF0F172A))
            : (dark ? const Color(0xFF1E1E24) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : (dark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.white : Colors.black).withValues(
                alpha: selected ? (dark ? 0.20 : 0.18) : (dark ? 0.05 : 0.05)),
            blurRadius: selected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
          if (dark && selected)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? (dark ? Colors.black : Colors.white)
                    : (dark ? Colors.white70 : const Color(0xFF475569)),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
