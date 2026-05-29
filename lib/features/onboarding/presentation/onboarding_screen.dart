import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

final onboardingPageProvider = StateProvider<int>((ref) => 0);

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).completeOnboarding();
    if (!mounted) return;
    AppNavigator.toAuth(context);
  }

  void _next(int total) {
    final page = ref.read(onboardingPageProvider);
    if (page < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final urdu = ref.watch(localeUrduProvider);
    final s = AppStrings(urdu);
    final pages = _pages(s);
    final page = ref.watch(onboardingPageProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(s.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) =>
                      ref.read(onboardingPageProvider.notifier).state = i,
                  itemBuilder: (_, i) => pages[i],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => Container(
                    width: page == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: page == i
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: page == pages.length - 1 ? s.getStarted : s.next,
                  onPressed: () => _next(pages.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pages(AppStrings s) {
    return [
      _OnboardingPage(
        icon: Icons.account_balance_wallet_rounded,
        title: s.onboardingTitle1,
        body: s.onboardingBody1,
      ),
      _OnboardingPage(
        icon: Icons.pie_chart_outline_rounded,
        title: s.onboardingTitle2,
        body: s.onboardingBody2,
      ),
      _LanguageOnboardingPage(
        title: s.onboardingTitle3,
        body: s.onboardingBody3,
        urduLabel: s.urdu,
        englishLabel: s.english,
      ),
    ];
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 88, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOnboardingPage extends ConsumerWidget {
  const _LanguageOnboardingPage({
    required this.title,
    required this.body,
    required this.urduLabel,
    required this.englishLabel,
  });

  final String title;
  final String body;
  final String urduLabel;
  final String englishLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.translate_rounded, size: 88, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xl),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(englishLabel)),
              ButtonSegment(value: true, label: Text(urduLabel)),
            ],
            selected: {urdu},
            onSelectionChanged: (set) {
              ref.read(appSettingsProvider.notifier).setUrdu(set.first);
            },
          ),
        ],
      ),
    );
  }
}
