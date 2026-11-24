import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/features/settings/presentation/about_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/language_setting_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/privacy_policy_screen.dart';
import 'package:pocket_karcha/features/share_kit/presentation/share_kit_screen.dart';
import 'package:pocket_karcha/features/shell/presentation/main_shell_screen.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/features/store_settings/presentation/backup_export_screen.dart';
import 'package:pocket_karcha/features/store_settings/presentation/backup_screen.dart';
import 'package:pocket_karcha/features/store_settings/presentation/blocked_customers_screen.dart';
import 'package:pocket_karcha/features/store_settings/presentation/order_settings_screen.dart';
import 'package:pocket_karcha/features/store_settings/presentation/store_link_screen.dart';
import 'package:pocket_karcha/features/store_home/widgets/order_alerts_card.dart';
import 'package:pocket_karcha/features/store_settings/presentation/store_profile_screen.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/services/push_service.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Settings tab: store, orders & data, app, account.
class StoreSettingsScreen extends ConsumerWidget {
  const StoreSettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ss = ref.read(storeStringsProvider);
    final user = ref.read(firebaseUserProvider).valueOrNull;

    if (user == null || user.isAnonymous) {
      final choice = await showCreamSheet<String>(
        context,
        title: ss.logoutAnonTitle,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ss.logoutAnonBody,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'backup'),
                child: Text(ss.backupNow),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'logout'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: Text(ss.logoutAnyway),
              ),
            ],
          ),
        ),
      );
      if (!context.mounted) return;
      if (choice == 'backup') {
        _push(context, const BackupScreen());
        return;
      }
      if (choice != 'logout') return;
    } else {
      final ok = await confirmAction(
        context,
        title: ss.logout,
        body: ss.logoutConfirm(user.email ?? ''),
        confirmLabel: ss.logout,
        cancelLabel: ss.cancel,
        destructive: true,
      );
      if (!ok) return;
    }

    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionProvider.notifier).signOut();
    ref.read(storeTabProvider.notifier).state = StoreTabs.home;
    if (context.mounted) AppNavigator.resetToOnboarding(context);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ss = ref.read(storeStringsProvider);
    final ok = await confirmAction(
      context,
      title: ss.deleteAccountTitle,
      body: ss.deleteAccountBody,
      confirmLabel: ss.deleteAccount,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (!ok) return;

    final uid = ref.read(storeOwnerIdProvider);
    final repo = ref.read(storeRepositoryProvider);
    final store = ref.read(currentStoreProvider);
    if (uid != null && repo != null) {
      try {
        await repo
            .closeStore(uid, store?.slug ?? '')
            .timeout(const Duration(seconds: 15));
        await ref.read(userProfileServiceProvider)?.disableAccount(uid);
      } catch (e) {
        if (context.mounted) context.showErrorSnack(friendlyError(e, ss));
        return;
      }
      await ref.read(preferencesServiceProvider).setStoreReady(uid, false);
    }
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionProvider.notifier).signOut();
    ref.read(storeTabProvider.notifier).state = StoreTabs.home;
    showRootSnack(message: ss.accountDeleted, type: AppSnackType.success);
    if (context.mounted) AppNavigator.resetToOnboarding(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final store = ref.watch(currentStoreProvider);
    final user = ref.watch(firebaseUserProvider).valueOrNull;
    final anonymous = user?.isAnonymous ?? false;
    final blockedCount = ref.watch(blockedCustomersProvider).length;
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 32),
      children: [
        Text(ss.settingsTitle, style: AppFonts.display(size: 26)),
        const SizedBox(height: 14),
        if (store != null)
          CreamCard(
            onTap: () => _push(context, const StoreProfileScreen()),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                InitialAvatar(name: store.name, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.display(size: 19),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppUrls.storeLinkDisplay(store.slug),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                Text(
                  ss.edit,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.brand),
              ],
            ),
          ),
        const SizedBox(height: 20),
        CapsLabel(ss.sectionStore),
        const SizedBox(height: 8),
        _Group(
          children: [
            _Tile(
              icon: Icons.storefront_outlined,
              title: ss.storeDetails,
              subtitle: ss.storeDetailsSub,
              onTap: () => _push(context, const StoreProfileScreen()),
            ),
            _Tile(
              icon: Icons.link_rounded,
              title: ss.yourLink,
              subtitle: store == null ? null : AppUrls.storeLinkDisplay(store.slug),
              onTap: () => _push(context, const StoreLinkScreen()),
            ),
            _Tile(
              icon: Icons.tune_rounded,
              title: ss.orderSettings,
              subtitle: ss.orderSettingsSub,
              onTap: () => _push(context, const OrderSettingsScreen()),
            ),
            _Tile(
              icon: Icons.qr_code_2_rounded,
              title: ss.shareKit,
              subtitle: ss.shareKitSub,
              onTap: () => _push(context, const ShareKitScreen()),
            ),
            _Tile(
              icon: Icons.power_settings_new_rounded,
              title: ss.takingOrders,
              subtitle: ss.takingOrdersSub,
              trailing: Switch(
                value: store?.isLive ?? true,
                onChanged: store == null ? null : (v) => StoreActions.setLive(ref, v),
              ),
              onTap: store == null ? null : () => StoreActions.showLiveSheet(context, ref),
            ),
            _Tile(
              icon: Icons.block_rounded,
              title: ss.blockedCustomers,
              subtitle: blockedCount == 0
                  ? ss.blockedCustomersSub
                  : ss.blockedCount(blockedCount),
              onTap: () => _push(context, const BlockedCustomersScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CapsLabel(ss.sectionData),
        const SizedBox(height: 8),
        _Group(
          children: [
            _Tile(
              icon: Icons.cloud_download_outlined,
              title: ss.backupExport,
              subtitle: ss.backupExportSub,
              onTap: () => _push(context, const BackupExportScreen()),
            ),
            _Tile(
              icon: Icons.ios_share_rounded,
              title: ss.sharePriceList,
              onTap: () => StoreActions.sharePriceList(ref),
            ),
            _Tile(
              icon: Icons.menu_book_outlined,
              title: ss.khata,
              subtitle: ss.khataSub,
              onTap: () => _push(context, const MainShellScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CapsLabel(ss.sectionApp),
        const SizedBox(height: 8),
        _Group(
          children: [
            _Tile(
              icon: Icons.translate_rounded,
              title: ss.language,
              subtitle: ss.isUrdu ? 'اردو' : 'English',
              onTap: () => _push(context, const LanguageSettingScreen()),
            ),
            const _OrderAlertsTile(),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: ss.privacyPolicy,
              onTap: () => _push(context, const PrivacyPolicyScreen()),
            ),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: ss.about,
              onTap: () => _push(context, const AboutScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CapsLabel(ss.sectionAccount),
        const SizedBox(height: 8),
        _Group(
          children: [
            if (anonymous)
              _Tile(
                icon: Icons.cloud_upload_outlined,
                iconColor: AppColors.dispatched,
                title: ss.backupStore,
                subtitle: ss.notBackedUp,
                onTap: () => _push(context, const BackupScreen()),
              )
            else if (user?.email != null)
              _Tile(
                icon: Icons.verified_user_outlined,
                title: ss.backupStore,
                subtitle: ss.backedUpAs(user!.email!),
                trailing: const SizedBox.shrink(),
              ),
            _Tile(
              icon: Icons.logout_rounded,
              title: ss.logout,
              onTap: () => _logout(context, ref),
            ),
            _Tile(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.danger,
              title: ss.deleteAccount,
              titleColor: AppColors.danger,
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CreamCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 62, color: AppColors.creamBorder),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.creamDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: iconColor ?? AppColors.brandDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}


/// New-order notifications: on (tap opens phone settings) or off (tap asks).
class _OrderAlertsTile extends ConsumerWidget {
  const _OrderAlertsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final on = ref.watch(pushAllowedProvider).valueOrNull ?? false;
    return _Tile(
      icon: on
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      title: ss.orderAlerts,
      subtitle: on ? ss.orderAlertsOnSub : ss.orderAlertsOffSub,
      onTap: on
          ? PushService.instance.openSettings
          : () => turnOnOrderAlerts(ref),
    );
  }
}
