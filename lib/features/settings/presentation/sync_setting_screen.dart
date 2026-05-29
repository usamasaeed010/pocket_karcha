import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class SyncSettingScreen extends ConsumerWidget {
  const SyncSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final session = ref.watch(sessionProvider);
    final canSync = FirebaseService.isReady && session.hasAccount;

    return AppPage(
      title: s.syncNow,
      subtitle: s.syncNowDesc,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 56,
                    color: canSync
                        ? AppColors.navActive
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    canSync ? s.syncReady : s.syncUnavailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canSync ? s.syncReadyDesc : s.loginToSync,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (canSync)
              FilledButton.icon(
                onPressed: () => context.showInfoSnack(s.comingSoon),
                icon: const Icon(Icons.sync),
                label: Text(s.syncNow),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navActive,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return AppPage(
      title: s.deleteAccount,
      subtitle: s.deleteAccountDesc,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 48, color: AppColors.expense),
                  const SizedBox(height: 12),
                  Text(
                    s.deleteAccountConfirm,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(s.cancel),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) AppNavigator.resetToAuth(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(s.deleteAccount),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
