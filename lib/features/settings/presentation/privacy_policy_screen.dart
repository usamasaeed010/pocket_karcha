import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_urls.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _loadFailed = false;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
              if (progress == 100) _loading = false;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _loadFailed = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadFailed = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(AppUrls.privacyPolicy));
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _progress = 0;
    });
    await _controller.loadRequest(Uri.parse(AppUrls.privacyPolicy));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return AppPage(
      title: s.privacyPolicy,
      body: Column(
        children: [
          if (_loading && _progress < 100)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress / 100 : null,
              minHeight: 2,
              color: AppColors.dashboardGreen,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          Expanded(
            child: _loadFailed
                ? _ErrorBody(
                    message: s.privacyPolicyLoadError,
                    retryLabel: s.retry,
                    onRetry: _reload,
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
