import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/confirmation_bottom_sheet.dart';

Future<void> showDeleteAccountSheet(BuildContext context, WidgetRef ref) async {
  final s = ref.read(appStringsProvider);
  final confirmed = await showConfirmationBottomSheet(
    context,
    title: s.deleteAccount,
    subtitle: s.deleteAccountConfirm,
    message: s.deleteAccountWarning,
    confirmLabel: s.deleteAccount,
    cancelLabel: s.cancel,
    confirmColor: AppColors.expense,
    icon: Icons.warning_amber_rounded,
    iconColor: AppColors.expense,
    messageBackground: const Color(0xFFFFF5F5),
    messageBorder: const Color(0xFFFECACA),
  );

  if (confirmed != true || !context.mounted) return;

  final uid = ref.read(currentUserIdProvider);
  if (uid != null) {
    final profiles = ref.read(userProfileServiceProvider);
    if (profiles != null) {
      await profiles.disableAccount(uid);
    }
  }
  await ref.read(authRepositoryProvider).signOut();
  await ref.read(sessionProvider.notifier).signOut();
  if (context.mounted) {
    context.showSuccessSnack(s.snackAccountDeleted);
    AppNavigator.resetToAuth(context);
  }
}
