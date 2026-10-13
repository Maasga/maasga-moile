import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/asset_utils.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
  });

  final String? imageUrl;
  final String? imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = _buildImage();
    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    return SizedBox(width: width, height: height, child: image);
  }

  Widget _buildImage() {
    final url = imageUrl ?? '';

    // 1. Empty / invalid URL
    if (url.isEmpty || url == '??') {
      if (imagePath != null && imagePath!.isNotEmpty) {
        return Image.asset(
          AssetUtils.getAssetPath(imagePath!),
          fit: fit,
          errorBuilder: (_, _, _) =>
              Image.asset('assets/products/product_placeholder.png', fit: fit),
        );
      }
      return Image.asset('assets/products/product_placeholder.png', fit: fit);
    }

    // 2. Base64 data URI
    if (url.trim().startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          errorBuilder: (_, _, _) =>
              Image.asset('assets/products/product_placeholder.png', fit: fit),
        );
      } catch (_) {
        return Image.asset('assets/products/product_placeholder.png', fit: fit);
      }
    }

    // 3. HTTP URL
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) =>
            Image.asset('assets/products/product_placeholder.png', fit: fit),
      );
    }

    // 4. Local asset
    return Image.asset(
      AssetUtils.getAssetPath(url),
      fit: fit,
      errorBuilder: (_, _, _) =>
          Image.asset('assets/products/product_placeholder.png', fit: fit),
    );
  }
}
