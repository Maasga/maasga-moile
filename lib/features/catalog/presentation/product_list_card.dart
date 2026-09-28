import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/asset_utils.dart';
import '../../../shared/design_tokens/maasga_tokens.dart';
import '../domain/product.dart';

class ProductListCard extends StatelessWidget {
  const ProductListCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  String _formatPrice(int price) {
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: context.isDarkMode ? 0.35 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (gauche)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: palette.cardAlt,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Color(0xFFBDBDBD),
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        AssetUtils.getAssetPath(product.image),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/products/product_placeholder.png',
                          );
                        },
                      ),
              ),
            ),
            // Infos (droite)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600, // SemiBold
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Specs - Bullet points
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: product.specs.take(3).map((spec) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1B3A8D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400, // Regular
                                    color: const Color(0xFF757575),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Prix et Bouton
                    Row(
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700, // Bold
                            color: const Color(0xFF1B3A8D),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: onAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A8D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            '+ Panier',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600, // SemiBold
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
