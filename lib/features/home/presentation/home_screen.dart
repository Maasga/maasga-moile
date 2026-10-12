import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/favorites_notifier.dart';
import '../../catalog/presentation/recent_products_notifier.dart';
import '../widgets/brand_scroll.dart';
import '../../../shared/widgets/main_bottom_nav.dart';
import '../../../shared/widgets/maasga_app_bar.dart';
import '../../../shared/utils/asset_utils.dart';
import '../../../shared/utils/price_formatter.dart';
import '../widgets/promo_banner.dart';
import '../../../shared/design_tokens/maasga_tokens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.maasga.pageGradient.colors.first,
      appBar: MaasgaAppBar(notificationsCount: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchBar()
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0),
            _LocationRow().animate().fadeIn(delay: 100.ms),
            const BrandScroll().animate().fadeIn(delay: 200.ms),
            const PromoBanner()
                .animate()
                .fadeIn(delay: 300.ms)
                .scale(begin: const Offset(0.95, 0.95)),
            const _RecentProductsSection(),
            const _FavoritesSection(),
            _InnovationsSection(formatPrice: PriceFormatter.format),
            const SizedBox(height: 18),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(
              alpha: context.isDarkMode ? 0.35 : 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => context.push('/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: palette.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(
                'Rechercher votre climatiseur...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Location Row ──────────────────────────────────────────────────────────────
class _LocationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.location_on, color: palette.warning, size: 18),
          const SizedBox(width: 8),
          Text(
            'Ouagadougou, Burkina Faso',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Récemment consultés ───────────────────────────────────────────────────────
class _RecentProductsSection extends ConsumerWidget {
  const _RecentProductsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentProductsProvider);
    if (recents.isEmpty) return const SizedBox.shrink();

    final palette = context.maasga;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Récemment consultés',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recents.length,
              itemBuilder: (context, index) {
                final p = recents[index];
                return _HomeProductCard(product: p);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Mes Favoris ──────────────────────────────────────────────────────────────
class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    if (favoriteIds.isEmpty) return const SizedBox.shrink();

    final productsAsync = ref.watch(productsProvider);
    final favoriteProducts = productsAsync.maybeWhen(
      data: (products) =>
          products.where((p) => favoriteIds.contains(p.id)).toList(),
      orElse: () => <Product>[],
    );

    if (favoriteProducts.isEmpty) return const SizedBox.shrink();

    final palette = context.maasga;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Mes Favoris',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/catalog'),
                  child: Text(
                    'Voir tout',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final p = favoriteProducts[index];
                return _HomeProductCard(product: p);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Carte produit carrousel ───────────────────────────────────────────────────
class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return GestureDetector(
      onTap: () => context.push('/catalog/product', extra: product),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: context.isDarkMode ? 0.35 : 0.07,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 110,
                color: palette.cardAlt,
                alignment: Alignment.center,
                child: product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty &&
                        !AssetUtils.getAssetPath(
                          product.imageUrl!,
                        ).contains('logo_maasga')
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/products/product_placeholder.png',
                          width: 70,
                          height: 70,
                        ),
                      )
                    : Image.asset(
                        AssetUtils.getAssetPath(
                          product.image.isNotEmpty
                              ? product.image
                              : (product.imageUrl ??
                                    'assets/products/product_placeholder.png'),
                        ),
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/products/product_placeholder.png',
                          width: 70,
                          height: 70,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PriceFormatter.format(product.price),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Innovations Section (uses real API data) ──────────────────────────────────
class _InnovationsSection extends ConsumerWidget {
  const _InnovationsSection({required this.formatPrice});

  final String Function(int price) formatPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Dernières Innovations',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.maasga.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/catalog'),
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.maasga.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Skeletonizer(
            enabled: productsAsync.isLoading,
            child: productsAsync.when(
              loading: () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) => _ProductCard(
                  product: Product(
                    id: 0,
                    name: 'Chargement...',
                    brand: 'MAASGA',
                    price: 150000,
                    category: 'Split',
                    image: '',
                    stock: 0,
                  ),
                  priceLabel: '150 000 F',
                ),
              ),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Impossible de charger les produits.',
                    style: GoogleFonts.poppins(
                      color: context.maasga.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (products) {
                final displayed = products.take(6).toList();
                if (displayed.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun produit disponible.',
                        style: GoogleFonts.poppins(
                          color: context.maasga.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayed.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final p = displayed[index];
                    return _ProductCard(
                          product: p,
                          priceLabel: formatPrice(p.price),
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Product Card (uses real Product model) ────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.priceLabel});

  final Product product;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return GestureDetector(
      onTap: () => context.go('/catalog'),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: context.isDarkMode ? 0.35 : 0.07,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    color: palette.cardAlt,
                    alignment: Alignment.center,
                    child:
                        product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty &&
                            !AssetUtils.getAssetPath(
                              product.imageUrl!,
                            ).contains('logo_maasga')
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/products/product_placeholder.png',
                              width: 80,
                              height: 80,
                            ),
                          )
                        : Image.asset(
                            AssetUtils.getAssetPath(
                              product.image.isNotEmpty
                                  ? product.image
                                  : (product.imageUrl ??
                                        'assets/products/product_placeholder.png'),
                            ),
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/products/product_placeholder.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
