import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/history_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

/// Search + sort row for History (period lives in shell header).
class HistoryToolbar extends ConsumerStatefulWidget {
  const HistoryToolbar({super.key, required this.strings});

  final AppStrings strings;

  @override
  ConsumerState<HistoryToolbar> createState() => _HistoryToolbarState();
}

class _HistoryToolbarState extends ConsumerState<HistoryToolbar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(historySearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showSortSheet() async {
    final s = widget.strings;
    final current = ref.read(historySortProvider);
    final picked = await showAppOptionsBottomSheet<HistorySort>(
      context: context,
      title: s.sortBy,
      options: HistorySort.values
          .map(
            (sort) => AppBottomSheetOption(
              value: sort,
              label: _sortLabel(s, sort),
              selected: current == sort,
            ),
          )
          .toList(),
    );
    if (picked != null) {
      ref.read(historySortProvider.notifier).state = picked;
    }
  }

  String _sortLabel(AppStrings s, HistorySort sort) {
    switch (sort) {
      case HistorySort.newest:
        return s.newestFirst;
      case HistorySort.oldest:
        return s.oldestFirst;
      case HistorySort.amountHigh:
        return s.amountHighToLow;
      case HistorySort.amountLow:
        return s.amountLowToHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(historySearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (v) =>
                    ref.read(historySearchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: widget.strings.searchTransactions,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(historySearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ToolbarIcon(
            icon: Icons.sort_rounded,
            onTap: _showSortSheet,
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
