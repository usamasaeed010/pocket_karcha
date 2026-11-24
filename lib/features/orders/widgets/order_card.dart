import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Order row: status bar on the left, name, chips, number and amount.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.strings,
    required this.money,
    required this.onTap,
  });

  final OrderModel order;
  final StoreStrings strings;
  final String Function(num) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ss = strings;
    final o = order;
    final name = o.displayName.isEmpty ? ss.walkIn : o.displayName;
    final what = o.isRequest ? ss.request : ss.itemsLabel(o.itemCount);
    final mode = o.fulfillment == Fulfillment.pickup ? ss.pickup : ss.delivery;
    final meta =
        '#${o.number} · ${TimeAgo.short(o.createdAt, urdu: ss.isUrdu)} · $what · $mode';

    return CreamCard(
      padding: EdgeInsets.zero,
      radius: 14,
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      o.source == OrderSource.link
                          ? Icons.link_rounded
                          : Icons.storefront_outlined,
                      size: 15,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: o.isCancelled ? AppColors.inkSoft : AppColors.ink,
                          decoration:
                              o.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      o.total > 0 ? money(o.total) : '—',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: o.isCancelled ? AppColors.inkFaint : AppColors.brand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    SoftChip(
                      label: ss.statusLabel(o.status, fulfillment: o.fulfillment),
                      background: OrderColors.chipBg(o.status),
                      foreground: OrderColors.chipFg(o.status),
                    ),
                    ?paymentChip(o, ss, money),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: OrderColors.bar(o.status)),
          ),
        ],
      ),
    );
  }

  /// "Paid" / "Rs 300 due" / "Payment pending" — null for cancelled orders.
  static Widget? paymentChip(
    OrderModel o,
    StoreStrings ss,
    String Function(num) money,
  ) {
    if (o.isCancelled) return null;
    if (o.isRequest && o.total <= 0) {
      return SoftChip(
        label: ss.request,
        background: AppColors.dispatchedSoft,
        foreground: const Color(0xFF2257B3),
        icon: Icons.chat_bubble_outline_rounded,
      );
    }
    switch (o.paymentState) {
      case PaymentState.paid:
        return SoftChip(
          label: ss.paidLabel,
          background: AppColors.brandSoft,
          foreground: AppColors.brandDark,
          icon: Icons.check_rounded,
        );
      case PaymentState.partial:
        return SoftChip(
          label: ss.dueAmount(money(o.due)),
          background: AppColors.pendingSoft,
          foreground: const Color(0xFFB4650F),
        );
      case PaymentState.unpaid:
        return SoftChip(
          label: ss.paymentPending,
          background: AppColors.dangerSoft,
          foreground: const Color(0xFFB23B3B),
        );
    }
  }
}

/// Buyer row in the Customers list.
class CustomerRow extends StatelessWidget {
  const CustomerRow({
    super.key,
    required this.customer,
    required this.strings,
    required this.money,
    required this.onTap,
  });

  final CustomerSummary customer;
  final StoreStrings strings;
  final String Function(num) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final title = c.name.isNotEmpty ? c.name : c.phone;
    return CreamCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      onTap: onTap,
      child: Row(
        children: [
          InitialAvatar(name: title, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings.ordersLabel(c.orderCount)} · ${money(c.total)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          if (c.due > 0)
            SoftChip(
              label: strings.dueAmount(money(c.due)),
              background: AppColors.pendingSoft,
              foreground: const Color(0xFFB4650F),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
