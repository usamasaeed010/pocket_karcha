import 'package:flutter/material.dart';
import 'package:pocket_karcha/features/shell/presentation/store_shell_screen.dart';

/// Entry after sign-in / store setup: Home · Orders · Products · Settings.
/// The old khata (MainShellScreen) opens from Settings → Khata.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoreShellScreen();
  }
}
