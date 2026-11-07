import 'package:ecommerce_app/bloc/cart/cart_cubit.dart';
import 'package:ecommerce_app/models/cart_item_model.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/screens/checkout_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart")),
      body: BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return Center(child: Text("Cart is Empty"));
          }
          return ListView.builder(
            itemCount: cart.length,
            itemBuilder: (context, index) {
              final item = cart[index];
              return ListTile(
                title: Text(item.product.name),
                subtitle: Text("Quantity: ${item.quantity}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<CartCubit>().decreaseQuantity(
                          item.product.name,
                        );
                      },
                      icon: Icon(Icons.remove),
                    ),

                    IconButton(
                      onPressed: () {
                        context.read<CartCubit>().increaseQuantity(
                          item.product.name,
                        );
                      },
                      icon: Icon(Icons.add),
                    ),

                    IconButton(
                      onPressed: () {
                        context.read<CartCubit>().removeFromCart(
                          item.product.name,
                        );
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cart) {
          final total = context.read<CartCubit>().getTotalPrice();
          return Padding(
            padding: EdgeInsets.all(16),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Total:৳$total",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CheckoutPage()),
                      );
                    },
                    child: Text("Proceed to Checkout"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
