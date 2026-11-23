import 'dart:convert';
import 'package:ecommerce_app/app_theme.dart';
import 'package:ecommerce_app/bkash_payment.dart';
import 'package:ecommerce_app/bloc/cart/cart_cubit.dart';
import 'package:ecommerce_app/bloc/product/product_bloc.dart';
import 'package:ecommerce_app/bloc/product/product_event.dart';
import 'package:ecommerce_app/config.dart';
import 'package:ecommerce_app/models/cart_item_model.dart';
import 'package:ecommerce_app/screens/order_confirmed_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String selectedPaymentMethod = 'bkash';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // লগইন করা ইউজারের নাম থাকলে অটোমেটিক বসিয়ে দেওয়া
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      nameController.text = user.displayName!;
    }
  }

  Future<dynamic> _placeOrder(List<CartItem> cart, {String? trxID}) async {
    const url = "${Config.apiBase}/Place_Order.php";
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      final items = cart.map((item) {
        return {
          'product_id': item.product.id,
          'variant_id': item.variant?.id,
          'quantity': item.quantity,
        };
      }).toList();

      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'name': nameController.text.trim(),
              'phone': phoneController.text.trim(),
              'address': addressController.text.trim(),
              'payment_method': selectedPaymentMethod,
              'trxID': trxID,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final result = jsonDecode(res.body);
      if (res.statusCode == 200 && result['ok'] == true) {
        return {'ok': true, 'order_id': result['order_id']};
      }
      return {
        'ok': false,
        'message': result['message'] ?? 'Failed to place order',
      };
    } catch (e) {
      return {'ok': false, 'message': 'Connection error: $e'};
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmPressed(List<CartItem> cart, double totalPrice) async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in your name, phone, and address"),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? trxID;
    if (selectedPaymentMethod == 'bkash') {
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BkashPaymentScreen(amount: totalPrice.toStringAsFixed(0)),
        ),
      );

      if (paymentResult == null || paymentResult['status'] != 'success') {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("bKash Payment Failed or Cancelled!"),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      trxID = paymentResult['trxID'];
    }

    final response = await _placeOrder(cart, trxID: trxID);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['ok'] == true) {
      // কার্ট খালি করা এবং হোম পেজের স্টক রিফ্রেশ করা
      context.read<CartCubit>().clearCart();
      context.read<ProductBloc>().add(LoadProduct());

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmedPage(
            orderId: int.tryParse('${response['order_id']}') ?? 0,
            totalAmount: totalPrice,
            paymentMethod: selectedPaymentMethod,
            trxId: trxID,
          ),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Order failed"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Checkout")),
      body: BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cart) {
          final totalPrice = context.read<CartCubit>().getTotalPrice();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. ডেলিভারি ঠিকানা কার্ড
                const Text(
                  "Delivery Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Delivery Address",
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ২. পেমেন্ট মেথড নির্বাচন
                const Text(
                  "Payment Method",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        activeColor: AppColors.primary,
                        title: const Text(
                          "bKash Payment",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text("Pay instantly via bKash"),
                        value: "bkash",
                        groupValue: selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => selectedPaymentMethod = value!);
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        activeColor: AppColors.primary,
                        title: const Text(
                          "Cash on Delivery (COD)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text("Pay when you receive the parcel"),
                        value: "cod",
                        groupValue: selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => selectedPaymentMethod = value!);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ৩. অর্ডার সামারি কার্ড
                const Text(
                  "Order Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ...cart.map((item) {
                        final variantInfo = item.variant != null
                            ? " (${item.variant!.size}${item.variant!.color.isNotEmpty ? ', ${item.variant!.color}' : ''})"
                            : "";
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item.product.name}$variantInfo × ${item.quantity}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                "৳${(item.unitPrice * item.quantity).toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Grand Total",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "৳${totalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cart) {
          if (cart.isEmpty) return const SizedBox.shrink();
          final totalPrice = context.read<CartCubit>().getTotalPrice();

          return Container(
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _onConfirmPressed(cart, totalPrice),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          selectedPaymentMethod == 'bkash'
                              ? "Pay ৳${totalPrice.toStringAsFixed(0)} with bKash"
                              : "Place Order (COD)",
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
