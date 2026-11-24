import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/services/push_service.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Asks for notification permission and saves this phone for new-order
/// alerts. Says what happened in a snack bar.
Future<bool> turnOnOrderAlerts(WidgetRef ref) async {
  final ss = ref.read(storeStringsProvider);
  final push = PushService.instance;
  final ok = await push.requestPermission();
  ref.invalidate(pushAllowedProvider);
  if (ok) {
    final uid = ref.read(storeOwnerIdProvider);
    if (uid != null) unawaited(push.registerDevice(uid, urdu: ss.isUrdu));
    showRootSnack(message: ss.alertsOn, type: AppSnackType.success);
  } else {
    showRootSnack(
      message: ss.alertsBlocked,
      type: AppSnackType.warning,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: ss.openSettings,
        textColor: Colors.white,
        onPressed: push.openSettings,
      ),
    );
  }
  return ok;
}

/// Home card: "Get new-order alerts" until alerts are on or the owner
/// taps Later.
class OrderAlertsCard extends ConsumerStatefulWidget {
  const OrderAlertsCard({super.key});

  @override
  ConsumerState<OrderAlertsCard> createState() => _OrderAlertsCardState();
}

class _OrderAlertsCardState extends ConsumerState<OrderAlertsCard> {
  late bool _dismissed =
      ref.read(preferencesServiceProvider).orderAlertsCardDismissed;
  bool _busy = false;

  Future<void> _turnOn() async {
    setState(() => _busy = true);
    await turnOnOrderAlerts(ref);
    if (mounted) setState(() => _busy = false);
  }

  void _later() {
    unawaited(ref.read(preferencesServiceProvider).setOrderAlertsCardDismissed());
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    // Hidden while checking and once alerts are on.
    if (ref.watch(pushAllowedProvider).valueOrNull != false) {
      return const SizedBox.shrink();
    }
    final ss = ref.watch(storeStringsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CreamCard(
        color: AppColors.brandSoft,
        borderColor: AppColors.brandSoftBorder,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ss.alertsCardTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ss.alertsCardBody,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _later, child: Text(ss.later)),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _busy ? null : _turnOn,
                  child: Text(ss.alertsTurnOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
