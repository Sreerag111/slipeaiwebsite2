import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';


import '../widgets/enhancement_save_button.dart';
import '../widgets/adaptive_image_frame.dart';
import '../widgets/enhancer_style.dart';
import '../widgets/enhancement_style_selector.dart';
import '../widgets/photo_comparison_view.dart';
import '../widgets/video_comparison_view.dart';

String _enhancementTitle(Map<String, dynamic> data) {
  final isVideo = data['type'] == 'video';
  final styles = isVideo ? videoEnhancementStyles : photoEnhancementStyles;
  for (final style in styles) {
    if (style.id == data['category']) return style.label;
  }
  return isVideo ? 'Enhanced video' : 'Enhanced photo';
}

Widget _buildTopBackButton(BuildContext context, bool isDark) {
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
        onTap: () => Navigator.of(context).pop(),
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

class EnhancementHistoryScreen extends StatefulWidget {
  const EnhancementHistoryScreen({super.key});

  @override
  State<EnhancementHistoryScreen> createState() =>
      _EnhancementHistoryScreenState();
}

class _EnhancementHistoryScreenState extends State<EnhancementHistoryScreen> {
  String _filter = 'all';
  void _openHistoryDetail(Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HistoryDetail(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final color = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: EnhancerStyle.theme(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Center(
            child: _buildTopBackButton(context, isDark),
          ),
          title: const Text('Enhancement history'),
        ),
        body: user == null
            ? const Center(child: Text('Sign in to view your history.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('enhancements')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Could not load history.'),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final entries = snapshot.data!.docs.where((doc) {
                          final data = doc.data();
                          return data['status'] == 'complete' &&
                              data['resultUrl'] is String &&
                              data['originalUrl'] is String &&
                              (_filter == 'all' || data['type'] == _filter);
                        }).toList();

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                              'Your best work, kept together.',
                              style: EnhancerStyle.heading(context, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Revisit originals and enhanced results anytime.',
                              style: EnhancerStyle.body(
                                context,
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                for (final option in const [
                                  ('all', 'All'),
                                  ('photo', 'Photos'),
                                  ('video', 'Videos')
                                ]) ...[
                                  ChoiceChip(
                                    label: Text(option.$2),
                                    selected: _filter == option.$1,
                                    onSelected: (_) =>
                                        setState(() => _filter = option.$1),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (entries.isEmpty)
                              Container(
                                height: 260,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color.surfaceContainer,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_outlined, size: 42),
                                    SizedBox(height: 12),
                                    Text('No enhancements yet'),
                                  ],
                                ),
                              ),
                            for (final entry in entries)
                              _HistoryCard(
                                data: entry.data(),
                                onTap: () => _openHistoryDetail(entry.data()),
                              ),
                          ],
                        );
                      },
                    ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = data['type'] == 'video';
    final color = Theme.of(context).colorScheme;
    final created = data['createdAt'];
    final date = created is Timestamp
        ? DateFormat('d MMM yyyy • h:mm a').format(created.toDate())
        : 'Recent enhancement';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: 98,
                child: isVideo
                    ? ColoredBox(
                        color: color.onSurface,
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: color.surface,
                          size: 40,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: data['resultUrl'] as String,
                        fit: BoxFit.cover,
                        memCacheWidth: 320,
                        placeholder: (_, __) =>
                            ColoredBox(color: color.surfaceContainer),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _enhancementTitle(data),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: TextStyle(
                        color: color.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'View before & after',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  const _HistoryDetail({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVideo = data['type'] == 'video';
    final before = data['originalUrl'] as String;
    final after = data['resultUrl'] as String;

    return Theme(
      data: EnhancerStyle.theme(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Center(
            child: _buildTopBackButton(context, isDark),
          ),
          title: Text(_enhancementTitle(data)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
                    Text(
                      'Before. After. Better.',
                      style: EnhancerStyle.heading(context, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVideo
                          ? 'Switch between Before and After.'
                          : 'Drag across the photo to reveal the difference.',
                    ),
                    const SizedBox(height: 22),
                    if (isVideo)
                      VideoComparisonView(beforeUrl: before, afterUrl: after)
                    else
                      AdaptiveImageFrame(
                        image: CachedNetworkImageProvider(before),
                        imageKey: before,
                        fallbackHeight: 390,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PhotoComparisonView(
                            before: CachedNetworkImageProvider(before),
                            after: CachedNetworkImageProvider(after),
                            transparentBackground:
                                data['category'] == 'remove_background',
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    EnhancementSaveButton(
                      url: after,
                      isVideo: isVideo,
                      label: 'Save enhanced result',
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
