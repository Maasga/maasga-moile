import 'dart:convert';

class Product {
  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.stock,
    this.category = 'Mural/Split',
    this.power = '1cv',
    this.specs = const <String>[],
    this.image = '',
    this.imageUrl,
    this.btu,
    this.images = const [],
    this.oldPrice,
    this.description = '',
    this.technicalSpecs = const {},
  });

  final int id;
  final String name;
  final String brand;
  final int price;
  final int stock;
  final String category;
  final String power;
  final List<String> specs;
  final String image;
  final String? imageUrl;
  final int? btu;

  // New fields for premium detail page
  final List<String> images;
  final int? oldPrice;
  final String description;
  final Map<String, String> technicalSpecs;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'stock': stock,
      'category': category,
      'power': power,
      'specs': specs,
      'image': image,
      'imageUrl': imageUrl,
      'btu': btu,
      'images': images,
      'old_price': oldPrice,
      'description': description,
      'techSpecs': technicalSpecs,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'Mural/Split',
      power: json['power'] as String? ?? '1cv',
      // Aucune valeur de repli inventée : afficher « Classe A+++ » ou
      // « 12000 BTU » sur un produit dont le serveur ne dit rien est un
      // argument commercial faux. Une liste vide laisse l'UI masquer la
      // section.
      specs: _parseListField(json['features'] ?? json['specs']),
      image: json['image'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      btu: (json['btu'] as num?)?.toInt(),
      images: _parseImagesField(
        json['media_urls'] as String? ??
            json['media'] as List<dynamic>? ??
            json['images'] as List<dynamic>?,
      ),
      oldPrice: (json['old_price'] as num?)?.toInt(),
      description: json['description'] as String? ?? '',
      technicalSpecs:
          (json['techSpecs'] as Map<String, dynamic>? ??
                  json['technical_specs'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, '$v')) ??
          {},
    );
  }

  /// Parse un champ qui peut être une chaîne JSON ou une liste directe
  static List<String> _parseListField(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
    }

    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((e) => '$e')
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return [value].where((e) => e.trim().isNotEmpty).toList();
    }

    return [];
  }

  /// Parse le champ images qui peut être une chaîne JSON, une liste de maps, ou une liste de strings
  static List<String> _parseImagesField(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) {
            if (e is Map) return e['url']?.toString() ?? '';
            return '$e';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((e) {
                if (e is Map) return e['url']?.toString() ?? '';
                return '$e';
              })
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return [value].where((s) => s.isNotEmpty).toList();
    }

    return [];
  }
}
