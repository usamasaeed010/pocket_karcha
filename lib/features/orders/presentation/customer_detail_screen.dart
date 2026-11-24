import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart' show storeStringsProvider;
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/features/orders/widgets/order_card.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// One buyer: totals, what they still owe, WhatsApp / call and their orders.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerKey});

  final String customerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final store = ref.watch(currentStoreProvider);
    final matches =
        ref.watch(customersProvider).where((c) => c.key == customerKey);
    final c = matches.isEmpty ? null : matches.first;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream),
      body: c == null
          ? Center(child: Text(ss.noCustomersTitle))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Row(
                  children: [
                    InitialAvatar(
                      name: c.name.isNotEmpty ? c.name : c.phone,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name.isNotEmpty ? c.name : c.phone,
                            style: AppFonts.display(size: 24),
                          ),
                          if (c.name.isNotEmpty && c.phone.isNotEmpty)
                            Text(
                              c.phone,
                              style: const TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 13.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (c.address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 17,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(label: ss.ordersCountLabel, value: '${c.orderCount}'),
                    const SizedBox(width: 8),
                    _Stat(label: ss.totalLabel, value: money(c.total)),
                    const SizedBox(width: 8),
                    _Stat(
                      label: ss.dueLabel,
                      value: money(c.due),
                      highlight: c.due > 0,
                    ),
                  ],
                ),
                if (c.phone.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => StoreActions.messageCustomer(
                            ref,
                            phone: c.phone,
                            text: ss.msgHello(
                              name: c.name,
                              store: store?.name ?? '',
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.whatsapp,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: Text(ss.whatsapp),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => StoreActions.callCustomer(c.phone),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: Text(ss.call),
                        ),
                      ),
                    ],
                  ),
                  if (c.due > 0) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => StoreActions.messageCustomer(
                        ref,
                        phone: c.phone,
                        text: ss.msgCustomerReminder(
                          name: c.name,
                          store: store?.name ?? '',
                          amount: money(c.due),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB4650F),
                        side: const BorderSide(color: Color(0xFFF3D9B5)),
                      ),
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: Text(ss.sendReminder),
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                CapsLabel(ss.ordersCaps),
                const SizedBox(height: 8),
                for (final o in c.orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OrderCard(
                      order: o,
                      strings: ss,
                      money: money,
                      onTap: () => StoreActions.openOrder(context, o.id),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CreamCard(
        radius: 12,
        color: highlight ? AppColors.pendingSoft : null,
        borderColor: highlight ? const Color(0xFFF3D9B5) : null,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: AppFonts.display(size: 18)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
