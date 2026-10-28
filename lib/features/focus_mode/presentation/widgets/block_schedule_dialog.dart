import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/theme_controller.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/focus_block_schedule.dart';

Color get kFocusAccent => AppTheme.accent;

/// Shown when the user toggles ON a specific app in the Blocked Apps list.
/// Returns the chosen [FocusBlockSchedule], or null if the user cancelled
/// (in which case the caller must NOT turn the toggle on).
Future<FocusBlockSchedule?> showBlockScheduleDialog(
  BuildContext context, {
  required String appName,
  FocusBlockSchedule? initial,
}) {
  final now = TimeOfDay.now();
  final defaultStart = initial?.start ?? now;
  final defaultEnd =
      initial?.end ?? TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);

  return showModalBottomSheet<FocusBlockSchedule>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BlockScheduleSheet(
      appName: appName,
      initialStart: defaultStart,
      initialEnd: defaultEnd,
      initialDays: initial?.days ?? kWeekdays,
    ),
  );
}

class _BlockScheduleSheet extends StatefulWidget {
  const _BlockScheduleSheet({
    required this.appName,
    required this.initialStart,
    required this.initialEnd,
    required this.initialDays,
  });

  final String appName;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final Set<Weekday> initialDays;

  @override
  State<_BlockScheduleSheet> createState() => _BlockScheduleSheetState();
}

class _BlockScheduleSheetState extends State<_BlockScheduleSheet> {
  late TimeOfDay _start = widget.initialStart;
  late TimeOfDay _end = widget.initialEnd;
  late Set<Weekday> _days = {...widget.initialDays};

  bool get _canConfirm => _days.isNotEmpty;

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (_toMinutes(_end) <= _toMinutes(_start)) {
        _end = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked == null) return;
    setState(() => _end = picked);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _toggleDay(Weekday day) {
    setState(() {
      if (_days.contains(day)) {
        _days.remove(day);
      } else {
        _days.add(day);
      }
    });
  }

  String get _daysSummary {
    if (_days.length == 7) return 'Every day';
    if (setEquals(_days, kWeekdays)) return 'Weekdays';
    if (setEquals(_days, {Weekday.sat, Weekday.sun})) return 'Weekends';
    if (_days.isEmpty) return 'Select days';
    return '${_days.length} day${_days.length > 1 ? 's' : ''}';
  }

  void _confirm() {
    if (!_canConfirm) return;

    Navigator.of(context).pop(
      FocusBlockSchedule(start: _start, end: _end, days: _days),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final l = MaterialLocalizations.of(context);

      final sheetBg = isDark ? const Color(0xFF15151A) : Colors.white;
      final cardBg = isDark
          ? Colors.white.withValues(alpha: .06)
          : const Color(0xFFF5F6F8);
      final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
      final mutedColor = isDark ? Colors.white54 : Colors.black54;
      final dividerColor = isDark ? Colors.white12 : Colors.black12;
      final circleBtnBg =
          isDark ? Colors.white10 : Colors.black.withValues(alpha: .05);

      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Grabber
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // ── Header row: back / title / (spacer to keep title centered)
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      background: circleBtnBg,
                      iconColor: textColor,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42), // balances the back button
                  ],
                ),
                const SizedBox(height: 24),

                // ── During this time
                _SectionLabel(
                  icon: Icons.calendar_today_rounded,
                  label: 'During this time',
                  color: mutedColor,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Connector: filled dot -> dashed line -> hollow ring
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kFocusAccent,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 1.4,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  color: mutedColor.withValues(alpha: .35),
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: mutedColor, width: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              _TimeRow(
                                label: 'From',
                                time: l.formatTimeOfDay(_start,
                                    alwaysUse24HourFormat: false),
                                textColor: textColor,
                                mutedColor: mutedColor,
                                onTap: _pickStart,
                              ),
                              Divider(height: 1, color: dividerColor),
                              _TimeRow(
                                label: 'To',
                                time: l.formatTimeOfDay(_end,
                                    alwaysUse24HourFormat: false),
                                textColor: textColor,
                                mutedColor: mutedColor,
                                onTap: _pickEnd,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ── On these days
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'On these days: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _daysSummary,
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: Weekday.values.map((day) {
                          final selected = _days.contains(day);
                          return GestureDetector(
                            onTap: () => _toggleDay(day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? kFocusAccent
                                    : (isDark ? Colors.white10 : Colors.white),
                                border: selected
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                      ),
                              ),
                              child: Text(
                                day.initial,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppTheme.onAccent
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                if (!_canConfirm) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Select at least one day',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ],

                const SizedBox(height: 26),

                // ── Hold to Commit
                GestureDetector(
                  onTap: _canConfirm ? _confirm : null,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      color: _canConfirm
                          ? kFocusAccent
                          : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: .06)),
                    ),
                    child: Text(
                      'Commit',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _canConfirm ? AppTheme.onAccent : mutedColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final String time;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: textColor)),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more_rounded, size: 18, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
