import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/features/orders/presentation/order_detail_screen.dart';
import 'package:pocket_karcha/features/orders/presentation/order_editor_screen.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Actions reused by Home, Orders and Settings.
abstract final class StoreActions {
  static Future<void> shareOnWhatsApp(WidgetRef ref) async {
    final store = ref.read(currentStoreProvider);
    if (store == null) return;
    final ss = ref.read(storeStringsProvider);
    final text =
        ss.shareStoreMessage(store.name, AppUrls.storeLink(store.slug));
    final opened = await LaunchUtils.openWhatsApp(text: text);
    if (!opened) await LaunchUtils.shareText(text);
  }

  /// Price list as a WhatsApp message (falls back to the share sheet).
  static Future<void> sharePriceList(WidgetRef ref) async {
    final store = ref.read(currentStoreProvider);
    if (store == null) return;
    final ss = ref.read(storeStringsProvider);
    final money = ref.read(moneyProvider);
    final products =
        ref.read(productListProvider).where((p) => p.inStock).toList();
    final b = StringBuffer(ss.priceListHeader(store.name))..writeln();
    String? lastCategory;
    for (final p in products) {
      final cat = p.category.trim();
      if (cat.isNotEmpty && cat != lastCategory) {
        b
          ..writeln()
          ..writeln('*$cat*');
        lastCategory = cat;
      }
      if (p.hasVariants) {
        final opts =
            p.variants.map((v) => '${v.name} ${money(v.price)}').join(' / ');
        b.writeln('• ${p.name} — $opts');
      } else {
        b.writeln('• ${p.name} — ${money(p.price)}');
      }
    }
    b
      ..writeln()
      ..writeln(ss.orderAt(AppUrls.storeLink(store.slug)));
    final text = b.toString().trim();
    final opened = await LaunchUtils.openWhatsApp(text: text);
    if (!opened) await LaunchUtils.shareText(text);
  }

  static Future<void> viewStore(WidgetRef ref) async {
    final store = ref.read(currentStoreProvider);
    if (store == null) return;
    await LaunchUtils.openUrl(AppUrls.storeLink(store.slug));
  }

  static Future<void> copyLink(BuildContext context, WidgetRef ref) async {
    final store = ref.read(currentStoreProvider);
    if (store == null) return;
    await LaunchUtils.copy(AppUrls.storeLink(store.slug));
    if (context.mounted) {
      context.showSuccessSnack(ref.read(storeStringsProvider).linkCopied);
    }
  }

  static void counterOrder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OrderEditorScreen()),
    );
  }

  static void openOrder(BuildContext context, String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  /// Opens a WhatsApp chat with a customer (phone as they typed it).
  static Future<void> messageCustomer(
    WidgetRef ref, {
    required String phone,
    required String text,
  }) async {
    final store = ref.read(currentStoreProvider);
    final ss = ref.read(storeStringsProvider);
    final digits = LaunchUtils.toWhatsAppDigits(
      phone,
      dialCode: store?.dialCode ?? '+92',
    );
    final opened =
        await LaunchUtils.openWhatsApp(phoneDigits: digits, text: text);
    if (!opened) {
      showRootSnack(message: ss.whatsappMissing, type: AppSnackType.error);
    }
  }

  static Future<void> callCustomer(String phone) => LaunchUtils.call(phone);

  static void setLive(WidgetRef ref, bool live) {
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    final ss = ref.read(storeStringsProvider);
    backgroundWrite(repo.updateStore(uid, {'isLive': live}), ss);
    showRootSnack(
      message: live ? ss.storeLiveNow : ss.storePaused,
      type: live ? AppSnackType.success : AppSnackType.warning,
    );
  }

  /// "Taking orders" switch + message shown while paused.
  static Future<void> showLiveSheet(BuildContext context, WidgetRef ref) async {
    final store = ref.read(currentStoreProvider);
    if (store == null) return;
    final ss = ref.read(storeStringsProvider);
    final message = TextEditingController(text: store.pausedMessage);
    var live = store.isLive;

    await showCreamSheet<void>(
      context,
      title: ss.takingOrders,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreamCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: SwitchRow(
                  title: live ? ss.live : ss.paused,
                  subtitle: live ? ss.liveOnDesc : ss.liveOffDesc,
                  value: live,
                  onChanged: (v) => setSheet(() => live = v),
                ),
              ),
              if (!live) ...[
                const SizedBox(height: 14),
                Text(
                  ss.pausedMessageLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: message,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: ss.pausedMessageHint),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  final repo = ref.read(storeRepositoryProvider);
                  final uid = ref.read(storeOwnerIdProvider);
                  if (repo != null && uid != null) {
                    backgroundWrite(
                      repo.updateStore(uid, {
                        'isLive': live,
                        'pausedMessage': message.text.trim(),
                      }),
                      ss,
                    );
                  }
                  Navigator.pop(ctx);
                  if (live != store.isLive) {
                    showRootSnack(
                      message: live ? ss.storeLiveNow : ss.storePaused,
                      type: live ? AppSnackType.success : AppSnackType.warning,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: live ? AppColors.brand : AppColors.pending,
                ),
                child: Text(ss.done),
              ),
            ],
          ),
        ),
      ),
    );
    // Not disposed here: the sheet's TextField may still be animating out.
  }
}
