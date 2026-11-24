import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/features/store_settings/widgets/slug_field.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Change the store link handle (`…/my-shop`).
class StoreLinkScreen extends ConsumerStatefulWidget {
  const StoreLinkScreen({super.key});

  @override
  ConsumerState<StoreLinkScreen> createState() => _StoreLinkScreenState();
}

class _StoreLinkScreenState extends ConsumerState<StoreLinkScreen> {
  String _slug = '';
  SlugCheck _status = SlugCheck.checking;
  bool _saving = false;

  Future<void> _save(StoreStrings ss) async {
    final store = ref.read(currentStoreProvider);
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (store == null || repo == null || uid == null) return;
    setState(() => _saving = true);
    try {
      await repo
          .changeSlug(uid: uid, oldSlug: store.slug, newSlug: _slug)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      showRootSnack(message: ss.linkSaved, type: AppSnackType.success);
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // Creating a slug that exists is denied by the rules → taken.
      if (e.code == 'permission-denied') {
        setState(() => _status = SlugCheck.taken);
        context.showErrorSnack(ss.slugTaken);
      } else {
        context.showErrorSnack(friendlyError(e, ss));
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showErrorSnack(ss.checkInternet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final store = ref.watch(currentStoreProvider);
    final canSave = store != null &&
        _status == SlugCheck.available &&
        _slug != store.slug &&
        !_saving;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream, title: Text(ss.yourLink)),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                FieldLabel(ss.linkName),
                SlugField(
                  initial: store.slug,
                  onChanged: (slug, status) => setState(() {
                    _slug = slug;
                    _status = status;
                  }),
                ),
                const SizedBox(height: 18),
                CreamCard(
                  color: AppColors.pendingSoft,
                  borderColor: const Color(0xFFF3D9B5),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFB4650F),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ss.changeLinkNote,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: canSave ? () => _save(ss) : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(ss.saveLink),
          ),
        ),
      ),
    );
  }
}
