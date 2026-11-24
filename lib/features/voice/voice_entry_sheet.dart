import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/stock_units.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/products/presentation/product_form_screen.dart';
import 'package:pocket_karcha/features/voice/voice_sale_parser.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Opens voice entry: say "1 dahi bhalla half Usama ke naam pe" and it is
/// written in the shop khata at menu prices. [person] fixes whose khata it
/// goes on (from a person's page).
Future<void> showVoiceEntrySheet(BuildContext context, {PersonModel? person}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => VoiceEntrySheet(person: person),
  );
}

/// "Say 1 dahi bhalla half Ali ke naam pe", built from the owner's menu.
String voiceExample(List<ProductModel> menu) {
  final sized = menu.where((p) => p.hasVariants && p.inStock).toList();
  final p = sized.isNotEmpty
      ? sized.first
      : (menu.isNotEmpty ? menu.first : null);
  if (p == null) return '1 dahi bhalla half Ali ke naam pe';
  final size = p.hasVariants ? ' ${p.variants.first.name.toLowerCase()}' : '';
  return '1 ${p.name.toLowerCase()}$size Ali ke naam pe';
}

class VoiceEntrySheet extends ConsumerStatefulWidget {
  const VoiceEntrySheet({super.key, this.person});

  final PersonModel? person;

  @override
  ConsumerState<VoiceEntrySheet> createState() => _VoiceEntrySheetState();
}

class _VoiceEntrySheetState extends ConsumerState<VoiceEntrySheet> {
  final _speech = SpeechToText();
  final _text = TextEditingController();
  final _textFocus = FocusNode();

  /// Null until the phone's speech service has been checked.
  bool? _available;
  bool _listening = false;
  double _level = 0;
  late bool _urdu = ref.read(storeStringsProvider).isUrdu;
  List<String> _localeIds = const [];
  String? _notice;

  bool _parsed = false;
  List<VoiceSaleLine> _lines = const [];
  PersonModel? _person;
  String? _newName;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    _pending = widget.person != null;
    _textFocus.addListener(() {
      if (_textFocus.hasFocus && _listening) unawaited(_stop());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(productListProvider).isNotEmpty) {
        unawaited(_start(auto: true));
      }
    });
  }

  @override
  void dispose() {
    if (_speech.isListening) unawaited(_speech.cancel());
    _speech.errorListener = null;
    _speech.statusListener = null;
    _text.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  // ── Speech ─────────────────────────────────────────────────────────────

  Future<bool> _ensureSpeech() async {
    if (_available == true) return true;
    final ss = ref.read(storeStringsProvider);
    var ok = false;
    try {
      ok = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    } catch (_) {
      ok = false;
    }
    // The plugin is shared: point its callbacks at this sheet.
    _speech.errorListener = _onError;
    _speech.statusListener = _onStatus;
    var micDenied = false;
    if (ok) {
      try {
        _localeIds = [for (final l in await _speech.locales()) l.localeId];
      } catch (_) {
        _localeIds = const [];
      }
    } else {
      final mic = await Permission.microphone.status;
      micDenied = mic.isDenied || mic.isPermanentlyDenied || mic.isRestricted;
    }
    if (!mounted) return false;
    setState(() {
      _available = ok;
      _notice = ok ? null : (micDenied ? ss.voiceMicDenied : ss.voiceNotAvailable);
    });
    return ok;
  }

  /// Phone locale for Roman / English or Urdu speech.
  String _localeFor(bool urdu) {
    final want = urdu ? const ['ur_PK', 'ur_IN'] : const ['en_IN', 'en_PK', 'en_US', 'en_GB'];
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();
    for (final w in want) {
      for (final id in _localeIds) {
        if (norm(id) == w.toLowerCase()) return id;
      }
    }
    if (urdu) {
      for (final id in _localeIds) {
        if (norm(id).startsWith('ur')) return id;
      }
    }
    return want.first;
  }

  /// [auto]: started on open — it never takes over while the owner types.
  Future<void> _start({bool auto = false}) async {
    if (!await _ensureSpeech() || !mounted) return;
    if (auto && (_textFocus.hasFocus || _text.text.isNotEmpty)) return;
    if (_speech.isListening) await _speech.cancel();
    if (!mounted) return;
    _textFocus.unfocus();
    setState(() {
      _notice = null;
      _listening = true;
      _level = 0;
    });
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: (level) {
          if (mounted) setState(() => _level = level);
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeFor(_urdu),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _notice = ref.read(storeStringsProvider).voiceNotAvailable;
      });
    }
  }

  Future<void> _stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) setState(() => _listening = false);
  }

  void _onStatus(String status) {
    if (!mounted) return;
    final listening = status == SpeechToText.listeningStatus;
    if (listening != _listening) setState(() => _listening = listening);
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted) return;
    final ss = ref.read(storeStringsProvider);
    debugPrint('Voice entry: ${e.errorMsg}');
    // Android marks every error "permanent", so only the kind matters.
    final message = switch (e.errorMsg) {
      'error_permission' || 'error_insufficient_permissions' => ss.voiceMicDenied,
      'error_language_not_supported' || 'error_language_unavailable' =>
        ss.voiceLangMissing,
      'error_network' ||
      'error_network_timeout' ||
      'error_server' ||
      'error_server_disconnected' ||
      'error_too_many_requests' =>
        ss.voiceNeedsNet,
      _ => ss.voiceHeardNothing,
    };
    setState(() {
      _listening = false;
      // A result already on screen beats "didn't catch that".
      if (!(_parsed && message == ss.voiceHeardNothing)) _notice = message;
    });
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final texts = [
      for (final a in result.alternates)
        if (a.recognizedWords.trim().isNotEmpty) a.recognizedWords.trim(),
    ];
    if (texts.isEmpty) return;
    final menu = ref.read(productListProvider);
    final people = ref.read(peopleListProvider);
    if (result.finalResult) {
      final best = VoiceSaleParser.parseBest(texts, menu: menu, people: people);
      _setText(best.text);
      _apply(best.draft);
    } else {
      _setText(texts.first);
      _apply(VoiceSaleParser.parse(texts.first, menu: menu, people: people));
    }
  }

  void _setText(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onTyped(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsed = false;
        _lines = const [];
        if (widget.person == null) {
          _person = null;
          _newName = null;
        }
      });
      return;
    }
    _apply(VoiceSaleParser.parse(
      text,
      menu: ref.read(productListProvider),
      people: ref.read(peopleListProvider),
    ));
  }

  void _apply(VoiceSaleDraft d) {
    setState(() {
      _parsed = true;
      _notice = null;
      _lines = d.lines;
      if (widget.person == null) {
        _person = d.person;
        _newName = d.person == null ? d.personName : null;
      }
      final named = _person != null || _newName != null;
      _pending = d.status != null ? d.status == EntryStatus.pending : named;
    });
  }

  void _setLanguage(bool urdu) {
    if (urdu == _urdu) return;
    setState(() => _urdu = urdu);
    if (_listening) unawaited(_start());
  }

  // ── Editing ────────────────────────────────────────────────────────────

  void _updateLine(int i, VoiceSaleLine line) {
    setState(() => _lines = [..._lines]..[i] = line);
  }

  void _removeLine(int i) {
    setState(() => _lines = [..._lines]..removeAt(i));
  }

  Future<void> _pickItem(int i) async {
    final ss = ref.read(storeStringsProvider);
    final money = ref.read(moneyProvider);
    final menu = ref.read(productListProvider);
    final picked = await showCreamSheet<ProductModel>(
      context,
      title: ss.voicePickItem,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final p in menu)
              ListTile(
                title: Text(p.name),
                subtitle: Text(
                  p.hasVariants
                      ? p.variants
                          .map((v) => '${v.name} ${money(v.price)}')
                          .join(' · ')
                      : money(p.price),
                ),
                trailing: p.inStock
                    ? null
                    : Text(
                        ss.outOfStock,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted && i < _lines.length) {
      _updateLine(i, _lines[i].copyWith(product: picked));
    }
  }

  Future<void> _pickPerson() async {
    final ss = ref.read(storeStringsProvider);
    final people = ref.read(peopleListProvider);
    final nameCtrl = TextEditingController(text: _newName ?? '');
    // PersonModel = existing, String = new name, false = no name.
    final picked = await showCreamSheet<Object>(
      context,
      title: ss.choosePerson,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: ss.personNameLabel,
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final v = nameCtrl.text.trim();
                      if (v.isNotEmpty) Navigator.pop(ctx, v);
                    },
                    child: Text(ss.add),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(ss.noPersonOption),
              onTap: () => Navigator.pop(ctx, false),
            ),
            for (final p in people)
              ListTile(
                leading: InitialAvatar(name: p.name, size: 34),
                title: Text(p.name),
                subtitle: p.phoneLocal.isEmpty ? null : Text(p.displayPhone),
                selected: p.id == _person?.id,
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
    if (!mounted || picked == null) return;
    setState(() {
      if (picked is PersonModel) {
        _person = picked;
        _newName = null;
        _pending = true;
      } else if (picked is String) {
        final match = people.where(
          (p) => p.name.trim().toLowerCase() == picked.toLowerCase(),
        );
        _person = match.isEmpty ? null : match.first;
        _newName = match.isEmpty ? picked : null;
        _pending = true;
      } else {
        _person = null;
        _newName = null;
        _pending = false;
      }
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────

  bool get _canSave => _lines.isNotEmpty && _lines.every((l) => l.isReady);

  double get _total => _lines.fold(0, (sum, l) => sum + l.total);

  void _save() {
    if (!_canSave) return;
    final ss = ref.read(storeStringsProvider);
    final now = DateTime.now();
    void failed(Object _) =>
        showRootSnack(message: ss.somethingWrong, type: AppSnackType.error);

    var personId = _person?.id;
    final newName = _newName?.trim() ?? '';
    if (personId == null && newName.isNotEmpty) {
      final person = PersonModel(id: 'p${now.millisecondsSinceEpoch}', name: newName);
      personId = person.id;
      unawaited(ref.read(peopleActionsProvider).add(person).catchError(failed));
    }

    final categoryId = ref
            .read(categoriesRepositoryProvider)
            .firstIdForScope(CategoryScope.got) ??
        '';
    final actions = ref.read(expenseActionsProvider);
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      final entry = ExpenseModel(
        id: '${now.millisecondsSinceEpoch + i}',
        amount: l.total,
        categoryId: categoryId,
        note: '',
        date: now,
        type: ExpenseRecordType.income,
        personId: personId,
        itemName: l.label,
        quantity: l.qty.toDouble(),
        unit: StockUnits.defaultSale,
        unitPrice: l.unitPrice,
        book: EntryBook.shop,
        status: _pending ? EntryStatus.pending : EntryStatus.paid,
      );
      // Firestore keeps the write on the phone (works offline).
      unawaited(actions.add(entry).catchError(failed));
    }
    showRootSnack(message: ss.voiceSaved, type: AppSnackType.success);
    Navigator.of(context).pop();
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final menu = ref.watch(productListProvider);
    final name = _person?.name ?? _newName;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(ss.voiceTitle, style: AppFonts.display(size: 21)),
                  ),
                  IconButton(
                    tooltip: ss.cancel,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: menu.isEmpty
                  ? EmptyHint(
                      icon: Icons.restaurant_menu_rounded,
                      title: ss.voiceMenuEmptyTitle,
                      body: ss.voiceMenuEmptyBody,
                      action: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProductFormScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(ss.addProduct),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(
                          ss.voiceSay(voiceExample(menu)),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ss.voiceHowTo,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(ss.voiceLangRoman),
                                selected: !_urdu,
                                onSelected: (_) => _setLanguage(false),
                              ),
                              ChoiceChip(
                                label: Text(ss.voiceLangUrdu),
                                selected: _urdu,
                                onSelected: (_) => _setLanguage(true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: _MicButton(
                            listening: _listening,
                            level: _level,
                            onTap: () => _listening ? _stop() : _start(),
                          ),
                        ),
                        Text(
                          _listening
                              ? ss.voiceListening
                              : (_notice ?? ss.voiceTapToSpeak),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _notice != null && !_listening
                                ? AppColors.pending
                                : AppColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_notice == ss.voiceMicDenied && !_listening)
                          Center(
                            child: TextButton(
                              onPressed: openAppSettings,
                              child: Text(ss.openSettings),
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _text,
                          focusNode: _textFocus,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: _onTyped,
                          decoration: InputDecoration(
                            hintText: ss.voiceTypeHint,
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                            suffixIcon: _text.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: ss.cancel,
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _text.clear();
                                      _onTyped('');
                                    },
                                  ),
                          ),
                        ),
                        if (_parsed && _lines.isEmpty) ...[
                          const SizedBox(height: 12),
                          _Notice(text: ss.voiceNothingFound),
                        ],
                        if (_lines.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          CreamCard(
                            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                            child: Column(
                              children: [
                                for (var i = 0; i < _lines.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.creamBorder,
                                    ),
                                  _LineRow(
                                    line: _lines[i],
                                    ss: ss,
                                    money: money,
                                    onChanged: (l) => _updateLine(i, l),
                                    onRemove: () => _removeLine(i),
                                    onPickItem: () => _pickItem(i),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomerRow(
                            name: name,
                            isNew: _person == null && _newName != null,
                            locked: widget.person != null,
                            ss: ss,
                            onChange: _pickPerson,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: StatusChoice(
                                  label: ss.statusPaid,
                                  icon: Icons.check_circle_outline_rounded,
                                  color: AppColors.brand,
                                  selected: !_pending,
                                  onTap: () => setState(() => _pending = false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StatusChoice(
                                  label: ss.statusPending,
                                  icon: Icons.schedule_rounded,
                                  color: pendingColor,
                                  selected: _pending,
                                  onTap: () => setState(() => _pending = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _pending ? ss.hintPendingIn : ss.hintPaidIn,
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (_lines.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: FilledButton.icon(
                    onPressed: _canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      name != null
                          ? ss.voiceSaveOn(money(_total), name)
                          : ss.voiceSaveSale(money(_total)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.level,
    required this.onTap,
  });

  final bool listening;

  /// Loudness from the recognizer (about −2 to 10 on Android).
  final double level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = listening ? AppColors.danger : AppColors.brand;
    final grow = listening ? (level.clamp(0, 10) / 10) : 0.0;
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 88 + 34 * grow,
            height: 88 + 34 * grow,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: listening ? 0.18 : 0.1),
            ),
          ),
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 76,
                height: 76,
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pendingSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.pending, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.ss,
    required this.money,
    required this.onChanged,
    required this.onRemove,
    required this.onPickItem,
  });

  final VoiceSaleLine line;
  final StoreStrings ss;
  final String Function(num) money;
  final ValueChanged<VoiceSaleLine> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickItem;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    if (product == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.pending, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ss.voiceNotOnMenu(line.heard),
                style: const TextStyle(fontSize: 13.5, height: 1.3),
              ),
            ),
            TextButton(onPressed: onPickItem, child: Text(ss.voicePickItem)),
            IconButton(
              tooltip: ss.delete,
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.inkSoft,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onPickItem,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                line.isReady ? money(line.total) : '—',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              IconButton(
                tooltip: ss.delete,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.inkSoft,
              ),
            ],
          ),
          if (product.hasVariants) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final v in product.variants)
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${v.name} · ${money(v.price)}'),
                    selected: line.variant?.name == v.name,
                    onSelected: (_) => onChanged(line.copyWith(variant: v)),
                  ),
              ],
            ),
            if (line.needsSize)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  ss.voiceChooseSize,
                  style: const TextStyle(
                    color: AppColors.pending,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          if (line.alternatives.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final alt in line.alternatives)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(alt.name),
                    onPressed: () => onChanged(line.copyWith(product: alt)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              QtyStepper(
                qty: line.qty,
                onMinus: () => line.qty > 1
                    ? onChanged(line.copyWith(qty: line.qty - 1))
                    : onRemove(),
                onPlus: () => onChanged(line.copyWith(qty: line.qty + 1)),
              ),
              const SizedBox(width: 10),
              if (line.isReady)
                Text(
                  '${line.qty} × ${money(line.unitPrice)}',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.name,
    required this.isNew,
    required this.locked,
    required this.ss,
    required this.onChange,
  });

  final String? name;
  final bool isNew;
  final bool locked;
  final StoreStrings ss;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final n = name;
    return CreamCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          if (n != null)
            InitialAvatar(name: n, size: 36)
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.brandDark, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ss.voiceCustomer,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        n ?? ss.voiceNoName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      SoftChip(
                        label: ss.voiceNewPerson,
                        background: AppColors.dispatchedSoft,
                        foreground: AppColors.dispatched,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!locked)
            TextButton(onPressed: onChange, child: Text(ss.voiceChange)),
        ],
      ),
    );
  }
}

/// "Speak to write in khata" card for the Home and Khata screens.
class VoiceEntryBar extends ConsumerWidget {
  const VoiceEntryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final menu = ref.watch(productListProvider);
    return Material(
      color: AppColors.creamCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.creamBorder),
      ),
      child: InkWell(
        onTap: () => showVoiceEntrySheet(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ss.voiceBarTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ss.voiceSay(voiceExample(menu)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
