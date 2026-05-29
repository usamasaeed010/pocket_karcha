import 'package:flutter/material.dart';
import 'package:pocket_karcha/features/shell/presentation/main_shell_screen.dart';

/// Entry after login — shell with bottom navigation + dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShellScreen();
  }
}
