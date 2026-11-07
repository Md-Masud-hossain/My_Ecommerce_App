import 'package:ecommerce_app/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductDetailsPage extends StatelessWidget {
  // const ProductDetailsPage({super.key});
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product Details")),

      body: Column(
        children: [
          Image.asset(product.image),
          Text(product.name),
          Text(product.category),
          Text("${product.price}"),
        ],
      ),
    );
  }
}
