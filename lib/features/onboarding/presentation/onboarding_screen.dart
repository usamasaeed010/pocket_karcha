import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/features/auth/presentation/auth_screen.dart';
import 'package:pocket_karcha/features/store_setup/store_gate.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_logo.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// First screen: three slides, then "Create my store" (guest account, no
/// sign-up form) or "I already have a store" (email sign-in).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _createStore() async {
    if (_busy) return;
    final ss = ref.read(storeStringsProvider);
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      context.showErrorSnack(ss.serviceUnavailable);
      return;
    }
    setState(() => _busy = true);
    try {
      final session = ref.read(sessionProvider.notifier);
      await session.completeOnboarding();
      final existing = auth.currentUser;
      final user = existing ?? (await auth.signInAnonymously()).user;
      if (user == null) throw FirebaseAuthException(code: 'no-user');
      await session.applyFirebaseUser(user, profileComplete: false);
      if (!mounted) return;
      if (existing == null) {
        AppNavigator.toStoreSetup(context);
      } else {
        await StoreGate.go(context, ref, user.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      switch (e.code) {
        // Anonymous sign-in is switched off in the Firebase console:
        // fall back to a normal email account.
        case 'operation-not-allowed' || 'admin-restricted-operation':
          context.showInfoSnack(ss.quickStartUnavailable);
          _openAuth(signUp: true);
        case 'network-request-failed':
          context.showErrorSnack(ss.checkInternet);
        default:
          context.showErrorSnack(ss.somethingWrong);
      }
    } catch (e) {
      debugPrint('Create store: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      context.showErrorSnack(ss.somethingWrong);
    }
  }

  Future<void> _openAuth({required bool signUp}) async {
    await ref.read(sessionProvider.notifier).completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(startInSignUp: signUp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final slides = [
      (ss.obTag1, ss.obTitle1, ss.obBody1, _StorePageMock(urdu: ss.isUrdu)),
      (ss.obTag2, ss.obTitle2, ss.obBody2, _OrdersMock(strings: ss)),
      (ss.obTag3, ss.obTitle3, ss.obBody3, _MoneyMock(strings: ss)),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(
                children: [
                  const AppLogo(size: 34, borderRadius: 10, showShadow: false),
                  const SizedBox(width: 10),
                  Text('Pocket Karcha', style: AppFonts.display(size: 18)),
                  const Spacer(),
                  _LanguageToggle(
                    urdu: ss.isUrdu,
                    onChanged: (urdu) =>
                        ref.read(appSettingsProvider.notifier).setUrdu(urdu),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (tag, title, body, art) = slides[i];
                  return _Slide(tag: tag, title: title, body: body, art: art);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.brand : AppColors.creamBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _createStore,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(ss.createMyStore),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : () => _openAuth(signUp: false),
                    child: Text(ss.haveStore),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ss.freeNoCommission,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.tag,
    required this.title,
    required this.body,
    required this.art,
  });

  final String tag;
  final String title;
  final String body;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: art),
            ),
          ),
          const SizedBox(height: 18),
          SoftChip(
            label: tag,
            background: AppColors.brandSoft,
            foreground: AppColors.brandDark,
            fontSize: 12.5,
          ),
          const SizedBox(height: 12),
          Text(title, style: AppFonts.display(size: 28, height: 1.15)),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.urdu, required this.onChanged});

  final bool urdu;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) {
      final selected = urdu == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.creamCard : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: AppColors.creamBorder) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.creamDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('EN', false), option('اردو', true)],
      ),
    );
  }
}

// ── Slide artwork (plain widgets, no images) ────────────────────────────────

class _MockCard extends StatelessWidget {
  const _MockCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StorePageMock extends StatelessWidget {
  const _StorePageMock({required this.urdu});

  final bool urdu;

  String _t(String en, String ur) => urdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_t('Mango Shake', 'مینگو شیک'), 250),
      (_t('Zinger Burger', 'زنگر برگر'), 450),
      (_t('Fries', 'فرائز'), 150),
    ];
    return _MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🥤', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Ali Juice Corner', 'علی جوس کارنر'),
                      style: AppFonts.display(size: 16),
                    ),
                    Text(
                      AppUrls.storeLinkDisplay('ali-juice'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (name, price) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatMoney(price, 'Rs'),
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.whatsapp,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _t('Send order · Rs 850', 'آرڈر بھیجیں · Rs 850'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _OrdersMock extends StatelessWidget {
  const _OrdersMock({required this.strings});

  final StoreStrings strings;

  @override
  Widget build(BuildContext context) {
    final ur = strings.isUrdu;
    final rows = [
      (ur ? 'عائشہ' : 'Ayesha', 3, 1250, OrderStatus.pending),
      (ur ? 'بلال' : 'Bilal', 2, 640, OrderStatus.confirmed),
      (ur ? 'ثنا' : 'Sana', 4, 900, OrderStatus.delivered),
    ];
    return SizedBox(
      width: 290,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (name, count, total, status) in rows) ...[
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.creamCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.creamBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Container(width: 5, color: OrderColors.bar(status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${strings.itemsLabel(count)} · ${formatMoney(total, 'Rs')}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SoftChip(
                    label: strings.statusLabel(status),
                    background: OrderColors.chipBg(status),
                    foreground: OrderColors.chipFg(status),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MoneyMock extends StatelessWidget {
  const _MoneyMock({required this.strings});

  final StoreStrings strings;

  @override
  Widget build(BuildContext context) {
    final ur = strings.isUrdu;
    return _MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapsLabel(strings.toCollect),
          const SizedBox(height: 4),
          Text(
            formatMoney(2350, 'Rs'),
            style: AppFonts.display(size: 30, color: AppColors.pending),
          ),
          const SizedBox(height: 14),
          _MoneyRow(
            name: ur ? 'حمزہ' : 'Hamza',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.dueAmount(formatMoney(800, 'Rs')),
                  style: const TextStyle(
                    color: AppColors.pending,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                SoftChip(
                  icon: Icons.chat_rounded,
                  label: strings.remind,
                  background: AppColors.whatsapp,
                  foreground: Colors.white,
                ),
              ],
            ),
          ),
          const Divider(height: 18, color: AppColors.creamBorder),
          _MoneyRow(
            name: ur ? 'ثنا' : 'Sana',
            trailing: SoftChip(
              icon: Icons.check_rounded,
              label: strings.paidLabel,
              background: AppColors.brandSoft,
              foreground: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.name, required this.trailing});

  final String name;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialAvatar(name: name, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        trailing,
      ],
    );
  }
}
