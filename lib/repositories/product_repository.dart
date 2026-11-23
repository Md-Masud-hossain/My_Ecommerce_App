import 'dart:convert';

import 'package:ecommerce_app/config.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:http/http.dart' as http;

class ProductRepository {
  // Same method name as before, so ProductBloc needs no changes.
  Future<List<Product>> getProducts({
    String query = '',
    int? categoryId,
  }) async {
    final params = <String, String>{
      if (query.isNotEmpty) 'q': query,
      if (categoryId != null) 'category_id': '$categoryId',
    };

    var uri = Uri.parse('${Config.apiBase}/get_products.php');
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Could not load products');
    }

    return (data['products'] as List)
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Full details (all images and variants) for the details page.
  Future<Product> getProduct(int id) async {
    final uri = Uri.parse('${Config.apiBase}/get_product.php?id=$id');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Could not load product');
    }
    return Product.fromJson(Map<String, dynamic>.from(data['product']));
  }
}
