import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ads/loading_page_ad.dart';
import '../../../../core/error/media_failure.dart';
import '../../../../core/review/app_review_service.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../data/enhancer_debug_log.dart';
import '../../data/topaz_enhancement_service.dart';
import '../widgets/enhancement_save_button.dart';
import '../widgets/enhancement_style_selector.dart';
import '../widgets/enhancer_style.dart';
import '../widgets/selected_video_preview.dart';
import '../widgets/video_comparison_view.dart';

/// Dedicated video processing and result screen matching the AI image enhancer flow:
/// - Top: Modern rounded card showing the video stage with frosted overlay,
///        gradient circular spinner, and bold status text during enhancement.
///        Transitions smoothly to [VideoComparisonView] upon completion.
/// - Actions: "Save enhanced video" and "Enhance another video" with matching button widths.
/// - Bottom: Native / MREC ad card for free users.
class VideoEnhancementProcessingScreen extends StatefulWidget {
  const VideoEnhancementProcessingScreen({
    super.key,
    required this.jobId,
    required this.category,
    this.originalFile,
    this.originalUrl,
    this.aspectRatio,
  });

  final String jobId;
  final String category;
  final File? originalFile;
  final String? originalUrl;
  final double? aspectRatio;

  @override
  State<VideoEnhancementProcessingScreen> createState() =>
      _VideoEnhancementProcessingScreenState();
}

class _VideoEnhancementProcessingScreenState
    extends State<VideoEnhancementProcessingScreen> {
  static const _savedJobKey = 'topaz_video_job_id';

  final _service = TopazEnhancementService();

  String _status = 'Enhancing your video…';
  String? _resultUrl;
  String? _originalUrl;
  bool _isBusy = true;
  bool _hasError = false;
  bool _isCanceling = false;
  bool _canCancel = true;
  double? _videoAspectRatio;

  String get _categoryTitle {
    for (final style in videoEnhancementStyles) {
      if (style.id == widget.category) {
        return style.label;
      }
    }
    return 'AI Video Remaster';
  }

  @override
  void initState() {
    super.initState();
    _videoAspectRatio = widget.aspectRatio;
    _originalUrl = widget.originalUrl;
    _poll(widget.jobId);
  }

  Future<void> _poll(String jobId) async {
    setState(() {
      _isBusy = true;
      _hasError = false;
      _status = 'Enhancing your video…';
    });

    try {
      var waitingForUpload = 0;
      while (mounted && !_isCanceling) {
        final state = await _service.videoStatus(jobId);
        if (!mounted || _isCanceling) return;

        final status =
            (state['status']?.toString() ?? 'processing').toLowerCase();
        final rawProgress =
            (state['progress'] as num?)?.toDouble().clamp(0.0, 100.0);

        setState(() {
          _canCancel = rawProgress == null || rawProgress < 100;
          _status = status == 'complete' || status == 'completed'
              ? 'Enhanced video is ready'
              : status == 'processing' &&
                      rawProgress != null &&
                      rawProgress >= 100
                  ? 'Finalizing your video…'
                  : status == 'processing' && rawProgress != null
                      ? 'Enhancing your video… ${rawProgress.toStringAsFixed(0)}%'
                      : status;
        });

        if (status == 'complete' || status == 'completed') {
          final url = state['resultUrl'] as String?;
          if (url == null || url.isEmpty) {
            throw StateError('The enhanced video URL was not returned.');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_savedJobKey);

          if (!mounted) return;
          unawaited(AppReviewService.instance.onFeatureCompleted(context));

          setState(() {
            _originalUrl =
                state['originalUrl'] as String? ?? widget.originalUrl;
            _resultUrl = url;
            _isBusy = false;
            _hasError = false;
            _status = 'Enhanced video is ready';
          });
          return;
        }

        if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'canceled') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_savedJobKey);
          throw StateError('Video enhancement failed.');
        }

        if (status == 'requested' || status == 'accepted') {
          waitingForUpload++;
          if (waitingForUpload >= 6) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_savedJobKey);
            throw StateError('Video processing request timed out.');
          }
        } else {
          waitingForUpload = 0;
        }

        await Future<void>.delayed(const Duration(seconds: 4));
      }
    } catch (error) {
      _handleFailure(error);
    }
  }

  void _handleFailure(Object error) {
    if (!mounted) return;
    EnhancerDebugLog.failure('video processing page', error);
    final message = MediaFailure.message(error, media: 'video');
    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
    setState(() {
      _isBusy = false;
      _hasError = true;
      _status = message;
    });
  }

  Future<void> _cancelEnhancement() async {
    if (_isCanceling) return;
    setState(() {
      _isCanceling = true;
      _status = 'Canceling video enhancement…';
    });
    try {
      final result = await _service.cancelVideo(widget.jobId);
      if (result['canceled'] != true) {
        if (!mounted) return;
        setState(() {
          _isCanceling = false;
          _canCancel = false;
          _status = 'Finalizing your video…';
        });
        await _poll(widget.jobId);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedJobKey);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCanceling = false;
      });
      _handleFailure(error);
    }
  }

  Future<bool> _handleBackPress() async {
    if (_isBusy) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Enhancement?'),
          content: const Text(
            'Your video is currently being processed by AI. Are you sure you want to stop?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Waiting'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogContext).colorScheme.errorContainer,
                foregroundColor:
                    Theme.of(dialogContext).colorScheme.onErrorContainer,
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        _isCanceling = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_savedJobKey);
        unawaited(_service.cancelVideo(widget.jobId));
        return true;
      }
      return false;
    }

    Navigator.of(context).pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final allow = await _handleBackPress();
          if (allow && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Theme(
        data: EnhancerStyle.theme(context),
        child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: _buildBackButton(context, isDark),
            ),
            title: Text(
              _categoryTitle,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Video Stage Card
                        _buildTopStageCard(context, isDark),

                        const SizedBox(height: 10),

                        // Actions when complete
                        if (!_isBusy && _resultUrl != null) ...[
                          _buildResultActions(context, isDark),
                        ]
                        // Cancel button during processing
                        else if (_isBusy && _canCancel) ...[
                          _buildCancelButton(context, isDark),
                        ],

                        // Bottom Native Ad Section (Free users only)
                        if (Get.isRegistered<PremiumController>() &&
                            Get.find<PremiumController>()
                                .shouldShowFreeAds) ...[
                          const LoadingPageAd(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTopStageCard(BuildContext context, bool isDark) {
    // 1. Result View (when enhancement finished) - naturally sized to avoid overflow
    if (!_isBusy && _resultUrl != null) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: VideoComparisonView(
          beforeUrl: _originalUrl ?? _resultUrl!,
          afterUrl: _resultUrl!,
          hasOriginal: _originalUrl != null,
          edgeToEdge: true,
        ),
      );
    }

    // 2. Loading / Processing State
    final screenSize = MediaQuery.sizeOf(context);
    final stageHeight = _videoAspectRatio == null
        ? (screenSize.height * 0.40).clamp(240.0, 360.0)
        : ((screenSize.width - 32) / _videoAspectRatio!).clamp(220.0, 360.0);

    return Container(
      width: double.infinity,
      height: stageHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video Preview (if original file exists)
          if (widget.originalFile != null)
            SelectedVideoPreview(
              key: ValueKey(widget.originalFile!.path),
              file: widget.originalFile!,
              enabled: false,
              onAspectRatio: (ratio) {
                if (mounted && _videoAspectRatio == null) {
                  setState(() => _videoAspectRatio = ratio);
                }
              },
            )
          else
            Container(
              color: isDark ? const Color(0xFF16161B) : const Color(0xFF1F2937),
              child: Center(
                child: Icon(
                  Icons.video_library_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),

          // Frosted dark vignette overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.60),
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),

          // Centered Gradient Spinner & Bold White Status Text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isBusy) ...[
                    const _GradientCircularLoader(),
                    const SizedBox(height: 14),
                  ] else if (_hasError) ...[
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (_hasError) ...[
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => _poll(widget.jobId),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: _isCanceling ? null : _cancelEnhancement,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF17171C) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isCanceling
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.stop_circle_outlined, size: 18),
        label: Text(
          _isCanceling ? 'Canceling…' : 'Cancel enhancement',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildResultActions(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Save enhanced video Button
        EnhancementSaveButton(
          url: _resultUrl!,
          isVideo: true,
          label: 'Save enhanced video',
        ),

        const SizedBox(height: 8),

        // Enhance another video Button (exact same button width: double.infinity, height: 48)
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF17171C) : Colors.white,
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.video_call_outlined, size: 18),
            label: const Text(
              'Enhance another video',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.12 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.05 : 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () async {
            final allow = await _handleBackPress();
            if (allow && mounted) {
              Navigator.of(context).pop();
            }
          },
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: 'Back',
            child: Center(
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientCircularLoader extends StatefulWidget {
  const _GradientCircularLoader();

  @override
  State<_GradientCircularLoader> createState() =>
      _GradientCircularLoaderState();
}

class _GradientCircularLoaderState extends State<_GradientCircularLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: const Size(52, 52),
        painter: _GradientSpinnerPainter(),
      ),
    );
  }
}

class _GradientSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 5.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0x00FF2A7A),
          Color(0xFFFF2A7A),
          Color(0xFFFF5252),
          Color(0xFFFF7A45),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width - strokeWidth) / 2,
      ),
      0,
      4.9,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
