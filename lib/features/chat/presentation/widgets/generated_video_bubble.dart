import 'dart:io';
import 'package:plagiarism_checker/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/theme_controller.dart';
import 'media_shimmer.dart';
import 'report_sheet.dart';

/// Interactive message bubble for AI-generated videos (Google Veo 3.1).
///
/// Features:
/// - In-chat video player with play/pause, scrub bar, duration, mute.
/// - Full-screen immersive viewer.
/// - Save to device gallery / files.
/// - Share video via OS share sheet.
/// - View generated prompt details.
class GeneratedVideoBubble extends StatefulWidget {
  const GeneratedVideoBubble({
    super.key,
    required this.videoUrl,
    this.videoPrompt,
    this.duration,
    this.authorizeExport,
  });

  final String videoUrl;
  final String? videoPrompt;
  final int? duration;
  final Future<bool> Function()? authorizeExport;

  @override
  State<GeneratedVideoBubble> createState() => _GeneratedVideoBubbleState();
}

class _GeneratedVideoBubbleState extends State<GeneratedVideoBubble>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;
  bool _isDownloading = false;
  int _feedbackStatus = 0; // 0: none, 1: up, -1: down

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_isInitialized && _controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  Future<void> _initializePlayer() async {
    debugPrint('[VideoBubble] Initializing video player');
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      _controller.setLooping(false);
      _controller.addListener(_videoListener);
      debugPrint(
        '[VideoCreation][VideoBubble] Player initialized successfully. '
        'Size: ${_controller.value.size}, Duration: ${_controller.value.duration}',
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint(
        '[VideoCreation][VideoBubble] Player initialization FAILED: $e\n$stack',
      );
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized) return;
    final value = _controller.value;
    // When video completes, stop and reset to beginning (no loop)
    if (value.duration > Duration.zero &&
        value.position >= value.duration &&
        value.isPlaying) {
      _controller.pause();
      _controller.seekTo(Duration.zero);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _controller.removeListener(_videoListener);
    }
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    AppHaptics.tap();
    final value = _controller.value;
    setState(() {
      if (value.isPlaying) {
        _controller.pause();
      } else {
        if (value.position >= value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    if (!_isInitialized) return;
    AppHaptics.selection();
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) return;
    if (widget.authorizeExport != null && !await widget.authorizeExport!())
      return;
    AppHaptics.tap();
    setState(() => _isDownloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (mounted) {
            _showPermissionDialog(context, 'videos');
          }
          return;
        }
      }

      final response = await http.get(Uri.parse(widget.videoUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video bytes');
      }

      final tempDir = await getTemporaryDirectory();
      final filename = 'slipe_ai_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      await Gal.putVideo(file.path, album: 'Slipe AI');

      if (mounted) {
        _showSnack(context, '✓ Video saved to gallery');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(context, 'Failed to save video: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _shareVideo() async {
    if (widget.authorizeExport != null && !await widget.authorizeExport!())
      return;
    AppHaptics.tap();
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/slipe_ai_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final response = await http.get(Uri.parse(widget.videoUrl));
      if (response.statusCode == 200) {
        await tempFile.writeAsBytes(response.bodyBytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempFile.path, mimeType: 'video/mp4')],
            text: widget.videoPrompt != null && widget.videoPrompt!.isNotEmpty
                ? 'Created with Slipe AI (Google Veo 3.1): ${widget.videoPrompt}'
                : 'Created with Slipe AI',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: widget.videoPrompt ?? 'AI Generated Video by Slipe AI',
            subject: 'AI Video',
          ),
        );
      }
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(text: widget.videoUrl),
      );
    }
  }

  void _showPromptSheet(BuildContext context) {
    AppHaptics.selection();
    final isDark = ThemeController.instance.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Veo 3.1 Video Prompt',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.videoPrompt ?? 'No prompt details available.',
              style: AppTextStyles.bodyMediumBase.copyWith(
                height: 1.5,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (widget.duration != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Duration: ${widget.duration}s',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF9D95FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    final isDark = ThemeController.instance.isDarkMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitPositiveFeedback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'contentUrl': widget.videoUrl,
        'contentPrompt': widget.videoPrompt,
        'contentType': 'video',
        'isPositive': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to submit positive feedback: $e');
    }
  }

  void _showPermissionDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Permission Required',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Gallery permission is required to save $type. Please enable it in your device settings.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child:
                Text('Open Settings', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context) async {
    AppHaptics.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenVideoViewer(
          controller: _controller,
          videoUrl: widget.videoUrl,
          videoPrompt: widget.videoPrompt,
          onDownload: _downloadVideo,
          onShare: _shareVideo,
          onShowPrompt: () => _showPromptSheet(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video container / player
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: _isInitialized && _controller.value.aspectRatio > 0
                    ? _controller.value.aspectRatio
                    : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_hasError)
                      _buildErrorPlaceholder()
                    else if (!_isInitialized)
                      _buildLoadingPlaceholder()
                    else
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: VideoPlayer(_controller),
                      ),

                    // Center Play/Pause overlay when paused
                    if (_isInitialized && !_controller.value.isPlaying)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),

                    // Top right: Fullscreen & Mute buttons
                    if (_isInitialized)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _IconButton(
                              icon: _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              onTap: _toggleMute,
                            ),
                            const SizedBox(width: 6),
                            _IconButton(
                              icon: Icons.fullscreen_rounded,
                              onTap: () => _openFullScreen(context),
                            ),
                          ],
                        ),
                      ),

                    // Bottom progress / elapsed time bar
                    if (_isInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, VideoPlayerValue value, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Icon(
                                      value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: VideoProgressIndicator(
                                        _controller,
                                        allowScrubbing: true,
                                        colors: VideoProgressColors(
                                          playedColor: AppTheme.accent,
                                          bufferedColor: Colors.white24,
                                          backgroundColor: Colors.white10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _ActionChip(
                    icon: _isDownloading
                        ? Icons.hourglass_top_rounded
                        : Icons.download_rounded,
                    onTap: _downloadVideo,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.share_rounded,
                    onTap: _shareVideo,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: _feedbackStatus == 1
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    onTap: () {
                      AppHaptics.selection();
                      if (_feedbackStatus == 1) {
                        setState(() => _feedbackStatus = 0);
                      } else {
                        setState(() => _feedbackStatus = 1);
                        _submitPositiveFeedback();
                        _showSnack(context, 'Thanks for your feedback!');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: _feedbackStatus == -1
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_down_alt_outlined,
                    onTap: () {
                      if (_feedbackStatus == -1) {
                        setState(() => _feedbackStatus = 0);
                        return;
                      }
                      ReportSheet.show(
                        context,
                        contentUrl: widget.videoUrl,
                        contentPrompt: widget.videoPrompt,
                        contentType: 'video',
                        onSubmit: () {
                          if (mounted) {
                            setState(() => _feedbackStatus = -1);
                            _showSnack(
                                context, 'Feedback submitted successfully');
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingPlaceholder() {
    final isDark = ThemeController.instance.isDarkMode;

    return MediaShimmer(
      isDark: isDark,
      label: 'Loading video…',

      // Parent VideoBubble already clips/framing the media area.
      showFrame: false,
      borderRadius: 0,
    );
  }

  Widget _buildErrorPlaceholder() {
    final isDark = ThemeController.instance.isDarkMode;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load video stream',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Video Viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenVideoViewer extends StatefulWidget {
  const _FullScreenVideoViewer({
    required this.controller,
    required this.videoUrl,
    this.videoPrompt,
    required this.onDownload,
    required this.onShare,
    required this.onShowPrompt,
  });

  final VideoPlayerController controller;
  final String videoUrl;
  final String? videoPrompt;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onShowPrompt;

  @override
  State<_FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<_FullScreenVideoViewer> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Center Video
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio > 0
                      ? widget.controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(widget.controller),
                ),
              ),

              // Top Bar
              if (_showControls)
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                        ),
                        onPressed: widget.onShowPrompt,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        onPressed: widget.onDownload,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                        ),
                        onPressed: widget.onShare,
                      ),
                    ],
                  ),
                ),

              // Bottom Playback Controls
              if (_showControls)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          widget.controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: AppTheme.accent,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: widget.controller,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                return IconButton(
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (value.isPlaying) {
                                        widget.controller.pause();
                                      } else {
                                        if (value.position >= value.duration) {
                                          widget.controller
                                              .seekTo(Duration.zero);
                                        }
                                        widget.controller.play();
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                            ValueListenableBuilder(
                              valueListenable: widget.controller,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                final pos = value.position;
                                final dur = value.duration;
                                return Text(
                                  '${_format(pos)} / ${_format(dur)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isDark ? Colors.white70 : Colors.black),
            ],
          ),
        ),
      );
    });
  }
}
