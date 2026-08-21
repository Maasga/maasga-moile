import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../features/cart/presentation/cart_state.dart';
import '../design_tokens/maasga_tokens.dart';

class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key, required this.currentPath});

  final String currentPath;

  int _indexFromPath() {
    if (currentPath.startsWith('/catalog') ||
        currentPath.startsWith('/catalogue')) {
      return 1;
    }
    if (currentPath.startsWith('/simulator') ||
        currentPath.startsWith('/simulateur')) {
      return 2;
    }
    if (currentPath.startsWith('/rdv') ||
        currentPath.startsWith('/rendez-vous') ||
        currentPath.startsWith('/service') ||
        currentPath.startsWith('/support')) {
      return 3;
    }
    if (currentPath.startsWith('/maintenance')) return 4;
    if (currentPath.startsWith('/cart')) return 5;
    if (currentPath.startsWith('/client-space') ||
        currentPath.startsWith('/espace-client')) {
      return 6;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final cartCount = lines.fold<int>(0, (sum, line) => sum + line.quantity);

    final palette = context.maasga;
    // Le bleu marine de la charte n'a presque aucun contraste sur la barre
    // sombre : en mode sombre, c'est le cyan qui porte l'état actif.
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
            selectedIndex: _indexFromPath(),
            onTabChange: (index) {
              const routes = <String>[
                '/home',
                '/catalog',
                '/simulator',
                '/rdv',
                '/maintenance',
                '/cart',
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
                icon: Icons.calculate_outlined,
                text: 'Simul.',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.build_outlined,
                text: 'Services',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.verified_user_outlined,
                text: 'Contrat',
                textStyle: labelStyle,
              ),
              GButton(
                icon: Icons.shopping_cart_outlined,
                text: 'Panier',
                leading: _CartIcon(
                  cartCount: cartCount,
                  isSelected: _indexFromPath() == 5,
                ),
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

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.cartCount, required this.isSelected});

  final int cartCount;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final iconColor = isSelected ? palette.accent : palette.textMuted;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
          color: iconColor,
          size: 22,
        ),
        if (cartCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.danger,
                // Le liseré reprend le fond de la barre : c'est lui qui détache
                // la pastille de l'icône, quel que soit le mode.
                border: Border.all(color: palette.card, width: 1),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              alignment: Alignment.center,
              child: Text(
                // '9+' et non '9' : afficher « 9 » pour 12 articles annonce un
                // panier plus petit qu'il ne l'est.
                cartCount > 9 ? '9+' : '$cartCount',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
