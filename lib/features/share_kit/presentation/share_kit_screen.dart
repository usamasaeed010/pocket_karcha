import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/data/models/store_model.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Ready-made artwork with the store link: counter QR poster, WhatsApp
/// status image and bio text.
class ShareKitScreen extends ConsumerStatefulWidget {
  const ShareKitScreen({super.key});

  @override
  ConsumerState<ShareKitScreen> createState() => _ShareKitScreenState();
}

class _ShareKitScreenState extends ConsumerState<ShareKitScreen> {
  final _posterKey = GlobalKey();
  final _statusKey = GlobalKey();
  bool _busy = false;

  Future<void> _shareImage(GlobalKey key, String fileName, String link) async {
    if (_busy) return;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _busy = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      await LaunchUtils.shareBytes(
        data.buffer.asUint8List(),
        fileName: fileName,
        mimeType: 'image/png',
        text: link,
      );
    } catch (e) {
      if (mounted) context.showErrorSnack(ref.read(storeStringsProvider).somethingWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final store = ref.watch(currentStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream, title: Text(ss.shareKitTitle)),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Text(
                  ss.shareKitIntro,
                  style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 18),
                CapsLabel(ss.counterPoster),
                const SizedBox(height: 8),
                Center(
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: _Poster(store: store, strings: ss),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _shareImage(
                            _posterKey,
                            '${store.slug}-poster.png',
                            AppUrls.storeLink(store.slug),
                          ),
                  icon: const Icon(Icons.download_rounded, size: 19),
                  label: Text(ss.savePoster),
                ),
                const SizedBox(height: 26),
                CapsLabel(ss.statusCard),
                const SizedBox(height: 8),
                Center(
                  child: RepaintBoundary(
                    key: _statusKey,
                    child: _StatusCard(store: store, strings: ss),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _shareImage(
                            _statusKey,
                            '${store.slug}-status.png',
                            AppUrls.storeLink(store.slug),
                          ),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
                  icon: const Icon(Icons.share_rounded, size: 19),
                  label: Text(ss.shareStatus),
                ),
                const SizedBox(height: 26),
                CapsLabel(ss.bioCard),
                const SizedBox(height: 8),
                CreamCard(
                  child: SelectableText(
                    ss.bioText(AppUrls.storeLink(store.slug)),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await LaunchUtils.copy(ss.bioText(AppUrls.storeLink(store.slug)));
                    if (context.mounted) context.showSuccessSnack(ss.copied);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(ss.copyBio),
                ),
              ],
            ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.store, required this.strings});

  final StoreModel store;
  final StoreStrings strings;

  @override
  Widget build(BuildContext context) {
    final link = AppUrls.storeLink(store.slug);
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creamBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            store.name,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 26, height: 1.15),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              strings.scanToOrder,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.creamBorder),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppUrls.storeLinkDisplay(store.slug),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.posterLine,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Text(
            strings.madeWith,
            style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.store, required this.strings});

  final StoreModel store;
  final StoreStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 480,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4A2E), AppColors.brand],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded, color: Colors.white, size: 34),
          const Spacer(),
          Text(
            strings.statusHeadline,
            style: AppFonts.display(size: 30, color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 10),
          Text(
            store.name,
            style: const TextStyle(
              color: Color(0xFFCBE5D3),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.statusSub,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.brand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppUrls.storeLinkDisplay(store.slug),
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
