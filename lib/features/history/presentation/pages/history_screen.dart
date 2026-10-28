import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/theme_controller.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../domain/entities/history_item.dart';
import '../controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final HistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = Get.find<HistoryController>();
    _searchController.addListener(() {
      _historyController.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRiskColor(double score) {
    if (score >= 70) return AppTheme.danger;
    if (score >= 40) return AppTheme.warning;
    if (score >= 20) return AppTheme.accent;
    return AppTheme.success;
  }

  Color _historyColor(HistoryItem item, bool isDark) {
    switch (item.type) {
      case 'chat':
        return isDark ? Colors.white : AppTheme.accent;
      case 'grammar':
        return const Color(0xFF94A3B8);
      default:
        return _getRiskColor(item.plagiarismScore ?? 0);
    }
  }

  String _historyLabel(String type) {
    switch (type) {
      case 'chat':
        return 'Chat';
      case 'grammar':
        return 'Grammar';
      default:
        return 'Plagiarism';
    }
  }

  String _formatDate(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp);
      return '${DateFormat('MMM d, yyyy').format(dt)} - ${DateFormat('h:mm a').format(dt)}';
    } catch (_) {
      return isoTimestamp;
    }
  }

  String _promptText(HistoryItem item) => item.fullText ?? item.textSnippet;

  String _responseText(HistoryItem item) =>
      item.fullResponse ?? item.responseSnippet ?? '';

  Future<void> _deleteItem(HistoryItem item) async {
    await _historyController.deleteItem(item);
    if (!mounted) return;
    final isDark = ThemeController.instance.isDarkMode;
    showTopSnackBar(
      context,
      'History item deleted',
      color: isDark ? AppTheme.card : Colors.black,
    );
  }

  void _showHistoryDetail(HistoryItem item) {
    final isDark = ThemeController.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _historyColor(item, isDark)
                          .withValues(alpha: isDark ? 0.14 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _historyLabel(item.type).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _historyColor(item, isDark),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteItem(item);
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(item.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                ),
              ),
              if (item.type == 'chat' && item.conversationId != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Get.find<ChatController>()
                          .loadAndOpenThread(item.conversationId!);
                      if (mounted) Navigator.pop(context);
                    },
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      'Continue Chat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _detailSection('Prompt', _promptText(item), isDark),
                    if (_responseText(item).trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _detailSection('Response', _responseText(item), isDark),
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

  Widget _detailSection(String title, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF8E8E93) : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: SelectableText(
            value.trim().isEmpty ? 'No content saved' : value,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
          title: Text(
            'HISTORY',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            Obx(
              () => _historyController.history.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () async {
                        await _historyController.clearHistory();
                      },
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                      ),
                      tooltip: 'Clear All',
                    ),
            ),
          ],
        ),
        body: Obx(
          () => _historyController.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                )
              : Column(
                  children: [
                    _buildSearchBar(isDark),
                    Expanded(
                      child: _historyController.history.isEmpty
                          ? _buildEmptyState(isDark)
                          : _historyController.filteredHistory.isEmpty
                              ? _buildSearchEmptyState(isDark)
                              : _buildHistoryList(
                                  _historyController.filteredHistory,
                                  isDark,
                                ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search history',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? const Color(0xFF8E8E93) : Colors.black54,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF8E8E93) : Colors.black,
          ),
          suffixIcon: Obx(
            () => _historyController.searchQuery.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: _searchController.clear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.black,
                    ),
                  ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: isDark
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: isDark
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.accent),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'No Analysis History',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your past analyses will appear here',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? const Color(0xFF8E8E93) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 14),
            Text(
              'No matching history',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or clear the search box.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? const Color(0xFF8E8E93) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> items, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return RepaintBoundary(
          child: Column(
            children: [
              InkWell(
                onTap: () => _showHistoryDetail(item),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.textSnippet,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.responseSnippet != null &&
                          item.responseSnippet!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.responseSnippet!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color:
                                isDark ? const Color(0xFF8E8E93) : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        _formatDate(item.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color:
                              isDark ? const Color(0xFF636366) : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFE2E8F0),
                height: 1,
              ),
            ],
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: (index * 24).clamp(0, 180)))
              .slideY(begin: 0.03),
        );
      },
    );
  }
}
