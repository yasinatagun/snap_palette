import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/index.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../palette/presentation/screens/palettes_screen.dart';

/// Provider for bottom navigation tab index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main screen with bottom navigation
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final currentIndex = ref.watch(navigationIndexProvider);

    // If user is not logged in, redirect to login screen
    if (user == null) {
      return const LoginScreen();
    }

    // List of screens to show in the bottom nav
    final screens = [const HomeScreen(), const PalettesScreen()];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap:
            (index) => ref.read(navigationIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Palettes'),
        ],
      ),
    );
  }
}
