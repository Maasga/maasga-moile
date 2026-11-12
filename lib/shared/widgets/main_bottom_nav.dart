import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../design_tokens/maasga_tokens.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  int _indexFromPath(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/catalog') || path.startsWith('/catalogue')) return 1;
    if (path.startsWith('/rdv') ||
        path.startsWith('/rendez-vous') ||
        path.startsWith('/service') ||
        path.startsWith('/support')) {
      return 2;
    }
    if (path.startsWith('/simulator') || path.startsWith('/simulateur')) {
      return 3;
    }
    if (path.startsWith('/client-space') ||
        path.startsWith('/espace-client')) {
      return 4;
    }
    return 0; // /home et tout le reste
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final active = palette.accent;
    final inactive = palette.textMuted;

    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: active,
    );

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.divider)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: palette.shadow.withValues(
              alpha: context.isDarkMode ? .35 : .1,
            ),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
          child: GNav(
            rippleColor: active.withValues(alpha: 0.2),
            hoverColor: active.withValues(alpha: 0.1),
            gap: 4,
            activeColor: active,
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: active.withValues(alpha: 0.14),
            color: inactive,
            selectedIndex: _indexFromPath(context),
            onTabChange: (index) {
              const routes = <String>[
                '/home',
                '/catalog',
                '/rdv',
                '/simulator',
                '/client-space',
              ];
              context.go(routes[index]);
            },
            tabs: [
              GButton(
                icon: Icons.home_outlined,
                text: 'Accueil',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.grid_view_outlined,
                text: 'Catalogue',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.build_outlined,
                text: 'Services',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.calculate_outlined,
                text: 'Simul.',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.person_outline,
                text: 'Profil',
                textStyle: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
