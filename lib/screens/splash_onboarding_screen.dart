import 'package:ecommerce_app/app_theme.dart';
import 'package:ecommerce_app/main.dart';
import 'package:ecommerce_app/screens/auth_screen.dart';
import 'package:ecommerce_app/screens/auth_service.dart';
import 'package:flutter/material.dart';

class SplashOnboardingScreen extends StatefulWidget {
  const SplashOnboardingScreen({super.key});

  @override
  State<SplashOnboardingScreen> createState() => _SplashOnboardingScreenState();
}

class _SplashOnboardingScreenState extends State<SplashOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthGate(child: HomePage()),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkOrGradient = _currentPage == 0 || _currentPage == 2;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildFirstPage(),
              _buildSecondPage(),
              _buildThirdPage(),
            ],
          ),

          // ওপরের ডানদিকে Skip বাটন (শেষ পেজ বাদে)
          if (_currentPage < 2)
            Positioned(
              top: 44,
              right: 20,
              child: TextButton(
                onPressed: _goToApp,
                style: TextButton.styleFrom(
                  backgroundColor: isDarkOrGradient
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: isDarkOrGradient ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          // নিচের পেজ ইন্ডিকেটর ডট ও Next / Get Started বাটন
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Dots
                Row(
                  children: List.generate(3, (index) {
                    final bool active = _currentPage == index;
                    Color activeColor = Colors.white;
                    Color inactiveColor = Colors.white.withValues(alpha: 0.35);

                    if (_currentPage == 0) {
                      activeColor = const Color(
                        0xFFD4AF37,
                      ); // ১ম পেজে গোল্ডেন ডট
                    } else if (_currentPage == 1) {
                      activeColor = AppColors.primary; // ২য় পেজে রোজ-পিংক ডট
                      inactiveColor = Colors.grey.shade300;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: active ? 26 : 8,
                      decoration: BoxDecoration(
                        color: active ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),

                // Next / Get Started Button
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage == 0
                        ? const Color(
                            0xFFD4AF37,
                          ) // ১ম পেজে লোগোর সাথে মিলিয়ে গোল্ডেন বাটন
                        : (_currentPage == 2
                              ? Colors.white
                              : AppColors.primary),
                    foregroundColor: _currentPage == 0
                        ? Colors.black
                        : (_currentPage == 2
                              ? AppColors.primary
                              : Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == 2 ? "Get Started" : "Next",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentPage == 2
                            ? Icons.shopping_bag_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ১ম পেজ: ১ম ছবির মতো কালো ব্যাকগ্রাউন্ড ও সোনালি ZEYNEP লোগো
  Widget _buildFirstPage() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // আপনার দেওয়া ১ম লোগো ছবিটি ব্যাকগ্রাউন্ডে
          Image.asset(
            'assets/images/zeynep_logo.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // যদি ছবি এখনো assets ফোল্ডারে না রাখা হয় তবে সুন্দর ফলব্যাক লোগো দেখাবে
              return const Center(
                child: Text(
                  "ZEYNEP",
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              );
            },
          ),

          // নিচের দিকে হালকা কালো শেড যাতে লেখা ও বাটন স্পষ্ট থাকে
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),

          // নিচের অংশে ট্যাগলাইন
          Positioned(
            bottom: 110,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    "Export Clothing Shop",
                    style: TextStyle(
                      color: Color(0xFFF3D06B),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "A Bangladeshi Fashion Brand\nSister Concern of BD Royal Culture",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ২য় পেজ: ঠিকানাসহ শপের সব তথ্য (আমাদের আগের Rose Pink থিমে)
  Widget _buildSecondPage() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ওপরের Rose Pink Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ABOUT ZEYNEP",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Store Location &\nContact Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // নিচের তথ্যসমূহ (স্ক্রলযোগ্য কার্ড)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              children: [
                _buildDetailCard(
                  icon: Icons.location_on_rounded,
                  title: "Shop Address",
                  value:
                      "Plot # 1/1, Road # 30/Ka, Rupnagar R/A (Baitul Mukaddim Masjid-er pasher building), Mirpur, Dhaka 1216, Bangladesh",
                ),
                const SizedBox(height: 12),
                _buildDetailCard(
                  icon: Icons.storefront_rounded,
                  title: "Specialities & Hours",
                  value: "In-store shopping • Home Delivery\nAlways Open",
                ),
                const SizedBox(height: 12),
                _buildDetailCard(
                  icon: Icons.phone_in_talk_rounded,
                  title: "Phone & WhatsApp",
                  value: "Phone: 01533-751871\nWhatsApp: +880 1864-717457",
                ),
                const SizedBox(height: 12),
                _buildDetailCard(
                  icon: Icons.language_rounded,
                  title: "Website & Email",
                  value: "zeynepfashion.com\nzeynep.brand@gmail.com",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ৩য় পেজ: Welcome to Zeynep (আমাদের আগের Rose Pink গ্র্যাডিয়েন্ট থিমে)
  Widget _buildThirdPage() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Welcome to Zeynep",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Sister Concern of BD Royal Culture",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Discover the latest export-quality fashion, pick your perfect size & color, and get it delivered straight to your door.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
