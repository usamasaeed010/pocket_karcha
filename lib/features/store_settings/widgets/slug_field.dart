import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/slug_utils.dart';
import 'package:pocket_karcha/data/repositories/store_repository.dart';
import 'package:pocket_karcha/providers/store_providers.dart';

enum SlugCheck { checking, available, yours, taken, invalid, failed }

extension SlugCheckX on SlugCheck {
  /// The link can be used (free, or already this owner's).
  bool get usable => this == SlugCheck.available || this == SlugCheck.yours;
}

/// Link handle input with a live "Available / taken" check.
class SlugField extends ConsumerStatefulWidget {
  const SlugField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.autofocus = false,
  });

  final String initial;
  final void Function(String slug, SlugCheck status) onChanged;
  final bool autofocus;

  @override
  ConsumerState<SlugField> createState() => _SlugFieldState();
}

class _SlugFieldState extends ConsumerState<SlugField> {
  late final TextEditingController _c =
      TextEditingController(text: SlugUtils.sanitizeTyping(widget.initial));
  Timer? _debounce;
  SlugCheck _status = SlugCheck.checking;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check(_c.text, delay: Duration.zero);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onTyped(String raw) {
    final clean = SlugUtils.sanitizeTyping(raw);
    if (clean != raw) {
      _c.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
    _check(clean);
  }

  void _check(String slug, {Duration delay = const Duration(milliseconds: 450)}) {
    _debounce?.cancel();
    _seq++;
    if (!SlugUtils.isValid(slug)) {
      _set(slug, SlugCheck.invalid);
      return;
    }
    _set(slug, SlugCheck.checking);
    _debounce = Timer(delay, () => _run(slug));
  }

  Future<void> _run(String slug) async {
    final seq = ++_seq;
    final repo = ref.read(storeRepositoryProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) {
      _set(slug, SlugCheck.failed);
      return;
    }
    try {
      final r = await repo
          .checkSlug(slug, uid: uid)
          .timeout(const Duration(seconds: 10));
      if (seq != _seq || !mounted) return;
      _set(
        slug,
        switch (r) {
          SlugStatus.available => SlugCheck.available,
          SlugStatus.yours => SlugCheck.yours,
          SlugStatus.taken => SlugCheck.taken,
        },
      );
    } catch (e) {
      debugPrint('Slug check failed: $e');
      if (seq != _seq || !mounted) return;
      _set(slug, SlugCheck.failed);
    }
  }

  void _set(String slug, SlugCheck s) {
    if (!mounted) return;
    setState(() => _status = s);
    widget.onChanged(slug, s);
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final (icon, color, text) = _statusLine(ss);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _c,
          autofocus: widget.autofocus,
          onChanged: _onTyped,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppUrls.storeHostPrefix}${_c.text}',
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (_status == SlugCheck.checking)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
              ),
            ),
            if (_status == SlugCheck.failed)
              TextButton(
                onPressed: () => _check(_c.text, delay: Duration.zero),
                child: Text(ss.retry),
              ),
          ],
        ),
      ],
    );
  }

  (IconData, Color, String) _statusLine(StoreStrings ss) => switch (_status) {
        SlugCheck.checking => (Icons.hourglass_empty_rounded, AppColors.inkSoft, ss.slugChecking),
        SlugCheck.available => (Icons.check_circle_rounded, AppColors.brand, ss.slugAvailable),
        SlugCheck.yours => (Icons.check_circle_rounded, AppColors.brand, ss.slugYours),
        SlugCheck.taken => (Icons.cancel_rounded, AppColors.danger, ss.slugTaken),
        SlugCheck.invalid => (Icons.info_outline_rounded, AppColors.pending, ss.slugInvalid),
        SlugCheck.failed => (Icons.wifi_off_rounded, AppColors.danger, ss.slugCheckFailed),
      };
}
