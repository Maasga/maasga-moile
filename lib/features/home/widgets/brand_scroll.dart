import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../data/home_repository.dart';
import '../models/brand.dart';

/// Barre de défilement horizontal des marques de l'accueil.
///
/// Affiche les marques depuis [brandsProvider] (API `/api/mobile/brands`).
/// En cas d'erreur réseau, bascule sur les assets locaux de [_fallbackAssets].
/// Chaque marque utilise [Brand.logoUrl] si disponible, sinon
/// `assets/brands/<assetKey>.png` comme fallback.
class BrandScroll extends ConsumerWidget {
  const BrandScroll({super.key});

  /// Assets locaux de repli — correspondent aux 5 marques du seed D1.
  static const Map<String, String> _fallbackAssets = {
    'DAIKIN': 'assets/brands/daikin.png',
    'MITSUBISHI': 'assets/brands/mitsubishi.png',
    'PANASONIC': 'assets/brands/panasonic.png',
    'TOSHIBA': 'assets/brands/toshiba.png',
    'AERO': 'assets/brands/aero.png',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return brandsAsync.when(
      data: (brands) {
        if (brands.isEmpty) return _buildList(_fallbackBrands());
        return _buildList(brands);
      },
      loading: () => _buildList(_fallbackBrands()),
      error: (_, _) => _buildList(_fallbackBrands()),
    );
  }

  List<Brand> _fallbackBrands() {
    return _fallbackAssets.entries
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => Brand(
            id: entry.key,
            name: entry.value.key,
            assetKey: entry.value.key.toLowerCase(),
            displayOrder: entry.key,
          ),
        )
        .toList();
  }

  Widget _buildList(List<Brand> brands) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            constraints: const BoxConstraints(maxWidth: 90),
            child: _BrandItem(brand: brand),
          );
        },
      ),
    );
  }
}

class _BrandItem extends StatelessWidget {
  const _BrandItem({required this.brand});
  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final textMuted = context.maasga.textMuted;

    Widget logoWidget;

    // Priorité 1 : URL distante
    if (brand.logoUrl != null && brand.logoUrl!.isNotEmpty) {
      logoWidget = CachedNetworkImage(
        imageUrl: brand.logoUrl!,
        height: 28,
        width: 90,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) => _localAssetImage(brand),
      );
    } else {
      // Priorité 2 : asset local
      logoWidget = _localAssetImage(brand);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(height: 2),
        Text(
          brand.name,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _localAssetImage(Brand brand) {
    final assetKey =
        brand.assetKey?.toLowerCase() ??
        brand.name.toLowerCase().replaceAll(' ', '_');
    final path = 'assets/brands/$assetKey.png';
    return Image.asset(
      path,
      height: 28,
      width: 90,
      fit: BoxFit.contain,
      errorBuilder: (context, _, _) => SizedBox(
        height: 28,
        width: 90,
        child: Center(
          child: Text(
            brand.name,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: context.maasga.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
