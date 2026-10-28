import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/theme_controller.dart';
import '../../domain/entities/chat_source.dart';

class ChatSourcesView extends StatelessWidget {
  const ChatSourcesView({
    super.key,
    required this.sources,
  });

  final List<ChatSource> sources;

  Future<void> _openSource(BuildContext context, ChatSource source) async {
    HapticFeedback.lightImpact();
    try {
      final uri = Uri.parse(source.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ChatSourcesView] Could not launch ${source.url}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final isDark = ThemeController.instance.isDarkMode;
    final headerTextColor = isDark ? Colors.white70 : Colors.black;
    final badgeBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0);
    final badgeTextColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Sources (N)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: headerTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sources',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: headerTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sources.length}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable cards
          SizedBox(
            height: 80,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) => true,
              child: SingleChildScrollView(
                key: PageStorageKey<String>(
                    'sources-${sources.isNotEmpty ? sources.first.url.hashCode : 0}'),
                scrollDirection: Axis.horizontal,
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (int index = 0; index < sources.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      _SourceCard(
                        source: sources[index],
                        isDark: isDark,
                        onTap: () => _openSource(context, sources[index]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.isDark,
    required this.onTap,
  });

  final ChatSource source;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
        : Border.all(color: const Color(0xFFE2E8F0), width: 1);
    final titleColor = isDark ? Colors.white : Colors.black;
    final domainColor = isDark ? Colors.white60 : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 175,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: cardBorder,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Domain + Favicon row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      source.faviconUrl,
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.language_rounded,
                        size: 14,
                        color: domainColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source.displayDomain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: domainColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 11,
                    color: domainColor,
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Title
              Text(
                source.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
