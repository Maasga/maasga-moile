import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/utils/asset_utils.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../cart/presentation/cart_state.dart';
import '../data/review_repository.dart';
import '../domain/product.dart';
import '../domain/product_review.dart';
import 'favorites_notifier.dart';
import 'recent_products_notifier.dart';
import 'widgets/compare_bottom_sheet.dart';
import 'widgets/fiche_complete_bottom_sheet.dart';
import 'widgets/spec_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentProductsProvider.notifier).addRecent(widget.product);
    });
  }

  void _incrementQty() => setState(() => _quantity++);
  void _decrementQty() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _shareProduct() {
    Share.share(
      'Découvrez le ${widget.product.name} de ${widget.product.brand} — '
      '${PriceFormatter.format(widget.product.price)}\n\n'
      'Voir le catalogue MAASGA : https://maasga.com',
    );
  }

  void _addToCart() {
    for (var i = 0; i < _quantity; i++) {
      ref.read(cartProvider.notifier).add(widget.product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ajouté au panier'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: context.maasga.accent,
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white,
          onPressed: () {
            final router = GoRouter.of(context);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            router.push('/cart');
          },
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imgUrl, BoxFit fit) {
    if (imgUrl.isEmpty || imgUrl == '??') {
      return Image.asset('assets/products/product_placeholder.png', fit: fit);
    }
    if (imgUrl.trim().startsWith('data:image')) {
      try {
        final base64Str = imgUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          errorBuilder: (_, _, _) =>
              Image.asset('assets/products/product_placeholder.png', fit: fit),
        );
      } catch (e) {
        return Image.asset('assets/products/product_placeholder.png', fit: fit);
      }
    } else if (imgUrl.startsWith('http')) {
      return Image.network(
        imgUrl,
        fit: fit,
        errorBuilder: (_, _, _) =>
            Image.asset('assets/products/product_placeholder.png', fit: fit),
      );
    } else {
      return Image.asset(
        AssetUtils.getAssetPath(imgUrl),
        fit: fit,
        errorBuilder: (_, _, _) =>
            Image.asset('assets/products/product_placeholder.png', fit: fit),
      );
    }
  }

  void _showFicheComplete() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FicheCompleteBottomSheet(product: widget.product),
    );
  }

  void _showCompare() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompareBottomSheet(currentProduct: widget.product),
    );
  }

  void _showReviewBottomSheet() {
    double rating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final palette = ctx.maasga;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Laisser un avis',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        itemCount: 5,
                        itemPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: palette.warning,
                        ),
                        onRatingUpdate: (r) {
                          setModalState(() => rating = r);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: palette.inputTextStyle,
                      decoration: InputDecoration(
                        hintText: 'Votre commentaire...',
                        hintStyle: TextStyle(color: palette.textMuted),
                        filled: true,
                        fillColor: palette.cardAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: rating == 0
                            ? null
                            : () {
                                ref
                                    .read(
                                      reviewsProvider(
                                        widget.product.id,
                                      ).notifier,
                                    )
                                    .submitReview(
                                      rating.round(),
                                      commentController.text.trim(),
                                    );
                                Navigator.of(ctx).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Envoyer',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.maasga.pageGradient.colors.first,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildCarousel(),
              _buildThumbnails(),
              _buildProductInfo(),
              _buildTechnicalBrief(),
              _buildReviewsSection(),
              _buildFullSheetButton(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: context.maasga.card,
      elevation: 0,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildCircleButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Détails du Produit',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: context.maasga.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildCircleButton(
            icon: Icons.share_outlined,
            onTap: _shareProduct,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildCircleButton(
            icon: Icons.compare_arrows_outlined,
            onTap: _showCompare,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.maasga.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: context.maasga.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildCarousel() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          CarouselSlider(
            items: widget.product.images.map((img) {
              return Container(
                width: double.infinity,
                color: context.maasga.cardAlt,
                child: _buildImageWidget(img, BoxFit.contain),
              );
            }).toList(),
            carouselController: _carouselController,
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              onPageChanged: (index, _) {
                setState(() => _selectedImageIndex = index);
              },
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.maasga.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedImageIndex + 1}/${widget.product.images.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.maasga.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnails() {
    return SliverToBoxAdapter(
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(top: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.product.images.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedImageIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedImageIndex = index);
                _carouselController.animateToPage(index);
              },
              child: Container(
                width: 66,
                height: 66,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? context.maasga.accent
                        : const Color(0xFFE0E0E0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImageWidget(
                    widget.product.images[index],
                    BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    final isFavorite = ref.watch(favoritesProvider).contains(widget.product.id);
    final discount = widget.product.oldPrice != null
        ? (((widget.product.oldPrice! - widget.product.price) /
                      widget.product.oldPrice!) *
                  100)
              .round()
        : 0;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.maasga.textPrimary,
                        ),
                      ),
                      Text(
                        'Marque: ${widget.product.brand} · ${widget.product.category}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: context.maasga.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final wasFavorite = isFavorite;
                    ref
                        .read(favoritesProvider.notifier)
                        .toggle(widget.product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasFavorite
                              ? 'Retiré des favoris'
                              : 'Ajouté aux favoris',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? context.maasga.danger
                          : context.maasga.textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  PriceFormatter.format(widget.product.price),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.maasga.accent,
                  ),
                ),
                if (widget.product.oldPrice != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    PriceFormatter.format(widget.product.oldPrice!),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: context.maasga.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.maasga.successSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-$discount%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.maasga.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: context.maasga.divider),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalBrief() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FICHE TECHNIQUE',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: context.maasga.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: const [
                SpecCard(
                  icon: Icons.energy_savings_leaf_outlined,
                  value: 'A+++ / A++',
                  label: 'Classe Énergétique',
                ),
                SpecCard(
                  icon: Icons.volume_down_outlined,
                  value: '21 dB(A)',
                  label: 'Niveau Sonore',
                ),
                SpecCard(
                  icon: Icons.air_outlined,
                  value: 'HEPA H13',
                  label: 'Système Filtration',
                ),
                SpecCard(
                  icon: Icons.wifi_outlined,
                  value: 'Smart Link',
                  label: 'Connectivité App',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    final palette = context.maasga;
    final reviewsAsync = ref.watch(reviewsProvider(widget.product.id));
    final avg = ref.watch(averageRatingProvider(widget.product.id));
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: palette.divider),
            const SizedBox(height: 20),
            Text(
              'AVIS CLIENTS',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            reviewsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => Text(
                'Impossible de charger les avis',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: palette.textMuted,
                ),
              ),
              data: (reviews) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reviews.isNotEmpty) ...[
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: avg,
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: palette.warning,
                            ),
                            itemCount: 5,
                            itemSize: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${avg.toStringAsFixed(1)} (${reviews.length} avis)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...reviews.take(3).map(_buildReviewItem),
                      if (reviews.length > 3)
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Voir tous les avis (${reviews.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: palette.accent,
                            ),
                          ),
                        ),
                    ] else
                      Text(
                        'Aucun avis pour ce produit.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                    if (isLoggedIn) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showReviewBottomSheet,
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: Text(
                          'Laisser un avis',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.accent,
                          side: BorderSide(color: palette.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(ProductReview review) {
    final palette = context.maasga;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              RatingBarIndicator(
                rating: review.rating.toDouble(),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: palette.warning,
                ),
                itemCount: 5,
                itemSize: 14,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${review.createdAt.day.toString().padLeft(2, '0')}/'
            '${review.createdAt.month.toString().padLeft(2, '0')}/'
            '${review.createdAt.year}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSheetButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton(
          onPressed: _showFicheComplete,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.maasga.accent, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 54),
          ),
          child: Text(
            'DÉCOUVRIR LA FICHE COMPLÈTE',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: context.maasga.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: context.maasga.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.maasga.cardAlt,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildQtyBtn(
                    icon: Icons.remove,
                    isRemove: true,
                    onTap: _decrementQty,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildQtyBtn(
                    icon: Icons.add,
                    isRemove: false,
                    onTap: _incrementQty,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  'Ajouter au Panier',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.maasga.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required bool isRemove,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isRemove ? context.maasga.card : context.maasga.accent,
          shape: BoxShape.circle,
          border: isRemove
              ? Border.all(color: context.maasga.accent, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isRemove ? context.maasga.accent : Colors.white,
        ),
      ),
    );
  }
}
