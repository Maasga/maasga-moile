/// Modèle d'une marque retournée par /api/mobile/brands.
///
/// [assetKey] — clé locale Flutter : `assets/brands/<assetKey>.png`.
/// [logoUrl]  — URL distante (prioritaire sur [assetKey] si non nulle).
class Brand {
  Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.assetKey,
    required this.displayOrder,
  });

  final int id;
  final String name;
  final String? logoUrl;
  final String? assetKey;
  final int displayOrder;

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      assetKey: json['asset_key'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
