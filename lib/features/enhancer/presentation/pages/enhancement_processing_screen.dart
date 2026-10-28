import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ads/admob_service.dart';
import '../../../../core/ads/loading_page_ad.dart';
import '../../../../core/error/media_failure.dart';
import '../../../../core/review/app_review_service.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../data/enhancer_debug_log.dart';
import '../../data/topaz_enhancement_service.dart';
import '../widgets/adaptive_image_frame.dart';
import '../widgets/enhancement_save_button.dart';
import '../widgets/enhancement_style_selector.dart';
import '../widgets/enhancer_style.dart';
import '../widgets/photo_comparison_view.dart';
import '../widgets/photo_zoom_view.dart';

/// Dedicated processing and result screen matching the client's design:
/// - Top: Large rounded card displaying the image with dark overlay,
///        gradient circular spinner, and bold status text ("Uploading...", "Enhancing...").
///        Transitions to Before/After comparison view when completed.
/// - Bottom: Native Ad container with media, icon, title, and wide pill button.
/// - Actions: "Save enhanced photo" and "Enhance another photo" with smart 1-pop vs. 2-pop navigation.
class EnhancementProcessingScreen extends StatefulWidget {
  const EnhancementProcessingScreen({
    super.key,
    this.originalFile,
    this.originalUrl,
    required this.category,
    this.isVideo = false,
    this.existingJobId,
    this.aspectRatio,
  });

  final File? originalFile;
  final String? originalUrl;
  final String category;
  final bool isVideo;
  final String? existingJobId;
  final double? aspectRatio;

  @override
  State<EnhancementProcessingScreen> createState() =>
      _EnhancementProcessingScreenState();
}

class _EnhancementProcessingScreenState
    extends State<EnhancementProcessingScreen> {
  static const _savedPhotoJobKey = 'topaz_photo_job_id';
  static const _savedVideoJobKey = 'topaz_video_job_id';

  final _service = TopazEnhancementService();

  String? _jobId;
  String _status = 'Uploading…';
  String? _resultUrl;
  bool _isBusy = true;
  bool _hasError = false;
  bool _isCanceling = false;

  String get _savedJobKey =>
      widget.isVideo ? _savedVideoJobKey : _savedPhotoJobKey;

  String get _categoryTitle {
    final styles =
        widget.isVideo ? videoEnhancementStyles : photoEnhancementStyles;
    for (final style in styles) {
      if (style.id == widget.category) {
        return style.label;
      }
    }
    return widget.isVideo ? 'AI Video Remaster' : 'AI Photo';
  }

  @override
  void initState() {
    super.initState();
    // Preload an interstitial ad in background
    AdMobService.instance.preloadInterstitialAd();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isBusy = true;
      _hasError = false;
      _status = widget.isVideo ? 'Uploading video…' : 'Uploading…';
    });

    try {
      if (widget.existingJobId != null) {
        _jobId = widget.existingJobId;
        await _poll(_jobId!);
        return;
      }

      if (widget.isVideo) {
        await _startVideoFlow();
      } else {
        await _startPhotoFlow();
      }
    } catch (error) {
      _handleFailure(error);
    }
  }

  Future<void> _startPhotoFlow() async {
    final file = widget.originalFile;
    if (file == null) {
      throw StateError('No photo file provided for enhancement.');
    }

    if (!mounted) return;
    setState(() => _status = 'Uploading…');

    final jobId = await _service.startPhoto(file, widget.category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedJobKey, jobId);

    if (!mounted) return;
    setState(() {
      _jobId = jobId;
      _status = 'Enhancing…';
    });

    await _poll(jobId);
  }

  Future<void> _startVideoFlow() async {
    final file = widget.originalFile;
    if (file == null) {
      throw StateError('No video file provided for enhancement.');
    }

    if (!mounted) return;
    setState(() => _status = 'Uploading…');

    final uploadId = await _service.uploadVideo(file);
    if (!mounted) return;

    setState(() => _status = 'Analyzing…');
    final estimate = await _service.createVideo(uploadId, widget.category);
    if (!mounted) return;

    final jobId = estimate['jobId'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedJobKey, jobId);

    if (!mounted) return;
    setState(() {
      _jobId = jobId;
      _status = 'Enhancing…';
    });

    await _service.acceptVideo(jobId);
    if (mounted) {
      await _poll(jobId);
    }
  }

  Future<void> _poll(String jobId) async {
    try {
      var waitingForUpload = 0;
      while (mounted && _jobId == jobId && !_isCanceling) {
        final state = widget.isVideo
            ? await _service.videoStatus(jobId)
            : await _service.photoStatus(jobId);

        if (!mounted || _jobId != jobId || _isCanceling) return;

        final status =
            (state['status']?.toString() ?? 'Processing').toLowerCase();
        final rawProgress = (state['progress'] as num?)?.toDouble();

        if (widget.isVideo && rawProgress != null) {
          setState(() {
            _status = status == 'complete' || status == 'completed'
                ? 'Finalizing…'
                : 'Enhancing… ${rawProgress.toStringAsFixed(0)}%';
          });
        } else {
          setState(() {
            _status = switch (status) {
              'complete' || 'completed' => 'Finalizing…',
              'queued' => 'Queued…',
              'processing' => 'Enhancing…',
              _ => 'Enhancing…',
            };
          });
        }

        if (status == 'complete' || status == 'completed') {
          final url = state['resultUrl'] as String?;
          if (url == null || url.isEmpty) {
            throw StateError('The enhanced result URL was not returned.');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_savedJobKey);

          if (!mounted) return;

          // Feature review prompt trigger
          unawaited(AppReviewService.instance.onFeatureCompleted(context));

          // Set complete state right on this screen
          setState(() {
            _isBusy = false;
            _resultUrl = url;
            _status = 'Complete';
          });
          return;
        }

        if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'canceled') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_savedJobKey);
          throw StateError(state['message'] is String
              ? state['message'] as String
              : 'Enhancement failed.');
        }

        if (widget.isVideo && (status == 'requested' || status == 'accepted')) {
          waitingForUpload++;
          if (waitingForUpload >= 6) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_savedJobKey);
            throw StateError('Video processing request timed out.');
          }
        }

        await Future<void>.delayed(const Duration(seconds: 4));
      }
    } catch (error) {
      _handleFailure(error);
    }
  }

  void _handleFailure(Object error) {
    if (!mounted) return;
    EnhancerDebugLog.failure(
      widget.isVideo ? 'video processing page' : 'photo processing page',
      error,
    );

    final message = MediaFailure.message(
      error,
      media: widget.isVideo ? 'video' : 'photo',
    );

    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));

    setState(() {
      _isBusy = false;
      _jobId = null;
      _hasError = true;
      _status = message;
    });
  }

  /// When back is tapped from result, pop 2 times straight back to Category Selection.
  void _popTwoTimesToCategories() {
    int count = 0;
    Navigator.of(context).popUntil((_) => count++ >= 2);
  }

  /// When "Enhance another photo" is tapped, pop 1 time back to PhotoEnhancerScreen.
  void _popOneTimeToPhotoPicker() {
    Navigator.of(context).pop();
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
            'Your media is currently being processed by AI. Are you sure you want to stop?',
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

        if (widget.isVideo && _jobId != null) {
          unawaited(_service.cancelVideo(_jobId!));
        }
        return true;
      }
      return false;
    }

    // When result is showing, back button pops two times to Category selection
    _popTwoTimesToCategories();
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Card: Large rounded card (~46% height) with blurred image & spinner
                  _buildTopStageCard(context, isDark),

                  const SizedBox(height: 14),

                  // Actions shown when enhancement completes
                  if (!_isBusy && _resultUrl != null) ...[
                    _buildResultActions(context, isDark),
                  ],

                  // Bottom Native Ad Section (Free users only)
                  if (Get.isRegistered<PremiumController>() &&
                      Get.find<PremiumController>().shouldShowFreeAds) ...[
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

  /// Upper card matching client's screenshot:
  /// Adapts to the natural aspect ratio of the user photo (no gaps on top/sides),
  /// rounded corners (24px), dark blur/overlay, centered gradient circular spinner,
  /// and bold white status text.
  Widget _buildTopStageCard(BuildContext context, bool isDark) {
    final screenH = MediaQuery.sizeOf(context).height;
    // During loading, keep card around ~42% so the Native Ad below is >50% visible without scrolling.
    // When completed, allow up to 65% max height as requested by client for rich result comparison.
    final fallbackHeight = _isBusy
        ? (screenH * 0.40).clamp(240.0, 320.0)
        : (screenH * 0.60).clamp(320.0, 480.0);
    final maxHeight = _isBusy
        ? (screenH * 0.42).clamp(260.0, 340.0)
        : (screenH * 0.65).clamp(340.0, 540.0);
    final hasFile = widget.originalFile != null;
    final hasUrl = widget.originalUrl != null;

    ImageProvider? beforeImage;
    if (hasFile) {
      beforeImage = FileImage(widget.originalFile!);
    } else if (hasUrl) {
      beforeImage = CachedNetworkImageProvider(widget.originalUrl!);
    }

    return AdaptiveImageFrame(
      image: beforeImage ??
          (_resultUrl != null ? CachedNetworkImageProvider(_resultUrl!) : null),
      imageKey: widget.originalFile?.path ?? widget.originalUrl ?? _resultUrl,
      fallbackHeight: fallbackHeight,
      minHeight: 180,
      maxHeight: maxHeight,
      child: Container(
        width: double.infinity,
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Result View (when enhancement finished)
            if (!_isBusy && _resultUrl != null && beforeImage != null) ...[
              PhotoComparisonView(
                before: beforeImage,
                after: CachedNetworkImageProvider(_resultUrl!),
                fit: BoxFit.cover,
                transparentBackground: widget.category == 'remove_background',
              ),
              // Zoom Button in corner
              Positioned(
                left: 12,
                top: 12,
                child: IconButton.filledTonal(
                  tooltip: 'Zoom photo',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PhotoZoomView(
                        image: CachedNetworkImageProvider(_resultUrl!),
                        transparentBackground:
                            widget.category == 'remove_background',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.zoom_in_rounded),
                ),
              ),
            ]
            // 2. Loading State (Matching client's screenshot)
            else ...[
              // Background Image (Photo only)
              if (hasFile && !widget.isVideo)
                Image.file(
                  widget.originalFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (hasUrl && !widget.isVideo)
                CachedNetworkImage(
                  imageUrl: widget.originalUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

              // Dark frosted vignette overlay matching screenshot
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),

              // Centered Gradient Spinner & Bold White Status Text
              Center(
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
                      FilledButton.icon(
                        onPressed: _startProcessing,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Action buttons rendered when enhancement is completed:
  /// - "Save enhanced photo" (triggers existing rewarded ad logic)
  /// - "Enhance another photo" (pops 1 time back to PhotoEnhancerScreen)
  Widget _buildResultActions(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Save Button (with existing save ad flow intact)
        EnhancementSaveButton(
          url: _resultUrl!,
          isVideo: widget.isVideo,
          label: 'Save enhanced photo',
        ),

        const SizedBox(height: 10),

        // Enhance another photo Button (pops 1 time)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _popOneTimeToPhotoPicker,
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
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(
              'Enhance another ${widget.isVideo ? 'video' : 'photo'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
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

/// Custom gradient circular spinner matching the pink/coral ring in the screenshot.
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
