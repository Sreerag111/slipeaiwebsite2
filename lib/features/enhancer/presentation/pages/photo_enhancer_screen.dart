import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/media_failure.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/pages/premium_screen.dart';
import '../../data/enhancer_debug_log.dart';
import '../widgets/enhancer_error_notice.dart';
import '../widgets/adaptive_image_frame.dart';
import '../widgets/enhancement_save_button.dart';
import '../widgets/enhancement_style_selector.dart';
import '../widgets/enhancer_style.dart';
import '../widgets/enhancer_page_chrome.dart';
import '../widgets/enhancement_loading_indicator.dart';
import '../widgets/photo_comparison_view.dart';
import '../widgets/photo_zoom_view.dart';
import 'enhancement_history_screen.dart';
import 'enhancement_processing_screen.dart';

class PhotoEnhancerScreen extends StatefulWidget {
  const PhotoEnhancerScreen({
    super.key,
    this.embedded = false,
    this.initialCategory,
  });

  final bool embedded;
  final String? initialCategory;

  @override
  State<PhotoEnhancerScreen> createState() => _PhotoEnhancerScreenState();
}

class _PhotoEnhancerScreenState extends State<PhotoEnhancerScreen>
    with RouteAware {
  static const _savedJobKey = 'topaz_photo_job_id';
  File? _original;
  String? _originalUrl;
  String? _resultUrl;
  String? _jobId;
  String? _selectedCategory;
  String? _resultCategory;
  String _status = '';
  bool _busy = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? photoEnhancementStyles.first.id;
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
    // When returning from History, Upgrade, or Result screen, refresh page & ads
    if (mounted) {
      _resetToIdle();
    }
  }

  void _resetToIdle() {
    if (Get.isRegistered<PremiumController>()) {
      Get.find<PremiumController>().refreshMediaUsage();
    }
    setState(() {
      _original = null;
      _originalUrl = null;
      _resultUrl = null;
      _resultCategory = null;
      _jobId = null;
      _busy = false;
      _hasError = false;
      _status = _selectedCategory == null
          ? 'Select enhancement, then continue'
          : 'Ready to enhance';
    });
  }

  Future<void> _restoreJob() async {
    final jobId =
        (await SharedPreferences.getInstance()).getString(_savedJobKey);
    if (jobId == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EnhancementProcessingScreen(
          existingJobId: jobId,
          category: _selectedCategory ?? photoEnhancementStyles.first.id,
          isVideo: false,
        ),
      ),
    );
    if (!mounted) return;
    _resetToIdle();
  }

  Future<void> _pickPhoto() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (error) {
      _fail(error);
      return;
    }
    if (picked == null || !mounted) return;
    EnhancerDebugLog.event('photo picked');
    final file = File(picked.path);
    setState(() {
      _original = file;
      _originalUrl = null;
      _jobId = null;
      _resultUrl = null;
      _resultCategory = null;
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
    setState(() {
      _busy = true;
      _status = 'Checking enhancement access…';
    });
    await Get.find<PremiumController>().refreshMediaUsage();
    if (!mounted) return;
    final premium = Get.find<PremiumController>();
    if (!premium.hasPhotoAccess) {
      setState(() {
        _busy = false;
        _status = 'Slipe AI Lite required to continue';
      });
      await PremiumScreen.open(context, initialPlanId: 'lite_monthly');
      if (mounted) _resetToIdle();
      return;
    }

    setState(() {
      _busy = false;
    });

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EnhancementProcessingScreen(
          originalFile: file,
          originalUrl: _originalUrl,
          category: category,
          isVideo: false,
        ),
      ),
    );

    if (!mounted) return;
    _resetToIdle();
  }

  void _resume() {
    final jobId = _jobId;
    if (jobId == null) return;
    _restoreJob();
  }

  void _removePhoto() {
    if (_busy) return;
    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
    setState(() {
      _original = null;
      _originalUrl = null;
      _resultUrl = null;
      _resultCategory = null;
      _jobId = null;
      _status = '';
    });
  }

  void _fail(Object error) {
    if (!mounted) return;
    EnhancerDebugLog.failure('photo enhancement', error);
    final message = MediaFailure.message(error, media: 'photo');
    SharedPreferences.getInstance().then((p) => p.remove(_savedJobKey));
    setState(() {
      _busy = false;
      _jobId = null;
      _hasError = true;
      _status = message;
    });
    EnhancerErrorNotice.show(context, message);
  }

  Widget _stageTag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final result = _resultUrl;
    EnhancementStyle? appliedStyle;
    for (final style in photoEnhancementStyles) {
      if (style.id == _resultCategory) {
        appliedStyle = style;
        break;
      }
    }
    EnhancementStyle? selectedStyle;
    for (final style in photoEnhancementStyles) {
      if (style.id == _selectedCategory) {
        selectedStyle = style;
        break;
      }
    }
    selectedStyle ??= photoEnhancementStyles.first;
    final canRemove =
        !_busy && (_original != null || _originalUrl != null || result != null);
    ImageProvider? before;
    if (_original != null) {
      before = FileImage(_original!);
    } else if (_originalUrl != null) {
      before = CachedNetworkImageProvider(_originalUrl!);
    }
    final stageHeight = (MediaQuery.sizeOf(context).height * 0.60);
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
          body: SafeArea(
              child: Column(
            children: [
              if (!widget.embedded)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildTopButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        dark: dark,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedStyle.label,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      _buildTopButton(
                        icon: Icons.history_rounded,
                        tooltip: 'History',
                        dark: dark,
                        onTap: openHistory,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (widget.embedded)
                      EnhancerPageHeader(
                        title: result != null
                            ? 'Enhanced Photo'
                            : 'AI Photo Enhancer',
                        onHistory: openHistory,
                      ),
                    AdaptiveImageFrame(
                      image: before ??
                          (result != null
                              ? CachedNetworkImageProvider(result)
                              : null),
                      imageKey: _original?.path ?? _originalUrl ?? result,
                      fallbackHeight: stageHeight,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                      minHeight: 0,
                      child: Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: (before == null && result == null)
                              ? Colors.transparent
                              : scheme.surfaceContainer,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Stack(children: [
                          Positioned.fill(
                            child: result != null && before != null
                                ? PhotoComparisonView(
                                    before: before,
                                    after: CachedNetworkImageProvider(result),
                                    transparentBackground:
                                        _resultCategory == 'remove_background')
                                : _original != null
                                    ? Image.file(_original!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity)
                                    : result != null
                                        ? CachedNetworkImage(
                                            imageUrl: result,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                            placeholder: (_, __) =>
                                                const EnhancementLoadingIndicator(),
                                            errorWidget: (_, __, ___) => Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: scheme.onSurfaceVariant,
                                                size: 36,
                                              ),
                                            ),
                                          )
                                        : EnhancerEmptyStage(
                                            icon: Icons
                                                .add_photo_alternate_outlined,
                                            title: 'Add a photo',
                                            detail:
                                                'JPG, PNG, WEBP or TIFF · Up to 10 MB',
                                            onTap: _busy || _jobId != null
                                                ? null
                                                : _pickPhoto,
                                            imageCards: EnhancerEmptyStage
                                                .defaultPhotoCards,
                                          ),
                          ),
                          if (_original != null && result == null && !_busy)
                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: _stageTag('Before'),
                            ),
                          if (canRemove)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton(
                                tooltip: 'Remove photo',
                                onPressed: _removePhoto,
                                style: IconButton.styleFrom(
                                  backgroundColor: scheme.surface,
                                  foregroundColor: scheme.onSurface,
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          if (before != null || result != null)
                            Positioned(
                              left: 12,
                              top: 12,
                              child: IconButton.filledTonal(
                                tooltip: 'Zoom photo',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PhotoZoomView(
                                      image: result != null
                                          ? CachedNetworkImageProvider(result)
                                          : before!,
                                      transparentBackground: result != null &&
                                          _resultCategory ==
                                              'remove_background',
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.zoom_in_rounded),
                              ),
                            ),
                          if (_busy)
                            Positioned.fill(
                              child: const EnhancementLoadingIndicator(),
                            ),
                        ]),
                      ),
                    ),
                    if (result != null && before != null) ...[
                      const SizedBox(height: 10),
                      Text('Drag to compare',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                    if (result != null) ...[
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
                                appliedStyle?.label ?? 'Photo enhancement',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ],
                    if (result == null) ...[
                      _buildSelectedOptionCard(
                        context,
                        scheme,
                        selectedStyle,
                      ),
                    ],
                    if (_status.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: Text(_status,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 46),
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : _jobId != null
                                ? _resume
                                : _original == null || result != null
                                    ? _pickPhoto
                                    : _selectedCategory == null
                                        ? null
                                        : _enhance,
                        icon: Icon(_hasError
                            ? Icons.refresh_rounded
                            : _jobId != null
                                ? Icons.refresh_rounded
                                : Icons.auto_fix_high_rounded),
                        label: Text(_jobId != null
                            ? 'Resume enhancement'
                            : _original == null
                                ? 'Choose photo'
                                : result != null
                                    ? 'Enhance another photo'
                                    : _hasError
                                        ? 'Try again'
                                        : 'Continue'),
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 46),
                        child: EnhancementSaveButton(
                          url: result,
                          isVideo: false,
                          label: 'Save enhanced photo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          )),
        ));
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

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool dark,
    String? tooltip,
  }) {
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
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip ?? '',
            child: Center(
              child: Icon(
                icon,
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
