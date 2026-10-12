import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../../shared/widgets/main_bottom_nav.dart';
import 'cart_item_card.dart';
import 'cart_state.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isPromoValid = false;
  bool _isPromoInvalid = false;
  static const double _remise = 100.0;
  static const String _validPromoCode = 'DROPSYEARAND';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      if (code == _validPromoCode) {
        _isPromoValid = true;
        _isPromoInvalid = false;
      } else {
        _isPromoValid = false;
        _isPromoInvalid = true;
      }
    });
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    final palette = context.maasga;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Supprimer l'article ?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        content: Text(
          'Voulez-vous retirer ce produit du panier ?',
          style: TextStyle(
            fontSize: 14,
            color: palette.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final double sousTotal = cart.fold(
      0.0,
      (sum, line) => sum + line.product.price * line.quantity,
    );
    final double remise = _isPromoValid ? _remise : 0.0;
    final double total = sousTotal - remise;

    return Scaffold(
      backgroundColor: palette.pageGradient.colors.first,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: palette.card,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Panier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 2-4. SCROLLABLE CONTENT
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: palette.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Votre panier est vide',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LISTE PRODUITS
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final line = cart[index];
                              return Dismissible(
                                key: ValueKey(line.product.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  return await _showDeleteDialog(context) ?? false;
                                },
                                onDismissed: (_) {
                                  final notifier = ref.read(cartProvider.notifier);
                                  for (int i = 0; i < line.quantity; i++) {
                                    notifier.remove(line.product);
                                  }
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: palette.danger,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                child: CartItemCard(
                                  line: line,
                                  onIncrement: () => cartNotifier.add(line.product),
                                  onDecrement: () {
                                    if (line.quantity == 1) {
                                      cartNotifier.remove(line.product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${line.product.name} retiré'),
                                          action: SnackBarAction(
                                            label: 'Annuler',
                                            onPressed: () =>
                                                cartNotifier.add(line.product),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    } else {
                                      cartNotifier.remove(line.product);
                                    }
                                  },
                                ),
                              );
                            },
                          ),

                          // 3. CODE PROMO
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avez-vous un code promo ?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _promoController,
                                        textCapitalization: TextCapitalization.characters,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: palette.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Entrez votre code',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: palette.textMuted,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                          filled: true,
                                          fillColor: palette.cardAlt,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: palette.cardBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: palette.cardBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: palette.accent),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: _applyPromo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: palette.accent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'Appliquer',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isPromoValid) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: palette.success, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _promoController.text.trim(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Disponible',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: palette.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_isPromoInvalid) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Code invalide',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: palette.danger,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 4. RÉCAPITULATIF
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Sous-total',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      PriceFormatter.format(sousTotal.toInt()),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isPromoValid) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Remise',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '-${PriceFormatter.format(remise.toInt())}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: palette.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                Divider(height: 20, color: palette.divider),
                                Row(
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      PriceFormatter.format(total.toInt()),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // 5. BOUTON VALIDER (fixe en bas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.card,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: cart.isEmpty ? null : () => context.push('/checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    disabledBackgroundColor: palette.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Valider la commande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom nav
            const MainBottomNav(),
          ],
        ),
      ),
    );
  }
}