import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_row.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_section_card.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';
import 'package:pocket_karcha/shared/widgets/profile_avatar.dart';

class ManageAccountScreen extends ConsumerStatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  ConsumerState<ManageAccountScreen> createState() =>
      _ManageAccountScreenState();
}

class _ManageAccountScreenState extends ConsumerState<ManageAccountScreen> {
  late final TextEditingController _name;
  bool _uploading = false;
  bool _savingName = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    _name = TextEditingController(text: session.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _initial(SessionState session) {
    final name = session.displayName?.split(' ').first ??
        session.email?.split('@').first ??
        'U';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Future<void> _saveName() async {
    final s = ref.read(appStringsProvider);
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      context.showErrorSnack(s.nameRequired);
      return;
    }

    setState(() {
      _savingName = true;
      _error = null;
    });

    try {
      await ref.read(sessionProvider.notifier).updateDisplayName(trimmed);
      if (mounted) context.showSuccessSnack(s.snackProfileUpdated);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        context.showErrorSnack(e.toString());
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final s = ref.read(appStringsProvider);
    final uid = ref.read(currentUserIdProvider);
    final storage = ref.read(storageServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);

    if (uid == null || storage == null || profiles == null) {
      setState(() => _error = s.profilePhotoUnavailable);
      context.showErrorSnack(s.profilePhotoUnavailable);
      return;
    }

    final source = await showAppOptionsBottomSheet<ImageSource>(
      context: context,
      title: s.profilePhoto,
      subtitle: s.changeProfilePhoto,
      options: [
        AppBottomSheetOption(
          value: ImageSource.camera,
          label: s.takePhoto,
          leading: const Icon(Icons.camera_alt_outlined,
              color: AppColors.dashboardGreen),
        ),
        AppBottomSheetOption(
          value: ImageSource.gallery,
          label: s.chooseGallery,
          leading: const Icon(Icons.photo_library_outlined,
              color: AppColors.dashboardGreen),
        ),
      ],
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final url = await profiles.updateAvatar(
        uid: uid,
        file: File(picked.path),
        storage: storage,
      );
      await ref.read(sessionProvider.notifier).updateAvatarUrl(url);
      if (mounted) {
        context.showSuccessSnack(s.snackProfilePhotoUpdated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        context.showErrorSnack(e.toString());
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final session = ref.watch(sessionProvider);
    final initial = _initial(session);
    final busy = _uploading || _savingName;

    return AppPage(
      title: s.editProfile,
      subtitle: s.editProfileDesc,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ProfileAvatar(
                      initial: initial,
                      imageUrl: session.avatarUrl,
                      radius: 48,
                      showBorder: true,
                    ),
                    Material(
                      color: AppColors.dashboardGreen,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy ? null : _pickAndUploadAvatar,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.changeProfilePhoto,
                  style: const TextStyle(
                    color: AppColors.dashboardGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _name,
            label: s.name,
            hint: s.name,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.saveChanges,
            loading: _savingName,
            onPressed: busy ? null : _saveName,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SettingsSectionCard(
            title: s.account,
            children: [
              if (session.email != null)
                SettingsRow(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF0D9488),
                  title: session.email!,
                ),
              if (session.phone != null && session.phone!.isNotEmpty)
                SettingsRow(
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  title: session.phone!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
