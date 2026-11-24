import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/blocked_customer.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Settings → Blocked customers. Orders from these numbers / buyers are
/// refused by firestore.rules.
class BlockedCustomersScreen extends ConsumerWidget {
  const BlockedCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final list = ref.watch(blockedCustomersProvider);
    final loading = ref.watch(blockedEntriesProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(ss.blockedCustomers),
      ),
      body: list.isEmpty
          ? Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : EmptyHint(
                      icon: Icons.block_rounded,
                      title: ss.noBlockedTitle,
                      body: ss.noBlockedBody,
                    ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BlockedRow(customer: list[i]),
            ),
    );
  }
}

class _BlockedRow extends ConsumerWidget {
  const _BlockedRow({required this.customer});

  final BlockedCustomer customer;

  void _unblock(BuildContext context, WidgetRef ref) {
    final ss = ref.read(storeStringsProvider);
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    backgroundWrite(repo.unblock(uid, customer.keys), ss);
    context.showInfoSnack(ss.customerUnblocked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final title = customer.name.isNotEmpty
        ? customer.name
        : customer.phone.isNotEmpty
            ? customer.phone
            : ss.blockedBadge;
    final date = customer.createdAt == null
        ? null
        : DateFormat('d MMM yyyy').format(customer.createdAt!);
    final sub = [
      if (customer.name.isNotEmpty && customer.phone.isNotEmpty) customer.phone,
      if (date != null) ss.blockedOn(date),
    ].join(' · ');

    return CreamCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block_rounded,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => _unblock(context, ref),
            child: Text(ss.unblock),
          ),
        ],
      ),
    );
  }
}
