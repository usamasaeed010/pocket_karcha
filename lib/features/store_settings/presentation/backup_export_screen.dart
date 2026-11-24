import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/backup/backup_excel.dart';
import 'package:pocket_karcha/core/utils/backup/backup_pdf.dart';
import 'package:pocket_karcha/core/utils/backup/backup_snapshot.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/features/store_settings/presentation/backup_screen.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Settings → Backup & export: where the data lives (cloud account) and
/// files to keep or share: a full Excel workbook and a PDF report.
class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

enum _Busy { none, excel, pdf }

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  BackupPeriod _period = BackupPeriod.all;
  _Busy _busy = _Busy.none;

  String _periodLabel(StoreStrings ss, BackupPeriod p) => switch (p) {
        BackupPeriod.thisMonth => ss.periodThisMonth,
        BackupPeriod.lastMonth => ss.periodLastMonth,
        BackupPeriod.thisYear => ss.periodThisYear,
        BackupPeriod.all => ss.periodAll,
      };

  String _fileStamp(DateTime now) => switch (_period) {
        BackupPeriod.thisMonth => DateFormat('yyyy-MM').format(now),
        BackupPeriod.lastMonth =>
          DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1)),
        BackupPeriod.thisYear => '${now.year}',
        BackupPeriod.all => DateFormat('yyyy-MM-dd').format(now),
      };

  /// Waits for the streams the files need (the cache answers at once when
  /// offline), then freezes them into one snapshot.
  Future<BackupSnapshot> _snapshot() async {
    const wait = Duration(seconds: 8);
    await Future.wait<Object?>([
      ref.read(allEntriesStreamProvider.future),
      ref.read(peopleStreamProvider.future),
      ref.read(ordersProvider.future),
      ref.read(productsProvider.future),
    ]).timeout(wait);
    final labels = {
      for (final c in ref.read(allCategoriesProvider)) c.id: c.labelEn,
    };
    return BackupSnapshot(
      storeName: ref.read(currentStoreProvider)?.name ?? '',
      currency: ref.read(currencySymbolProvider),
      period: _period,
      generatedAt: DateTime.now(),
      entries: ref.read(allEntriesStreamProvider).valueOrNull ?? const [],
      people: ref.read(peopleListProvider),
      ledgers: ref.read(ledgersProvider),
      orders: ref.read(orderListProvider),
      menu: ref.read(productListProvider),
      categoryLabel: (id) =>
          labels[id] ?? ref.read(categoryByIdProvider(id)).labelEn,
    );
  }

  Future<void> _export(_Busy kind) async {
    if (_busy != _Busy.none) return;
    final ss = ref.read(storeStringsProvider);
    setState(() => _busy = kind);
    try {
      final snap = await _snapshot();
      final stamp = _fileStamp(snap.generatedAt);
      if (kind == _Busy.excel) {
        final bytes = BackupExcel.build(snap);
        await LaunchUtils.shareBytes(
          Uint8List.fromList(bytes),
          fileName: 'pocket-karcha-$stamp.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        final fonts = BackupFonts(
          regular: await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
          bold: await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
          urdu: await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
        );
        final bytes = await BackupPdf.build(
          snap,
          fonts: fonts,
          money: ref.read(moneyProvider),
        );
        await LaunchUtils.shareBytes(
          bytes,
          fileName: 'pocket-karcha-report-$stamp.pdf',
          mimeType: 'application/pdf',
        );
      }
    } catch (e, st) {
      debugPrint('Export failed: $e\n$st');
      if (mounted) context.showErrorSnack(ss.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final user = ref.watch(firebaseUserProvider).valueOrNull;
    final guest = user == null || user.isAnonymous;

    // Keep the data streams alive while this screen is open.
    final entriesAsync = ref.watch(allEntriesStreamProvider);
    ref.watch(peopleStreamProvider);
    ref.watch(productsProvider);
    final ordersAsync = ref.watch(ordersProvider);
    final loading = entriesAsync.isLoading || ordersAsync.isLoading;

    final range = _period.range(DateTime.now());
    bool inRange(DateTime d) =>
        (range.from == null || !d.isBefore(range.from!)) &&
        (range.to == null || d.isBefore(range.to!));
    final entryCount =
        (entriesAsync.valueOrNull ?? const []).where((e) => inRange(e.date)).length;
    final orderCount = ref
        .watch(orderListProvider)
        .where((o) => inRange(o.createdAt))
        .length;
    final peopleCount = ref.watch(peopleListProvider).length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(ss.backupExport),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _CloudCard(guest: guest, email: user?.email),
          const SizedBox(height: 22),
          CapsLabel(ss.exportPeriod),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in BackupPeriod.values)
                ChoiceChip(
                  label: Text(_periodLabel(ss, p)),
                  selected: _period == p,
                  onSelected: _busy != _Busy.none
                      ? null
                      : (_) => setState(() => _period = p),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            loading
                ? ss.exportLoading
                : ss.exportCounts(entryCount, orderCount, peopleCount),
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ExportTile(
            icon: Icons.table_view_rounded,
            color: const Color(0xFF1D6F42),
            title: ss.excelBackup,
            subtitle: ss.excelBackupSub,
            busy: _busy == _Busy.excel,
            enabled: _busy == _Busy.none,
            onTap: () => _export(_Busy.excel),
          ),
          const SizedBox(height: 10),
          _ExportTile(
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFB42318),
            title: ss.pdfReport,
            subtitle: ss.pdfReportSub,
            busy: _busy == _Busy.pdf,
            enabled: _busy == _Busy.none,
            onTap: () => _export(_Busy.pdf),
          ),
          const SizedBox(height: 16),
          Text(
            ss.exportNote,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudCard extends ConsumerWidget {
  const _CloudCard({required this.guest, this.email});

  final bool guest;
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final color = guest ? AppColors.dispatched : AppColors.brand;
    return CreamCard(
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                guest ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  guest ? ss.cloudGuestTitle : ss.cloudSavedTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guest ? ss.cloudGuestBody : ss.cloudSavedBody(email ?? ''),
            style: const TextStyle(color: AppColors.ink, height: 1.4),
          ),
          if (guest) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(ss.backupNow),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CreamCard(
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Icon(Icons.ios_share_rounded, color: color),
        ],
      ),
    );
  }
}
