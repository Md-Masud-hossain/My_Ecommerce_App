import 'package:ecommerce_app/models/product_model.dart';

class ProductRepository {
  Future<List<Product>> getProducts() async {
    return [
      Product("Half Slim T-Shirt", 500, "assets/images/t-shirt.jpg", "Zeynep"),
      Product("Running Shoes", 1500, "assets/images/shoes.jpg", "Lotto"),

      Product("Rolex Watch", 1800, "assets/images/watch.jpg", "Rolex"),

      Product("Joyroom Airbuds", 3100, "assets/images/airbuds.jpg", "Joyroom"),

      Product(
        "Custom fit shirt",
        999,
        "assets/images/Custom-fit shirt.jpg",
        "Zeynep",
      ),

      Product(
        "Formal check shirt",
        998,
        "assets/images/Formal Check Shirt.jpg",
        "Zeynep",
      ),

      Product(
        "Mens green solid slim fit shirt",
        1250,
        "assets/images/Mens green solid slim fit.jpg",
        "Zeynep",
      ),

      Product("Formal shirt", 1199, "assets/images/formal_shirt.jpg", "Zeynep"),
    ];
  }
}
