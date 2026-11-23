import 'package:ecommerce_app/models/cart_item_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartCubit extends Cubit<List<CartItem>> {
  CartCubit() : super([]);

  void addToCart(Product product, {Variant? variant, int quantity = 1}) {
    final String key =
        variant != null ? 'v_${variant.id}' : 'p_${product.id}';
    final int maxStock = variant?.stock ?? 99;

    final int index = state.indexWhere((item) => item.uniqueKey == key);
    final List<CartItem> updatedCart = [...state];

    if (index == -1) {
      final int safeQty = quantity > maxStock ? maxStock : quantity;
      if (safeQty > 0) {
        updatedCart.add(CartItem(product, safeQty, variant: variant));
      }
    } else {
      final int newQty = updatedCart[index].quantity + quantity;
      updatedCart[index].quantity = newQty > maxStock ? maxStock : newQty;
    }
    emit(updatedCart);
  }

  void increaseQuantity(String uniqueKey) {
    final int index = state.indexWhere((item) => item.uniqueKey == uniqueKey);
    final List<CartItem> updatedCart = [...state];

    if (index != -1) {
      if (updatedCart[index].quantity < updatedCart[index].maxStock) {
        updatedCart[index].quantity += 1;
        emit(updatedCart);
      }
    }
  }

  void decreaseQuantity(String uniqueKey) {
    final int index = state.indexWhere((item) => item.uniqueKey == uniqueKey);
    final List<CartItem> updatedCart = [...state];

    if (index != -1) {
      if (updatedCart[index].quantity > 1) {
        updatedCart[index].quantity -= 1;
      } else {
        updatedCart.removeAt(index);
      }
      emit(updatedCart);
    }
  }

  void removeFromCart(String uniqueKey) {
    final List<CartItem> updatedCart = [...state];
    updatedCart.removeWhere((item) => item.uniqueKey == uniqueKey);
    emit(updatedCart);
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in state) {
      total += item.unitPrice * item.quantity;
    }
    return total;
  }

  void clearCart() {
    emit([]);
  }
}