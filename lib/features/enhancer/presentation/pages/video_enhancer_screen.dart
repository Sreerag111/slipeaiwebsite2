import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ads/loading_page_ad.dart';
import '../../../../core/error/media_failure.dart';
import '../../../../core/review/app_review_service.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/pages/premium_screen.dart';
import '../../data/enhancer_debug_log.dart';
import '../../data/topaz_enhancement_service.dart';
import '../widgets/enhancer_error_notice.dart';
import '../widgets/enhancement_save_button.dart';
import '../widgets/enhancement_style_selector.dart';
import '../widgets/enhancer_style.dart';
import '../widgets/enhancer_page_chrome.dart';
import '../widgets/enhancement_loading_indicator.dart';
import '../widgets/selected_video_preview.dart';
import '../widgets/video_comparison_view.dart';
import 'enhancement_history_screen.dart';
import 'video_enhancement_processing_screen.dart';

class VideoEnhancerScreen extends StatefulWidget {
  const VideoEnhancerScreen({
    super.key,
    this.embedded = false,
    this.initialCategory,
  });

  final bool embedded;
  final String? initialCategory;

  @override
  State<VideoEnhancerScreen> createState() => _VideoEnhancerScreenState();
}

class _VideoEnhancerScreenState extends State<VideoEnhancerScreen>
    with RouteAware {
  static const _savedJobKey = 'topaz_video_job_id';
  final _service = TopazEnhancementService();
  File? _original;
  String? _originalUrl;
  String? _jobId;
  String? _resultUrl;
  String? _selectedCategory;
  double? _sourceAspectRatio;
  String _status = 'Choose a video to enhance';
  bool _busy = false;
  bool _hasError = false;
  bool _canceling = false;
  bool _canCancel = true;

  /// Bumped each time the user returns to this screen so that [FreeUserBannerAd]
  /// and the bottom [LoadingPageAd] are fully rebuilt, disposing the old ad and
  /// requesting a fresh one (= new impression).
  int _adRefreshKey = 0;
  DateTime _lastAdRefreshTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? videoEnhancementStyles.first.id;
    _restoreJob();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called whenever another full-screen route (e.g. PremiumScreen,
    // EnhancementHistoryScreen, VideoEnhancementProcessingScreen, Settings)
    // popped and the user returned back to this remaster page.
    if (mounted) {
      _resetToIdle();
    }
  }

  Future<void> _restoreJob() async {
    final jobId =
        (await SharedPreferences.getInstance()).getString(_savedJobKey);
    if (jobId == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoEnhancementProcessingScreen(
          jobId: jobId,
          category: _selectedCategory ?? videoEnhancementStyles.first.id,
          aspectRatio: _sourceAspectRatio,
        ),
      ),
    );
    if (!mounted) return;
    _resetToIdle();
  }

  /// Resets the screen back to the idle 'Choose a video' starting stage and bumps
  /// the ad key so both the collapsible banner and the bottom MREC ad request fresh
  /// impressions. Called after returning from the result / processing screen,
  /// history screen, upgrade screen, or any other pushed page.
  void _resetToIdle() {
    final now = DateTime.now();
    final shouldBumpAd =
        now.difference(_lastAdRefreshTime).inMilliseconds > 500;
    if (shouldBumpAd) {
      _lastAdRefreshTime = now;
    }
    if (Get.isRegistered<PremiumController>()) {
      Get.find<PremiumController>().refreshMediaUsage();
    }
    setState(() {
      _original = null;
      _originalUrl = null;
      _resultUrl = null;
      _jobId = null;
      _sourceAspectRatio = null;
      _selectedCategory =
          widget.initialCategory ?? videoEnhancementStyles.first.id;
      _busy = false;
      _hasError = false;
      _status = 'Choose a video to enhance';
      if (shouldBumpAd) {
        _adRefreshKey++; // force FreeUserBannerAd + bottom MREC to reload
      }
    });
  }

  Future<void> _pickVideo() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );
    } catch (error) {
      _fail(error);
      return;
    }
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;
    EnhancerDebugLog.event('video picked');
    final file = File(path);
    setState(() {
      _original = file;
      _originalUrl = null;
      _jobId = null;
      _resultUrl = null;
      _sourceAspectRatio = null;
      _busy = false;
      _hasError = false;
      _status = _selectedCategory == null
          ? 'Select enhancement, then continue'
          : 'Ready to enhance';
    });
  }

  Future<void> _enhance() async {
    if (_busy) return;
    final file = _original;
    final category = _selectedCategory;
    if (file == null || category == null) return;

    final premium = Get.find<PremiumController>();
    if (!premium.hasProAccess) {
      await PremiumScreen.open(context, initialPlanId: 'pro_monthly');
      if (mounted) _resetToIdle();
      return;
    }

    setState(() {
      _busy = true;
      _hasError = false;
      _canCancel = true;
      _status = 'Uploading your video…';
    });
    try {
      final uploadId = await _service.uploadVideo(file);
      if (!mounted) return;
      setState(() => _status = 'Preparing video enhancement…');
      final estimate = await _service.createVideo(uploadId, category);
      if (!mounted) return;
      final jobId = estimate['jobId'] as String;
      await (await SharedPreferences.getInstance())
          .setString(_savedJobKey, jobId);
      await _service.acceptVideo(jobId);
      if (!mounted) return;

      setState(() {
        _busy = false;
        _status = 'Enhancing your video…';
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoEnhancementProcessingScreen(
            jobId: jobId,
            category: category,
            originalFile: file,
            originalUrl: _originalUrl,
            aspectRatio: _sourceAspectRatio,
          ),
        ),
      );

      if (!mounted) return;
      _resetToIdle();
    } catch (error) {
      if (_hasEntitlementReason(error, 'PRO_REQUIRED') ||
          _hasEntitlementReason(error, 'VIDEO_FREE_LIMIT_REACHED')) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _hasError = false;
          _status = 'Slipe AI Pro required for video remastering';
        });
        await PremiumScreen.open(context, initialPlanId: 'pro_monthly');
        if (mounted) _resetToIdle();
        return;
      }
      _fail(error);
    }
  }

  bool _hasEntitlementReason(Object error, String expectedReason) {
    if (error is! FirebaseFunctionsException) return false;
    final details = error.details;
    if (details is! Map) return false;
    return details['reason']?.toString() == expectedReason;
  }

  Future<void> _poll(String jobId) async {
    try {
      var waitingForUpload = 0;
      while (mounted && _jobId == jobId && !_canceling) {
        final state = await _service.videoStatus(jobId);
        if (!mounted || _jobId != jobId || _canceling) return;
        final status =
            state['status']?.toString().toLowerCase() ?? 'processing';
        final progress = (state['progress'] as num?)?.clamp(0, 100);
        setState(() {
          _selectedCategory = state['category'] as String? ?? _selectedCategory;
          _canCancel = progress == null || progress < 100;
          _status = status == 'complete'
              ? 'Enhanced video is ready'
              : status == 'processing' && progress != null && progress >= 100
                  ? 'Finalizing your video…'
                  : status == 'processing' && progress != null
                      ? 'Enhancing your video… ${progress.toStringAsFixed(0)}%'
                      : status;
        });
        if (status == 'complete' || status == 'completed') {
          final url = state['resultUrl'] as String?;
          if (url == null || url.isEmpty) {
            throw StateError('The enhanced video was not returned.');
          }
          await (await SharedPreferences.getInstance()).remove(_savedJobKey);
          if (mounted)
            setState(() {
              _jobId = null;
              _hasError = false;
              _selectedCategory =
                  state['category'] as String? ?? _selectedCategory;
              _originalUrl = state['originalUrl'] as String?;
              _resultUrl = url;
              _busy = false;
            });
          unawaited(AppReviewService.instance
              .onFeatureCompleted(mounted ? context : Get.context));
          return;
        }
        if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'canceled') {
          await (await SharedPreferences.getInstance()).remove(_savedJobKey);
          if (mounted) setState(() => _jobId = null);
          EnhancerDebugLog.event('video job failed', detail: 'status=$status');
          throw StateError('Video enhancement failed.');
        }
        if (status == 'requested' || status == 'accepted') {
          waitingForUpload++;
          if (waitingForUpload >= 6) {
            SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
            setState(() {
              _busy = false;
              _hasError = true;
              _jobId = null;
              _status =
                  'Upload interrupted. Tap Try again or choose another style.';
            });
            return;
          }
        } else {
          waitingForUpload = 0;
        }
        await Future<void>.delayed(const Duration(seconds: 7));
      }
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _resume() async {
    final jobId = _jobId;
    if (jobId == null) return;
    setState(() {
      _busy = true;
      _status = 'Resuming enhancement…';
    });
    try {
      final state = await _service.videoStatus(jobId);
      final status = state['status']?.toString().toLowerCase();
      if (mounted) {
        setState(() {
          _selectedCategory = state['category'] as String? ?? _selectedCategory;
          final progress = (state['progress'] as num?)?.clamp(0, 100);
          _canCancel = progress == null || progress < 100;
        });
      }
      if (status == 'requested' || status == 'accepted') {
        await _service.acceptVideo(jobId);
      }
      if (mounted) await _poll(jobId);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _cancelEnhancement() async {
    final jobId = _jobId;
    if (jobId == null || _canceling) return;
    setState(() {
      _canceling = true;
      _status = 'Canceling video enhancement…';
    });
    try {
      final result = await _service.cancelVideo(jobId);
      if (result['canceled'] != true) {
        if (!mounted) return;
        setState(() {
          _canceling = false;
          _canCancel = false;
          _status = 'Finalizing your video…';
        });
        await _poll(jobId);
        return;
      }
      await (await SharedPreferences.getInstance()).remove(_savedJobKey);
      if (!mounted) return;
      setState(() {
        _jobId = null;
        _busy = false;
        _canceling = false;
        _hasError = false;
        _status = _original == null
            ? 'Choose a video to enhance'
            : _selectedCategory == null
                ? 'Select enhancement, then continue'
                : 'Ready to enhance';
      });
      EnhancerDebugLog.event('video enhancement canceled');
    } catch (error) {
      if (!mounted) return;
      final message = MediaFailure.message(error, media: 'video');
      setState(() {
        _busy = true;
        _canceling = false;
        _hasError = true;
        _status = 'Could not cancel. Enhancement is still running.';
      });
      EnhancerDebugLog.failure('cancel video enhancement', error);
      EnhancerErrorNotice.show(context, message);
      await _poll(jobId);
    }
  }

  void _removeVideo() {
    if (_busy) return;
    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
    setState(() {
      _original = null;
      _originalUrl = null;
      _resultUrl = null;
      _jobId = null;
      _sourceAspectRatio = null;
      _hasError = false;
      _status = 'Choose a video to enhance';
    });
  }

  void _fail(Object error) {
    if (!mounted) return;
    EnhancerDebugLog.failure('video enhancement', error);
    final message = MediaFailure.message(error, media: 'video');
    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
    setState(() {
      _busy = false;
      _jobId = null;
      _hasError = true;
      _status = message;
    });
    EnhancerErrorNotice.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSurface;
    final screenSize = MediaQuery.sizeOf(context);
    final stageHeight = (_original == null || _sourceAspectRatio == null)
        ? (screenSize.height * 0.28).clamp(210.0, 250.0)
        : (screenSize.width / _sourceAspectRatio!)
            .clamp(160.0, screenSize.height * 0.65);
    final canRemove = !_busy &&
        (_original != null || _originalUrl != null || _resultUrl != null);
    EnhancementStyle? appliedStyle;
    for (final style in videoEnhancementStyles) {
      if (style.id == _selectedCategory) {
        appliedStyle = style;
        break;
      }
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    Future<void> openHistory() async {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const EnhancementHistoryScreen(),
      ));
      if (!mounted) return;
      _resetToIdle();
    }

    return Theme(
      data: EnhancerStyle.theme(context),
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Center(
                  child: _buildTopBackButton(context, dark),
                ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    EnhancerPageHeader(
                      title: _resultUrl != null
                          ? 'Remastered Video'
                          : appliedStyle?.label ?? 'AI Video Remaster',
                      onHistory: openHistory,
                    ),
                    Container(
                      width: double.infinity,
                      height: _resultUrl == null ? stageHeight : null,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: (_original == null && _resultUrl == null)
                            ? Colors.transparent
                            : scheme.surfaceContainer,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Stack(children: [
                        if (_resultUrl != null)
                          VideoComparisonView(
                            beforeUrl: _originalUrl ?? _resultUrl!,
                            afterUrl: _resultUrl!,
                            hasOriginal: _originalUrl != null,
                            edgeToEdge: true,
                            onRemove: canRemove ? _removeVideo : null,
                          )
                        else
                          Positioned.fill(
                            child: _original != null
                                ? SelectedVideoPreview(
                                    key: ValueKey(_original!.path),
                                    file: _original!,
                                    enabled: !_busy,
                                    onAspectRatio: (ratio) {
                                      if (mounted) {
                                        setState(
                                            () => _sourceAspectRatio = ratio);
                                      }
                                    },
                                  )
                                : EnhancerEmptyStage(
                                    icon: Icons.video_call_outlined,
                                    title: 'Add a video',
                                    detail: 'MP4 · Up to 75 MB',
                                    onTap: _busy ? null : _pickVideo,
                                  ),
                          ),
                        if (canRemove && _resultUrl == null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              tooltip: 'Remove video',
                              onPressed: _removeVideo,
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surface,
                                foregroundColor: foreground,
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        if (_busy)
                          Positioned.fill(
                            child: const EnhancementLoadingIndicator(),
                          ),
                      ]),
                    ),
                    if (_resultUrl != null) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Icon(appliedStyle?.icon ?? Icons.auto_awesome_rounded,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 9),
                          Text('Enhanced with ',
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                          Expanded(
                            child: Text(
                                appliedStyle?.label ?? 'Video enhancement',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: foreground,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ],
                    if (appliedStyle != null && _resultUrl == null)
                      _buildSelectedOptionCard(
                        context,
                        scheme,
                        appliedStyle,
                      ),
                    if (_status.isNotEmpty &&
                        (_original != null ||
                            _busy ||
                            _resultUrl != null ||
                            _jobId != null)) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(_status,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 46),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (dark ? Colors.white : Colors.black)
                                  .withValues(alpha: dark ? 0.14 : 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            if (dark)
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.08),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : _jobId != null
                                  ? _resume
                                  : _original == null || _resultUrl != null
                                      ? _pickVideo
                                      : _selectedCategory == null
                                          ? null
                                          : _enhance,
                          icon: Icon(_hasError
                              ? Icons.refresh_rounded
                              : Icons.auto_fix_high_rounded),
                          label: Text(_jobId != null && _resultUrl == null
                              ? 'Retry upload'
                              : _original == null
                                  ? 'Choose video'
                                  : _resultUrl != null
                                      ? 'Enhance another video'
                                      : _hasError
                                          ? 'Try again'
                                          : 'Continue'),
                        ),
                      ),
                    ),
                    if (_busy && _jobId != null && _canCancel) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 46),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (dark ? Colors.white : Colors.black)
                                    .withValues(alpha: dark ? 0.08 : 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: OutlinedButton.icon(
                            onPressed: _canceling ? null : _cancelEnhancement,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _canceling
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.stop_circle_outlined),
                            label: Text(_canceling
                                ? 'Canceling…'
                                : 'Cancel enhancement'),
                          ),
                        ),
                      ),
                    ],
                    if (_resultUrl != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 46),
                        child: EnhancementSaveButton(
                          url: _resultUrl!,
                          isVideo: true,
                          label: 'Save enhanced video',
                        ),
                      ),
                      if (Get.isRegistered<PremiumController>() &&
                          Get.find<PremiumController>().shouldShowFreeAds) ...[
                        LoadingPageAd(
                          key: ValueKey('mrec_$_adRefreshKey'),
                          margin: const EdgeInsets.symmetric(horizontal: 20)
                              .copyWith(top: 24, bottom: 20),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOptionCard(
    BuildContext context,
    ColorScheme scheme,
    EnhancementStyle style,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = scheme.primary.withValues(alpha: dark ? 0.18 : 0.12);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy ? null : () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      style.icon,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Selected: ',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                            letterSpacing: 0.1,
                          ),
                        ),
                        TextSpan(
                          text: style.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF242426) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (dark ? Colors.white : Colors.black)
                            .withValues(alpha: dark ? 0.14 : 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: (dark ? Colors.white : Colors.black)
                            .withValues(alpha: dark ? 0.06 : 0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: dark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBackButton(BuildContext context, bool dark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F1F1F) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.12 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.05 : 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: 'Back',
            child: Center(
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
