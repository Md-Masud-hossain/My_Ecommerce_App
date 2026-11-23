import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _placeholder(Icons.image_not_supported);
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ IMAGE FAILED TO LOAD: $path | Error: $error');
        return _placeholder(Icons.broken_image);
      },
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(icon, color: Colors.grey.shade400, size: 32),
      ),
    );
  }
}