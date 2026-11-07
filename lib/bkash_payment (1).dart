import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BkashPaymentScreen extends StatefulWidget {
  final String amount;

  const BkashPaymentScreen({super.key, required this.amount});

  @override
  State<BkashPaymentScreen> createState() => _BkashPaymentScreenState();
}

class _BkashPaymentScreenState extends State<BkashPaymentScreen> {
  static const String baseUrl = 'http://localhost/ecommerce_api';

  bool isLoading = true;
  bool isVerifying = false;
  String message = 'Creating bKash payment...';

  String? paymentID;
  String? bkashUrl;

  Timer? _timer;
  bool _finished = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- 1. Create the payment ----------
  Future<void> _startPayment() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': widget.amount}),
      );

      debugPrint('Create payment status: ${response.statusCode}');
      debugPrint('Create payment response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['bkashURL'] != null &&
          data['paymentID'] != null) {
        paymentID = data['paymentID'].toString();
        bkashUrl = data['bkashURL'].toString();

        if (!mounted) return;
        setState(() {
          isLoading = false;
          message =
              'Complete the payment on the bKash page.\nThis screen will continue automatically once the payment is confirmed.';
        });

        _openBkash();
        _startPolling();
      } else {
        throw Exception(
          data is Map
              ? (data['message'] ?? 'Could not create payment URL')
              : 'Invalid backend response',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        message = 'Could not start payment: $e';
      });
    }
  }

  void _openBkash() {
    if (bkashUrl != null) {
      html.window.open(bkashUrl!, '_blank');
    }
  }

  // ---------- 2. Check the payment status every 3 seconds ----------
  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_finished || paymentID == null) return;

      _attempts++;
      if (_attempts > 100) {
        _timer?.cancel();
        if (mounted) {
          setState(() => message =
              'Timed out. If you have paid, tap "I have paid, verify" below.');
        }
        return;
      }

      try {
        final res = await http.post(
          Uri.parse('$baseUrl/check_payment.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'paymentID': paymentID}),
        );
        final data = jsonDecode(res.body);

        if (data is Map && data['payment_status'] == 'Paid') {
          _finish({
            'status': 'success',
            'paymentID': paymentID,
            'trxID': data['trxID'],
          });
        } else if (data is Map &&
            (data['payment_status'] == 'Cancelled' ||
                data['payment_status'] == 'Failed')) {
          _finish({'status': 'cancelled'});
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  // ---------- 3. Manual verification (works without the callback) ----------
  Future<void> _verifyNow() async {
    if (paymentID == null) return;

    setState(() => isVerifying = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/Execute_Payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentID': paymentID}),
      );

      debugPrint('Execute response: ${res.body}');
      final data = jsonDecode(res.body);

      if (data is Map && data['status'] == 'success') {
        _finish({
          'status': 'success',
          'paymentID': paymentID,
          'trxID': data['trxID'],
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        isVerifying = false;
        message = 'Payment not confirmed: '
            '${data is Map ? (data['message'] ?? 'Please try again') : 'Please try again'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isVerifying = false;
        message = 'Could not verify: $e';
      });
    }
  }

  void _finish(Map<String, dynamic> result) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final started = paymentID != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('bKash Payment'),
        backgroundColor: Colors.pink,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading || isVerifying)
                const CircularProgressIndicator(color: Colors.pink),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (started)
                ElevatedButton(
                  onPressed: isVerifying ? null : _verifyNow,
                  child: const Text('I have paid, verify'),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  _finished = true;
                  _timer?.cancel();
                  Navigator.pop(context, {'status': 'cancelled'});
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
