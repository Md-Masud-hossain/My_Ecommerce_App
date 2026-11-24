import 'dart:async';
import 'dart:convert';
import 'package:ecommerce_app/app_theme.dart';
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
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String selectedPaymentMethod = 'sslcommerz';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      nameController.text = user.displayName!;
    }
  }

  /// ধাপ ১: SSLCommerz পেমেন্ট সেশন তৈরি ও গেটওয়ে ওপেন করা
  Future<String?> _startSslCommerzPayment(double totalPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final res = await http
          .post(
            Uri.parse('${Config.apiBase}/ssl_create_payment.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': totalPrice,
              'cus_name': nameController.text.trim(),
              'cus_email': user?.email ?? 'customer@zeynep.com',
              'cus_phone': phoneController.text.trim(),
              'cus_add1': addressController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 &&
          data['status'] == 'success' &&
          data['gatewayURL'] != null) {
        final String gatewayUrl = data['gatewayURL'];
        final String tranId = data['tran_id'];

        // নতুন ট্যাবে SSLCommerz গেটওয়ে ওপেন করা
        final uri = Uri.parse(gatewayUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!mounted) return null;

        // ইউজার পেমেন্ট শেষ করে ফিরে এলে ভেরিফাই করার ডায়ালগ
        final bool? verified = await _showVerifyDialog(tranId);
        if (verified == true) {
          return tranId;
        }
        return null;
      } else {
        throw Exception(data['message'] ?? 'Could not initialize payment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return null;
    }
  }

  /// পেমেন্ট ভেরিফিকেশন ডায়ালগ
  /// পেমেন্ট ভেরিফিকেশন ডায়ালগ (অটোমেটিক + ম্যানুয়াল চেক)
  Future<bool?> _showVerifyDialog(String tranId) {
    bool isVerifying = false;
    String? verifyError;
    Timer? autoCheckTimer;
    bool dialogClosed = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // প্রতি ৩ সেকেন্ড পরপর অটোমেটিক চেক করবে পেমেন্ট Paid হয়েছে কিনা
            autoCheckTimer ??= Timer.periodic(const Duration(seconds: 3), (
              timer,
            ) async {
              if (dialogClosed) {
                timer.cancel();
                return;
              }
              try {
                final res = await http
                    .post(
                      Uri.parse('${Config.apiBase}/ssl_verify.php'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'tran_id': tranId}),
                    )
                    .timeout(const Duration(seconds: 10));

                final data = jsonDecode(res.body);
                if (res.statusCode == 200 && data['ok'] == true) {
                  timer.cancel();
                  if (!dialogClosed && ctx.mounted) {
                    dialogClosed = true;
                    Navigator.pop(ctx, true);
                  }
                }
              } catch (_) {}
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Waiting for Payment...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete your payment in the opened browser tab and click "Back to Home Page". This screen will confirm automatically.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TXN ID: $tranId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (verifyError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      verifyError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          dialogClosed = true;
                          autoCheckTimer?.cancel();
                          Navigator.pop(ctx, false);
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          setDialogState(() {
                            isVerifying = true;
                            verifyError = null;
                          });

                          try {
                            final res = await http
                                .post(
                                  Uri.parse('${Config.apiBase}/ssl_verify.php'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({'tran_id': tranId}),
                                )
                                .timeout(const Duration(seconds: 15));

                            final data = jsonDecode(res.body);
                            if (res.statusCode == 200 && data['ok'] == true) {
                              dialogClosed = true;
                              autoCheckTimer?.cancel();
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } else {
                              setDialogState(() {
                                isVerifying = false;
                                verifyError =
                                    data['message'] ??
                                    'Payment not confirmed yet.';
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              isVerifying = false;
                              verifyError = 'Verification error: $e';
                            });
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ধাপ ২: ডাটাবেসে অর্ডার সেভ করা
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
    if (selectedPaymentMethod == 'sslcommerz') {
      trxID = await _startSslCommerzPayment(totalPrice);
      if (trxID == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        return;
      }
    }

    final response = await _placeOrder(cart, trxID: trxID);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['ok'] == true) {
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
                          "Online Payment",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          "Pay via bKash, Nagad, Rocket, Visa/Mastercard",
                        ),
                        value: "sslcommerz",
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
                          selectedPaymentMethod == 'sslcommerz'
                              ? "Pay ৳${totalPrice.toStringAsFixed(0)} Online"
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
