import 'package:flutter/material.dart';

/// Global app lifecycle callbacks (resume / pause).
abstract final class AppLifecycleNotifier {
  static final _resumeListeners = <VoidCallback>{};
  static final _pauseListeners = <VoidCallback>{};

  static void addResumeListener(VoidCallback listener) {
    _resumeListeners.add(listener);
  }

  static void removeResumeListener(VoidCallback listener) {
    _resumeListeners.remove(listener);
  }

  static void addPauseListener(VoidCallback listener) {
    _pauseListeners.add(listener);
  }

  static void removePauseListener(VoidCallback listener) {
    _pauseListeners.remove(listener);
  }

  static void notifyResumed() {
    for (final listener in List<VoidCallback>.from(_resumeListeners)) {
      listener();
    }
  }

  static void notifyPaused() {
    for (final listener in List<VoidCallback>.from(_pauseListeners)) {
      listener();
    }
  }
}

/// Observes [AppLifecycleState] and notifies [AppLifecycleNotifier].
class AppLifecycleWrapper extends StatefulWidget {
  const AppLifecycleWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppLifecycleNotifier.notifyResumed();
      case AppLifecycleState.paused:
        AppLifecycleNotifier.notifyPaused();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
