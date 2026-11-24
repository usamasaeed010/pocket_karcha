import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/store_model.dart';
import 'package:pocket_karcha/features/products/presentation/paste_list_screen.dart';
import 'package:pocket_karcha/features/products/presentation/product_form_screen.dart';
import 'package:pocket_karcha/features/share_kit/presentation/share_kit_screen.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/features/store_home/widgets/order_alerts_card.dart';
import 'package:pocket_karcha/features/store_settings/presentation/backup_screen.dart';
import 'package:pocket_karcha/features/store_settings/presentation/store_link_screen.dart';
import 'package:pocket_karcha/features/voice/voice_entry_sheet.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openOrdersWith(WidgetRef ref, OrderFilter filter) {
    ref.read(ordersSegmentProvider.notifier).state = 0;
    ref.read(orderFilterProvider.notifier).state = filter;
    ref.read(storeTabProvider.notifier).state = StoreTabs.orders;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final storeAsync = ref.watch(storeProvider);
    final store = storeAsync.valueOrNull;

    if (store == null) {
      // Loaded, but this account has no store (e.g. setup never finished).
      if (storeAsync.hasValue && !storeAsync.isLoading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyHint(
              icon: Icons.storefront_rounded,
              title: ss.noStoreTitle,
              body: ss.noStoreBody,
              action: FilledButton(
                onPressed: () => AppNavigator.toStoreSetup(context),
                child: Text(ss.createMyStore),
              ),
            ),
          ),
        );
      }
      return Center(
        child: storeAsync.hasError
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ss.checkInternet, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(storeProvider),
                      child: Text(ss.retry),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      );
    }

    final money = ref.watch(moneyProvider);
    final kpis = ref.watch(orderKpisProvider);
    final stats = ref.watch(storeStatsProvider).valueOrNull ?? const StoreStats();
    final orders = ref.watch(orderListProvider);
    final productsAsync = ref.watch(productsProvider);
    final noProducts = productsAsync.hasValue && productsAsync.value!.isEmpty;
    final isAnonymous =
        ref.watch(firebaseUserProvider).valueOrNull?.isAnonymous ?? false;
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 28),
      children: [
        _StoreCard(
          store: store,
          stats: stats,
          strings: ss,
          onLiveTap: () => StoreActions.showLiveSheet(context, ref),
          onEditLink: () => _push(context, const StoreLinkScreen()),
          onCopy: () => StoreActions.copyLink(context, ref),
        ),
        const SizedBox(height: 10),
        const OrderAlertsCard(),
        if (noProducts) ...[
          _AddProductsCard(
            strings: ss,
            onAdd: () => _push(context, const ProductFormScreen()),
            onPaste: () => _push(context, const PasteListScreen()),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                value: '${kpis.toConfirm}',
                label: ss.toConfirm,
                background: AppColors.peach,
                foreground: const Color(0xFFB4650F),
                onTap: () => _openOrdersWith(ref, OrderFilter.pending),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                value: '${kpis.toDispatch}',
                label: ss.toDispatch,
                background: AppColors.brandSoft,
                foreground: AppColors.brandDark,
                onTap: () => _openOrdersWith(ref, OrderFilter.confirmed),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                value: money(kpis.toCollect),
                label: ss.toCollect,
                background: AppColors.brandSoft,
                foreground: AppColors.brandDark,
                onTap: () => _openOrdersWith(ref, OrderFilter.unpaid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CreamCard(
          color: const Color(0xFFE9F3EB),
          borderColor: AppColors.brandSoftBorder,
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          onTap: () => _push(context, const ShareKitScreen()),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.creamCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brandSoftBorder),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.brandDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ss.bioPromoTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ss.bioPromoBody,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => StoreActions.shareOnWhatsApp(ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.whatsapp,
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.share_rounded, size: 20),
          label: Text(ss.shareOnWhatsapp, style: const TextStyle(fontSize: 15.5)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => StoreActions.viewStore(ref),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(ss.viewStore, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => StoreActions.counterOrder(context),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(ss.counterOrder, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const VoiceEntryBar(),
        const SizedBox(height: 22),
        CapsLabel(
          ss.recentOrders,
          trailing: orders.isEmpty
              ? null
              : GestureDetector(
                  onTap: () => _openOrdersWith(ref, OrderFilter.all),
                  child: Text(
                    ss.seeAll,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          CreamCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: AppColors.inkFaint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ss.noOrdersTitle,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ss.noOrdersBody,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          for (final o in orders.take(5))
            _RecentOrderRow(
              order: o,
              strings: ss,
              amount: money(o.total),
              onTap: () => StoreActions.openOrder(context, o.id),
            ),
        if (isAnonymous) ...[
          const SizedBox(height: 18),
          CreamCard(
            color: AppColors.backupBlue,
            borderColor: AppColors.backupBlueBorder,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ss.backupTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ss.backupBody,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _push(context, const BackupScreen()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dispatched,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(ss.backupCta),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.stats,
    required this.strings,
    required this.onLiveTap,
    required this.onEditLink,
    required this.onCopy,
  });

  final StoreModel store;
  final StoreStats stats;
  final StoreStrings strings;
  final VoidCallback onLiveTap;
  final VoidCallback onEditLink;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final ss = strings;
    return CreamCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  store.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(size: 23, height: 1.15),
                ),
              ),
              const SizedBox(width: 8),
              _LivePill(live: store.isLive, strings: ss, onTap: onLiveTap),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 17, color: AppColors.inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppUrls.storeLinkDisplay(store.slug),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEditLink,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AppColors.brandDark,
                ),
              ),
              TextButton(
                onPressed: onCopy,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(ss.copy),
              ),
            ],
          ),
          Text(
            ss.shareLinkHint,
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 15,
                color: AppColors.brand,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  ss.linkStats(stats.opens, stats.carts, stats.sent),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.brand,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({
    required this.live,
    required this.strings,
    required this.onTap,
  });

  final bool live;
  final StoreStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = live ? AppColors.brandDark : const Color(0xFFB4650F);
    return Material(
      color: live ? AppColors.brandSoft : AppColors.pendingSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                live ? strings.live : strings.paused,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.expand_more_rounded, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value, style: AppFonts.display(size: 21)),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: foreground),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: foreground),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductsCard extends StatelessWidget {
  const _AddProductsCard({
    required this.strings,
    required this.onAdd,
    required this.onPaste,
  });

  final StoreStrings strings;
  final VoidCallback onAdd;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return CreamCard(
      color: AppColors.pendingSoft,
      borderColor: const Color(0xFFF3D9B5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.addProductsTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            strings.addProductsBody,
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(strings.addProduct),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste_rounded, size: 17),
                  label: Text(strings.pasteList),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({
    required this.order,
    required this.strings,
    required this.amount,
    required this.onTap,
  });

  final OrderModel order;
  final StoreStrings strings;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ss = strings;
    final sub = order.isRequest
        ? ss.request
        : ss.itemsLabel(order.itemCount);
    final mode =
        order.fulfillment == Fulfillment.pickup ? ss.pickup : ss.delivery;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: OrderColors.bar(order.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.displayName.isEmpty ? ss.walkIn : order.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$sub · $mode',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              ss.statusLabel(order.status, fulfillment: order.fulfillment),
              style: TextStyle(
                fontSize: 12.5,
                color: OrderColors.chipFg(order.status),
              ),
            ),
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: Text(
                amount,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
