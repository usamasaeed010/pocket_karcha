import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/features/orders/presentation/customer_detail_screen.dart';
import 'package:pocket_karcha/features/orders/widgets/order_card.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Orders tab: Orders | Customers, search, status filters, day groups.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late final TextEditingController _search =
      TextEditingController(text: ref.read(orderSearchProvider));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _filterLabel(StoreStrings ss, OrderFilter f) => switch (f) {
        OrderFilter.all => ss.filterAll,
        OrderFilter.unpaid => ss.filterUnpaid,
        OrderFilter.pending => ss.filterStatusLabel(OrderStatus.pending),
        OrderFilter.confirmed => ss.filterStatusLabel(OrderStatus.confirmed),
        OrderFilter.dispatched => ss.filterStatusLabel(OrderStatus.dispatched),
        OrderFilter.delivered => ss.filterStatusLabel(OrderStatus.delivered),
        OrderFilter.cancelled => ss.filterStatusLabel(OrderStatus.cancelled),
      };

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final segment = ref.watch(ordersSegmentProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: segment == 0
          ? FloatingActionButton.extended(
              heroTag: 'orders-fab',
              onPressed: () => StoreActions.counterOrder(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(ss.newOrder),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(ss.ordersTitle, style: AppFonts.display(size: 26)),
                ),
                PillToggle(
                  labels: [ss.ordersTitle, ss.customersTab],
                  index: segment,
                  onChanged: (i) =>
                      ref.read(ordersSegmentProvider.notifier).state = i,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StoreSearchField(
              controller: _search,
              hint: segment == 0 ? ss.searchOrders : ss.searchCustomers,
              onChanged: (v) => ref.read(orderSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: segment == 0
                ? _OrdersList(filterLabel: _filterLabel)
                : const _CustomersList(),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.filterLabel});

  final String Function(StoreStrings, OrderFilter) filterLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final filter = ref.watch(orderFilterProvider);
    final counts = ref.watch(orderFilterCountsProvider);
    final all = ref.watch(orderListProvider);
    final orders = ref.watch(filteredOrdersProvider);
    final loading = ref.watch(ordersProvider).isLoading && all.isEmpty;

    // Day headers + order rows. The list is newest first, so one day's
    // orders are next to each other.
    final groups = <_DayGroup>[];
    String? lastKey;
    for (final o in orders) {
      final d = o.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      if (key != lastKey) {
        lastKey = key;
        groups.add(_DayGroup(TimeAgo.dayLabel(d, urdu: ss.isUrdu), [o]));
      } else {
        groups.last.orders.add(o);
      }
    }
    final entries = <Object>[
      for (final g in groups) ...[g, ...g.orders],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            children: [
              for (final f in OrderFilter.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _FilterChip(
                    label: filterLabel(ss, f),
                    count: counts[f] ?? 0,
                    selected: f == filter,
                    onTap: () =>
                        ref.read(orderFilterProvider.notifier).state = f,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : all.isEmpty
                  ? ListView(
                      children: [
                        EmptyHint(
                          icon: Icons.receipt_long_outlined,
                          title: ss.noOrdersTitle,
                          body: ss.noOrdersBody,
                          action: FilledButton.icon(
                            onPressed: () => StoreActions.shareOnWhatsApp(ref),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.whatsapp,
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(ss.shareOnWhatsapp),
                          ),
                        ),
                      ],
                    )
                  : orders.isEmpty
                      ? ListView(
                          children: [
                            EmptyHint(
                              icon: Icons.search_off_rounded,
                              title: ss.noOrdersMatch,
                              body: '',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: entries.length,
                          itemBuilder: (context, i) {
                            final e = entries[i];
                            if (e is _DayGroup) {
                              final total = e.orders
                                  .where((o) => !o.isCancelled)
                                  .fold<double>(0, (s, o) => s + o.total);
                              final pending = e.orders
                                  .where((o) => o.status == OrderStatus.pending)
                                  .length;
                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  2,
                                  i == 0 ? 6 : 16,
                                  2,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      e.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ss.dayHeader(
                                          e.orders.length,
                                          money(total),
                                          pending,
                                        ),
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final o = e as OrderModel;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OrderCard(
                                order: o,
                                strings: ss,
                                money: money,
                                onTap: () => StoreActions.openOrder(context, o.id),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _DayGroup {
  const _DayGroup(this.label, this.orders);

  final String label;
  final List<OrderModel> orders;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : AppColors.creamCard,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.brand : AppColors.creamBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomersList extends ConsumerWidget {
  const _CustomersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final all = ref.watch(customersProvider);
    final list = ref.watch(filteredCustomersProvider);

    if (all.isEmpty) {
      return ListView(
        children: [
          EmptyHint(
            icon: Icons.people_outline_rounded,
            title: ss.noCustomersTitle,
            body: ss.noCustomersBody,
          ),
        ],
      );
    }
    if (list.isEmpty) {
      return ListView(
        children: [
          EmptyHint(
            icon: Icons.search_off_rounded,
            title: ss.noOrdersMatch,
            body: '',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = list[i];
        return CustomerRow(
          customer: c,
          strings: ss,
          money: money,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomerDetailScreen(customerKey: c.key),
            ),
          ),
        );
      },
    );
  }
}
