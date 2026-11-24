import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Links the guest account to an email + password so the store can be
/// opened on another phone.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _mapError(FirebaseAuthException e, StoreStrings ss) => switch (e.code) {
        'email-already-in-use' || 'credential-already-in-use' => ss.emailInUse,
        'invalid-email' => ss.invalidEmail,
        'weak-password' => ss.passwordShort,
        'requires-recent-login' => ss.signInAgain,
        'network-request-failed' => ss.checkInternet,
        _ => ss.somethingWrong,
      };

  Future<void> _backup(StoreStrings ss) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = ss.invalidEmail);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = ss.passwordShort);
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = ss.passwordsMismatch);
      return;
    }
    final auth = ref.read(authServiceProvider);
    if (auth == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cred = await auth.linkWithEmail(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await ref
            .read(sessionProvider.notifier)
            .applyFirebaseUser(user, profileComplete: true);
      }
      if (mounted) setState(() => _busy = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'provider-already-linked' ? null : _mapError(e, ss);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = ss.somethingWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final user = ref.watch(firebaseUserProvider).valueOrNull;
    final backedUp = user != null && !user.isAnonymous && (user.email ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: backedUp
            ? [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: AppColors.brand,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  ss.backedUpTitle,
                  textAlign: TextAlign.center,
                  style: AppFonts.display(size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  ss.backedUpBody(user.email!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ss.done),
                ),
              ]
            : [
                Text(ss.backupScreenTitle, style: AppFonts.display(size: 26)),
                const SizedBox(height: 8),
                Text(
                  ss.backupIntro,
                  style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
                ),
                const SizedBox(height: 22),
                FieldLabel(ss.email),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                FieldLabel(ss.password),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FieldLabel(ss.confirmPassword),
                TextField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _backup(ss),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : () => _backup(ss),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(ss.backupNow),
                ),
              ],
      ),
    );
  }
}
