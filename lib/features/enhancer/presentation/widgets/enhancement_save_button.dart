import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/error/media_failure.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';
import '../../../premium/presentation/widgets/premium_media_preview.dart';
import '../../data/enhancer_debug_log.dart';
import '../utils/enhancement_export.dart';
import 'enhancer_error_notice.dart';

class EnhancementSaveButton extends StatefulWidget {
  const EnhancementSaveButton({
    super.key,
    required this.url,
    required this.isVideo,
    required this.label,
  });

  final String url;
  final bool isVideo;
  final String label;

  @override
  State<EnhancementSaveButton> createState() => _EnhancementSaveButtonState();
}

class _EnhancementSaveButtonState extends State<EnhancementSaveButton> {
  String? _stage;
  bool _dialogOpen = false;

  Future<void> _save({bool rewardedSave = false}) async {
    if (_stage != null) return;
    setState(() => _stage = 'Checking access…');
    try {
      await saveEnhancement(
        context,
        url: widget.url,
        isVideo: widget.isVideo,
        allowRewardedSave: rewardedSave,
        onStage: (stage) {
          if (mounted) setState(() => _stage = stage);
        },
      );
    } catch (error) {
      EnhancerDebugLog.failure('save enhancement', error);
      if (mounted)
        EnhancerErrorNotice.show(
            context,
            MediaFailure.message(error,
                media: widget.isVideo ? 'video' : 'photo', action: 'save'));
    } finally {
      if (mounted) setState(() => _stage = null);
    }
  }

  Future<void> _requestSave() async {
    if (_stage != null || _dialogOpen) return;
    final premium = Get.find<PremiumController>();
    if (premium.canExportEnhancement(isVideo: widget.isVideo)) {
      await _save();
      return;
    }
    _dialogOpen = true;
    try {
      await showPremiumDialog(
        context,
        initialPlanId: widget.isVideo ? 'pro_monthly' : 'lite_monthly',
        offerRewardedSave:
            widget.isVideo ? false : premium.shouldShowFreeAds,
        mediaPreview:
            PremiumMediaPreview(source: widget.url, isVideo: widget.isVideo),
        onRewardedImageGranted: () async {
          if (mounted) await _save(rewardedSave: true);
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => _button(
        onPressed: _requestSave,
        label: widget.label,
      );

  Widget _button({
    required Future<void> Function() onPressed,
    required String label,
    IconData icon = Icons.download_rounded,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
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
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _stage == null ? onPressed : null,
        icon: _stage == null
            ? Icon(icon)
            : SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
        label: Text(
          _stage ?? label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
