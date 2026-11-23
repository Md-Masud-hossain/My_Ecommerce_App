import 'package:ecommerce_app/app_theme.dart';
import 'package:ecommerce_app/bloc/cart/cart_cubit.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/screens/cart_page.dart';
import 'package:ecommerce_app/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ProductRepository _repo = ProductRepository();
  final PageController _imagePageController = PageController();

  late Product _product;
  bool _isLoadingDetails = true;
  int _currentImageIndex = 0;

  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initDefaults();
    _fetchFullProductDetails();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // get_product.php থেকে পণ্যের সব ছবি (gallery) ও ভ্যারিয়েন্ট (size/color) নিয়ে আসা
  Future<void> _fetchFullProductDetails() async {
    try {
      final fullProduct = await _repo.getProduct(_product.id);
      if (!mounted) return;
      setState(() {
        _product = fullProduct;
        _isLoadingDetails = false;
        _initDefaults();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
    }
  }

  void _initDefaults() {
    if (_product.variants.isNotEmpty) {
      // স্টকে আছে এমন প্রথম ভ্যারিয়েন্ট ডিফল্ট হিসেবে বাছা
      final firstInStock = _product.variants.firstWhere(
        (v) => v.stock > 0,
        orElse: () => _product.variants.first,
      );
      _selectedSize = firstInStock.size.isNotEmpty ? firstInStock.size : null;
      _selectedColor = firstInStock.color.isNotEmpty ? firstInStock.color : null;
      _quantity = firstInStock.stock > 0 ? 1 : 0;
    } else {
      _quantity = _product.inStock ? 1 : 0;
    }
  }

  List<String> get _galleryImages {
    if (_product.images.isNotEmpty) return _product.images;
    if (_product.image != null && _product.image!.isNotEmpty) {
      return [_product.image!];
    }
    return [];
  }

  List<String> get _availableSizes {
    return _product.variants
        .map((v) => v.size)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> get _availableColors {
    return _product.variants
        .map((v) => v.color)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  Variant? get _selectedVariant {
    if (_product.variants.isEmpty) return null;
    try {
      return _product.variants.firstWhere(
        (v) =>
            (_selectedSize == null || v.size == _selectedSize) &&
            (_selectedColor == null || v.color == _selectedColor),
      );
    } catch (_) {
      return _product.variants.first;
    }
  }

  int get _currentStock {
    if (_product.variants.isEmpty) return _product.inStock ? 99 : 0;
    return _selectedVariant?.stock ?? 0;
  }

  double get _displayPrice {
    return _product.price + (_selectedVariant?.extraPrice ?? 0);
  }

  void _handleAddToCart({bool goToCart = false}) {
    if (_currentStock <= 0 || _quantity <= 0) return;

    context.read<CartCubit>().addToCart(
          _product,
          variant: _selectedVariant,
          quantity: _quantity,
        );

    if (goToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_product.name} added to cart"),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _galleryImages;
    final sizes = _availableSizes;
    final colors = _availableColors;
    final stock = _currentStock;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ১. ছবির গ্যালারি (Image Gallery)
                  Container(
                    height: 330,
                    width: double.infinity,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        images.isEmpty
                            ? const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 64, color: Colors.grey),
                              )
                            : PageView.builder(
                                controller: _imagePageController,
                                itemCount: images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return ProductImage(
                                    path: images[index],
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                final active = _currentImageIndex == i;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  height: 7,
                                  width: active ? 22 : 7,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // থাম্বনেইল বার (একাধিক ছবি থাকলে)
                  if (images.length > 1)
                    Container(
                      height: 68,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final active = _currentImageIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _imagePageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ProductImage(
                                    path: images[index], fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ২. পণ্যের নাম, দাম, স্টক ও বিবরণ কার্ড
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Stock Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_product.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _product.category,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: stock > 0
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stock > 0
                                    ? (_product.variants.isEmpty
                                        ? "In Stock"
                                        : "In Stock ($stock left)")
                                    : "Out of Stock",
                                style: TextStyle(
                                  color: stock > 0
                                      ? Colors.green.shade700
                                      : AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Product Name
                        Text(
                          _product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_product.brand.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Brand: ${_product.brand}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Dynamic Price
                        Text(
                          "৳${_displayPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),

                        if (_isLoadingDetails)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            ),
                          ),

                        // ৩. সাইজ বাছা (Size Selection)
                        if (sizes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Select Size",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: sizes.map((size) {
                              final isSelected = _selectedSize == size;
                              return ChoiceChip(
                                label: Text(size),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSize = size;
                                    _quantity = _currentStock > 0 ? 1 : 0;
                                  });
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.background,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // ৪. রঙ বাছা (Color Selection)
                        if (colors.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Select Color",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: colors.map((color) {
                              final isSelected = _selectedColor == color;
                              return ChoiceChip(
                                label: Text(color),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedColor = color;
                                    _quantity = _currentStock > 0 ? 1 : 0;
                                  });
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.background,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // ৫. পরিমাণ বাড়ানো-কমানো (Quantity)
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Text(
                              "Quantity",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    icon: const Icon(Icons.remove, size: 18),
                                    color: AppColors.primary,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      "$_quantity",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _quantity < stock
                                        ? () => setState(() => _quantity++)
                                        : null,
                                    icon: const Icon(Icons.add, size: 18),
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ৬. পণ্যের বিবরণ (Description)
                        if (_product.description.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // নিচের ফিক্সড বাটন বার (Add to Cart & Buy Now)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: stock > 0
                          ? () => _handleAddToCart(goToCart: false)
                          : null,
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          size: 20),
                      label: const Text("Add to Cart"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: stock > 0
                          ? () => _handleAddToCart(goToCart: true)
                          : null,
                      icon: const Icon(Icons.flash_on_rounded, size: 20),
                      label: const Text("Buy Now"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}