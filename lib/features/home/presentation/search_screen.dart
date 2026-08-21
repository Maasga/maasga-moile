import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/main_bottom_nav.dart';
import '../../cart/presentation/cart_state.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/product_list_card.dart';

/// Recherche plein texte dans le catalogue.
///
/// Le filtrage se fait en mémoire sur `productsProvider`, le même
/// FutureProvider que l'écran catalogue : arriver ici après avoir ouvert le
/// catalogue ne relance aucun appel réseau.
///
/// `/api/mobile/products` n'accepte pas de paramètre `?q=` : une recherche
/// côté serveur (utile quand le catalogue dépassera quelques centaines de
/// références) demande d'abord une évolution du worker.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const Color _primaryBlue = Color(0xFF1B3A8D);

  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value);

  void _applySuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    _setQuery(value);
  }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).add(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ajouté au panier'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: _primaryBlue,
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.push('/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: Column(
        children: [
          _SearchHeader(
            controller: _controller,
            hasQuery: _query.isNotEmpty,
            onChanged: _setQuery,
            onClear: () {
              _controller.clear();
              _setQuery('');
            },
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(),
              data: _buildResults,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentPath: '/search'),
    );
  }

  Widget _buildResults(List<Product> products) {
    final tokens = _tokenize(_query);
    if (tokens.isEmpty) return _buildSuggestions(products);

    final results = products
        .where((product) => _matches(product, tokens))
        .toList();
    if (results.isEmpty) return _buildNoResults();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              results.length == 1
                  ? '1 produit trouvé'
                  : '${results.length} produits trouvés',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          );
        }
        final product = results[index - 1];
        return ProductListCard(
          product: product,
          onTap: () => context.push('/catalog/product', extra: product),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  /// Écran d'accueil de la recherche : marques et catégories réellement
  /// présentes dans le catalogue chargé (aucune suggestion inventée).
  Widget _buildSuggestions(List<Product> products) {
    final brands = _distinctValues(products.map((p) => p.brand));
    final categories = _distinctValues(products.map((p) => p.category));

    if (brands.isEmpty && categories.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.search,
        title: 'Rechercher un produit',
        message: 'Tapez un modèle, une marque ou une puissance.',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (categories.isNotEmpty) ...[
          _buildSuggestionTitle('Catégories'),
          _buildSuggestionChips(categories),
          const SizedBox(height: 20),
        ],
        if (brands.isNotEmpty) ...[
          _buildSuggestionTitle('Marques'),
          _buildSuggestionChips(brands),
        ],
      ],
    );
  }

  Widget _buildSuggestionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(List<String> values) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ActionChip(
              label: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => _applySuggestion(value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNoResults() {
    return _buildPlaceholder(
      icon: Icons.search_off,
      title: 'Aucun résultat',
      message: 'Aucun produit ne correspond à « $_query ».',
      action: TextButton(
        onPressed: () => context.go('/catalog'),
        child: const Text('Voir tout le catalogue'),
      ),
    );
  }

  Widget _buildError() {
    return _buildPlaceholder(
      icon: Icons.wifi_off,
      title: 'Catalogue indisponible',
      message: 'Vérifiez votre connexion puis réessayez.',
      action: TextButton(
        onPressed: () => ref.invalidate(productsProvider),
        child: const Text('Réessayer'),
      ),
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF757575),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            // La recherche est un détour : si la pile est vide (arrivée par
            // notification), on retombe sur l'accueil au lieu de bloquer.
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(Icons.arrow_back, size: 20),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Climatiseur, marque, puissance...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: hasQuery
                    ? IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Effacer',
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _distinctValues(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) unique.add(trimmed);
  }
  final result = unique.toList();
  result.sort();
  return result;
}

List<String> _tokenize(String query) {
  return _fold(
    query,
  ).split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
}

bool _matches(Product product, List<String> tokens) {
  final haystack = _fold(
    [
      product.name,
      product.brand,
      product.category,
      product.power,
      if (product.btu != null) '${product.btu} btu',
      ...product.specs,
    ].join(' '),
  );
  return tokens.every(haystack.contains);
}

const String _accented = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
const String _unaccented = 'aaaaaaeeeeiiiiooooouuuucn';

/// Minuscules sans accents : « Économie » et « economie » doivent matcher la
/// même saisie — un utilisateur ne tape pas les accents sur un clavier mobile.
String _fold(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = _accented.indexOf(char);
    buffer.write(index == -1 ? char : _unaccented[index]);
  }
  return buffer.toString();
}
