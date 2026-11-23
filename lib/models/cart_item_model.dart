import 'package:ecommerce_app/models/product_model.dart';

class CartItem {
  final Product product;
  final Variant? variant;
  int quantity;

  CartItem(this.product, this.quantity, {this.variant});

  // মূল দামের সাথে ভ্যারিয়েন্টের অতিরিক্ত দাম (যদি থাকে) যোগ করে একক দাম
  double get unitPrice => product.price + (variant?.extraPrice ?? 0);

  // এই আইটেমের সর্বোচ্চ স্টক কত আছে
  int get maxStock => variant?.stock ?? 99;

  // কার্টে ইউনিকভাবে চেনার জন্য Key (যাতে M-Black আর L-Black আলাদা থাকে)
  String get uniqueKey =>
      variant != null ? 'v_${variant!.id}' : 'p_${product.id}';
}