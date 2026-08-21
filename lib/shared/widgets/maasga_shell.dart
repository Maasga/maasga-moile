import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens/maasga_tokens.dart';
import 'main_bottom_nav.dart';
import 'maasga_app_bar.dart';
import '../../features/notifications/data/activity_repository.dart';

class MaasgaShell extends ConsumerWidget {
  const MaasgaShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottomNavigationBar,
    this.showDrawer = false,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final bool showDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      drawer: null,
      appBar: MaasgaAppBar(notificationsCount: unreadNotificationCount),
      body: Container(
        decoration: BoxDecoration(gradient: context.maasga.pageGradient),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar:
          bottomNavigationBar ??
          MainBottomNav(currentPath: GoRouterState.of(context).uri.toString()),
    );
  }
}
