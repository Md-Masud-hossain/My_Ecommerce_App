// One size/color option of a product, with its own stock.
class Variant {
  final int id;
  final String size;
  final String color;
  final String? colorHex;
  final double extraPrice;
  final int stock;

  const Variant({
    required this.id,
    required this.size,
    required this.color,
    this.colorHex,
    required this.extraPrice,
    required this.stock,
  });

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: int.tryParse('${j['id']}') ?? 0,
        size: (j['size'] ?? '').toString(),
        color: (j['color'] ?? '').toString(),
        colorHex: j['color_hex']?.toString(),
        extraPrice: double.tryParse('${j['extra_price']}') ?? 0,
        stock: int.tryParse('${j['stock']}') ?? 0,
      );
}

class Product {
  // The first four positional parameters are unchanged, so existing code
  // such as Product("Shirt", 500, "path", "Category") keeps working.
  final String name;
  final int price; // whole taka, kept as int for the existing cart code
  final String image; // cover image URL, or '' when there is none
  final String category;

  // New optional fields (filled from the API).
  final int id;
  final String brand;
  final String description;
  final double priceExact; // exact price, may have decimals
  final List<String> images;
  final List<Variant> variants;
  final bool inStock;

  Product(
    this.name,
    this.price,
    this.image,
    this.category, {
    this.id = 0,
    this.brand = '',
    this.description = '',
    double? priceExact,
    this.images = const [],
    this.variants = const [],
    this.inStock = true,
  }) : priceExact = priceExact ?? price.toDouble();

  factory Product.fromJson(Map<String, dynamic> j) {
    final images =
        ((j['images'] as List?) ?? []).map((e) => e.toString()).toList();
    final variants = ((j['variants'] as List?) ?? [])
        .map((e) => Variant.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final exact = double.tryParse('${j['price']}') ?? 0;
    final cover =
        j['image']?.toString() ?? (images.isNotEmpty ? images.first : '');

    return Product(
      (j['name'] ?? '').toString(),
      exact.round(),
      cover,
      (j['category'] ?? '').toString(),
      id: int.tryParse('${j['id']}') ?? 0,
      brand: (j['brand'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      priceExact: exact,
      images: images,
      variants: variants,
      inStock: j.containsKey('in_stock')
          ? j['in_stock'] == true
          : variants.any((v) => v.stock > 0),
    );
  }
}
