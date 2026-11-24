import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/item_list_parser.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Paste a whole menu ("Mango Shake - 250" per line) and add it at once.
///
/// With [onDone] (store setup) the parsed items are handed back instead of
/// being written to the store.
class PasteListScreen extends ConsumerStatefulWidget {
  const PasteListScreen({super.key, this.onDone});

  final ValueChanged<List<ProductModel>>? onDone;

  @override
  ConsumerState<PasteListScreen> createState() => _PasteListScreenState();
}

class _PasteListScreenState extends ConsumerState<PasteListScreen> {
  final _text = TextEditingController();
  List<ParsedItem> _items = const [];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _parse() => setState(() => _items = ItemListParser.parse(_text.text));

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text ?? '';
    if (t.trim().isEmpty) return;
    _text.text = _text.text.trim().isEmpty ? t : '${_text.text.trimRight()}\n$t';
    _parse();
  }

  void _add(StoreStrings ss) {
    // Items without a price show as out of stock until priced.
    final products = [
      for (final it in _items)
        ProductModel(
          id: '',
          name: it.name,
          price: it.price ?? 0,
          inStock: it.price != null,
        ),
    ];
    if (products.isEmpty) return;

    final onDone = widget.onDone;
    if (onDone != null) {
      onDone(products);
      Navigator.of(context).pop();
      return;
    }

    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    backgroundWrite(
      repo.addProducts(
        uid,
        products,
        startOrder: ref.read(productListProvider).length,
      ),
      ss,
    );
    showRootSnack(
      message: ss.productsAdded(products.length),
      type: AppSnackType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(ss.pasteListTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _parse(),
            decoration: InputDecoration(hintText: ss.pasteListHint),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pasteClipboard,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(ss.pasteFromClipboard),
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 8),
            CapsLabel(ss.itemsFound(_items.length)),
            const SizedBox(height: 8),
            CreamCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: AppColors.creamBorder,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _items[i].name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            _items[i].price == null
                                ? ss.noPriceYet
                                : money(_items[i].price!),
                            style: TextStyle(
                              fontSize: 13,
                              color: _items[i].price == null
                                  ? AppColors.pending
                                  : AppColors.brandDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _items.isEmpty ? null : () => _add(ss),
            child: Text(ss.addNProducts(_items.length)),
          ),
        ),
      ),
    );
  }
}
