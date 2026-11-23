import 'package:ecommerce_app/app_theme.dart';
import 'package:ecommerce_app/main.dart';
import 'package:flutter/material.dart';

class OrderConfirmedPage extends StatelessWidget {
  final int orderId;
  final double totalAmount;
  final String paymentMethod;
  final String? trxId;

  const OrderConfirmedPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    this.trxId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // সাকসেস আইকন
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 84,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Order Confirmed!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Thank you for shopping with Zeynep.\nYour order has been received and is being processed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // অর্ডার রসিদ কার্ড
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRow("Order ID", "#$orderId", isBold: true),
                    const Divider(height: 22),
                    _buildRow(
                      "Total Paid / Payable",
                      "৳${totalAmount.toStringAsFixed(0)}",
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                    const Divider(height: 22),
                    _buildRow(
                      "Payment Method",
                      paymentMethod == 'bkash' ? "bKash" : "Cash on Delivery",
                    ),
                    if (trxId != null && trxId!.isNotEmpty) ...[
                      const Divider(height: 22),
                      _buildRow("Transaction ID", trxId!),
                    ],
                  ],
                ),
              ),
              const Spacer(),

              // হোম পেজে ফেরার বাটন
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text("Continue Shopping"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color valueColor = AppColors.textDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}