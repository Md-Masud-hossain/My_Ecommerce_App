import 'dart:convert';

import 'package:ecommerce_app/bkash_payment%20(1).dart';
import 'package:ecommerce_app/config.dart';
import 'package:ecommerce_app/models/Order_Model.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/bloc/cart/cart_cubit.dart';
import 'package:ecommerce_app/models/cart_item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // dispose er kaj holo ,controller use sese segulo clean korbe
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String selectedPaymentMethod = 'bkash';

  Future<bool> add(List<CartItem> cart, {String? trxID}) async {
    const url = "http://localhost/ecommerce_api/Place_Order.php";

    try {
      final items = cart.map((item) {
        return {
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.product.price,
        };
      }).toList();

      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'payment_method': selectedPaymentMethod,
          'trxID': trxID,
          'items': items,
        }),
      );

      print("Status Code: ${res.statusCode}");
      print("Response Body: ${res.body}");

      final result = jsonDecode(res.body);

      if (res.statusCode == 200 && result['ok'] == true) {
        print("Order ID: ${result['order_id']}");
        return true;
      }

      print("Order failed: ${result['message']}");
      return false;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cart) {
          final totalPrice = context.read<CartCubit>().getTotalPrice();
          return Column(
            children: [
              Text("Order Summary"),
              Padding(
                padding: EdgeInsets.all(12),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Customer Name",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Customer Number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Customer Address",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // Gmini
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Payment Method:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              RadioListTile<String>(
                title: const Text("bKash Payment"),
                value: "bkash",
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Cash on Delivery"),
                value: "cod",
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),

              // Gmini
              Expanded(
                child: ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text("Quantity:${item.quantity}"),
                      trailing: Text("৳${item.product.price * item.quantity}"),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Grand Total:৳${context.read<CartCubit>().getTotalPrice()}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
                          phoneController.text.trim().isEmpty ||
                          addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all fields"),
                          ),
                        );
                        return;
                      }
                      // gmini
                      if (selectedPaymentMethod == 'bkash') {
                        final paymentResult = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BkashPaymentScreen(
                              amount: totalPrice.toString(),
                            ),
                          ),
                        );

                        // gmini
                        if (paymentResult != null &&
                            paymentResult['status'] == 'success') {
                          final success = await add(
                            cart,
                            trxID: paymentResult['trxID'],
                          );

                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "bKash Order Placed Successfully!",
                                ),
                              ),
                            );

                            // gmini
                          }
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "bKash Payment Failed or Cancelled!",
                              ),
                            ),
                          );
                        }
                      } else {
                        final success = await add(cart);

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "Order created successfully"
                                  : "Order failed! Check console",
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      selectedPaymentMethod == 'bkash'
                          ? "Pay with bKash"
                          : "Place Order (COD)",
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
