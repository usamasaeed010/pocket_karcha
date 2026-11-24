import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/features/khata/presentation/khata_screen.dart';
import 'package:pocket_karcha/features/orders/presentation/order_detail_screen.dart';
import 'package:pocket_karcha/features/orders/presentation/orders_screen.dart';
import 'package:pocket_karcha/features/products/presentation/products_screen.dart';
import 'package:pocket_karcha/features/shell/widgets/store_bottom_nav.dart';
import 'package:pocket_karcha/features/store_home/presentation/store_home_screen.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/features/store_settings/presentation/store_settings_screen.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/services/push_service.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Main app after setup: Home · Orders · Products · Khata · Settings.
class StoreShellScreen extends ConsumerStatefulWidget {
  const StoreShellScreen({super.key});

  @override
  ConsumerState<StoreShellScreen> createState() => _StoreShellScreenState();
}

class _StoreShellScreenState extends ConsumerState<StoreShellScreen> {
  DateTime? _lastBackOnHome;
  StreamSubscription<String>? _pushTaps;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLiveSheetOnce();
      _setUpPush();
    });
    // Back from phone settings with notifications turned on → save this
    // phone for alerts.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(pushAllowedProvider);
        _registerForAlerts();
      },
    );
  }

  @override
  void dispose() {
    _pushTaps?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Opens orders from tapped notifications and keeps this phone saved for
  /// new-order alerts.
  void _setUpPush() {
    final push = PushService.instance;
    _pushTaps = push.openedOrderIds.listen(_openOrderFromPush);
    final first = push.takeInitialOrderId();
    if (first != null) _openOrderFromPush(first);
    _registerForAlerts();
  }

  void _openOrderFromPush(String orderId) {
    if (!mounted) return;
    ref.read(storeTabProvider.notifier).state = StoreTabs.orders;
    StoreActions.openOrder(context, orderId);
  }

  Future<void> _registerForAlerts() async {
    final uid = ref.read(storeOwnerIdProvider);
    if (uid == null || !await PushService.instance.isAllowed()) return;
    if (!mounted) return;
    await PushService.instance.registerDevice(
      uid,
      urdu: ref.read(storeStringsProvider).isUrdu,
    );
  }

  /// Right after store setup: "Your store is live!" + share on WhatsApp.
  Future<void> _showLiveSheetOnce() async {
    if (!mounted || !ref.read(storeJustCreatedProvider)) return;
    ref.read(storeJustCreatedProvider.notifier).state = false;
    await showCreamSheet<void>(
      context,
      builder: (sheetContext) => _StoreLiveSheet(
        onShare: () {
          Navigator.of(sheetContext).pop();
          StoreActions.shareOnWhatsApp(ref);
        },
        onCopy: () => StoreActions.copyLink(sheetContext, ref),
        onLater: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  void _onBack() {
    final tab = ref.read(storeTabProvider);
    if (tab != StoreTabs.home) {
      ref.read(storeTabProvider.notifier).state = StoreTabs.home;
      _lastBackOnHome = null;
      return;
    }
    final now = DateTime.now();
    if (_lastBackOnHome != null &&
        now.difference(_lastBackOnHome!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackOnHome = now;
    context.showInfoSnack(ref.read(storeStringsProvider).pressBackAgain);
  }

  /// Snack when a new order arrives from the store link while the app is open.
  void _watchNewOrders() {
    ref.listen<AsyncValue<List<OrderModel>>>(ordersProvider, (prev, next) {
      final before = prev?.valueOrNull;
      final after = next.valueOrNull;
      if (before == null || after == null) return;
      final known = before.map((o) => o.id).toSet();
      final fresh = after
          .where((o) => !known.contains(o.id) && o.source == OrderSource.link)
          .toList();
      if (fresh.isEmpty) return;

      final order = fresh.first;
      final ss = ref.read(storeStringsProvider);
      final money = ref.read(moneyProvider);
      HapticFeedback.mediumImpact();
      showRootSnack(
        message: ss.newOrderFrom(
          order.displayName.isEmpty ? ss.walkIn : order.displayName,
          money(order.total),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: ss.view,
          textColor: AppColors.brandSoft,
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OrderDetailScreen(orderId: order.id),
              ),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _watchNewOrders();
    // Alerts follow the app language.
    ref.listen<bool>(
      storeStringsProvider.select((s) => s.isUrdu),
      (_, _) => _registerForAlerts(),
    );
    final tab = ref.watch(storeTabProvider);
    final ss = ref.watch(storeStringsProvider);
    final pending = ref.watch(orderKpisProvider).toConfirm;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: IndexedStack(
          index: tab,
          children: const [
            StoreHomeScreen(),
            OrdersScreen(),
            ProductsScreen(),
            KhataScreen(),
            StoreSettingsScreen(),
          ],
        ),
        bottomNavigationBar: StoreBottomNav(
          currentIndex: tab,
          ordersBadge: pending,
          labels: [
            ss.tabHome,
            ss.tabOrders,
            ss.tabProducts,
            ss.tabKhata,
            ss.tabSettings,
          ],
          onTap: (i) {
            ref.read(storeTabProvider.notifier).state = i;
            if (i != StoreTabs.home) _lastBackOnHome = null;
          },
        ),
      ),
    );
  }
}

class _StoreLiveSheet extends ConsumerWidget {
  const _StoreLiveSheet({
    required this.onShare,
    required this.onCopy,
    required this.onLater,
  });

  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final store = ref.watch(currentStoreProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.brand,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ss.storeLiveTitle,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            ss.storeLiveBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
          ),
          const SizedBox(height: 18),
          CreamCard(
            radius: 12,
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.brand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: store == null
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          AppUrls.storeLinkDisplay(store.slug),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandDark,
                          ),
                        ),
                ),
                TextButton(
                  onPressed: store == null ? null : onCopy,
                  child: Text(ss.copy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: store == null ? null : onShare,
            style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
            icon: const Icon(Icons.share_rounded, size: 19),
            label: Text(ss.shareOnWhatsapp),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onLater, child: Text(ss.later)),
        ],
      ),
    );
  }
}
