import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

// ---------- Branding (change these to match your store) ----------
const String kAppName = 'Zeynep';
const String kTagline = 'Discover the latest fashion,\ndelivered to your door.';
const Color kBrand = Color(0xFFE91E63);
const Color kBrandDark = Color(0xFF880E4F);

/// Shows AuthScreen when logged out, and [child] when logged in.
/// Usage:  home: const AuthGate(child: HomePage())
class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: kBrand)),
          );
        }
        if (snapshot.hasData) return child;
        return const AuthScreen();
      },
    );
  }
}

/// Call this from the logout button on your home page:
///   onPressed: () => confirmAndLogout(context)
Future<void> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.logout_rounded, color: kBrand, size: 34),
      title: const Text('Logout'),
      content: const Text(
        'Are you sure you want to logout?',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(100, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrand,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Yes'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await AuthService().signOut();
    // Close any pages still open so the login screen shows cleanly.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;
  String? error;
  String? info;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      error = null;
      info = null;
    });
    try {
      await action();
      // On success, AuthGate automatically switches to the home screen.
    } catch (e) {
      if (mounted) setState(() => error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (isLogin) {
      _run(() => _auth.signIn(email: _email.text, password: _password.text));
    } else {
      _run(() async {
        final email = _email.text.trim();
        await _auth.signUp(
          name: _name.text,
          phone: _phone.text,
          email: email,
          password: _password.text,
        );
        // Account created: go back to the Login tab and ask the user to login.
        if (!mounted) return;
        setState(() {
          isLogin = true;
          _name.clear();
          _phone.clear();
          _password.clear();
          _email.text = email;
          info = 'Account created successfully. Please login to continue.';
        });
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() {
        info = null;
        error = 'Enter your email above, then tap "Forgot password?"';
      });
      return;
    }
    await _run(() async {
      await _auth.sendPasswordReset(email);
      if (mounted) setState(() => info = 'Password reset email sent to $email');
    });
  }

  void _switchMode(bool login) {
    if (loading || isLogin == login) return;
    setState(() {
      isLogin = login;
      error = null;
      info = null;
    });
  }

  // ---------- Layout ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _BrandPanel()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildForm(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const _BrandPanel(compact: true),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Form card ----------
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Login / Sign up tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDF3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tab('Login', isLogin, () => _switchMode(true)),
                  _tab('Sign up', !isLogin, () => _switchMode(false)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isLogin ? 'Welcome back' : 'Create your account',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isLogin
                  ? 'Login to continue shopping'
                  : 'Sign up to start shopping with us',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            if (!isLogin) ...[
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Full name', Icons.person_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Phone number', Icons.phone_outlined),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 14),
            ],

            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration('Email', Icons.mail_outline),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: hidePassword,
              decoration: _decoration(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Enter at least 6 characters'
                  : null,
              onFieldSubmitted: (_) => loading ? null : _submit(),
            ),

            if (isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: kBrand),
                  ),
                ),
              )
            else
              const SizedBox(height: 12),

            if (error != null) _banner(error!, isError: true),
            if (info != null) _banner(info!, isError: false),

            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLogin ? 'Login' : 'Create account',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: loading ? null : () => _run(_auth.signInWithGoogle),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFE0DCE3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            if (!isLogin) ...[
              const SizedBox(height: 16),
              Text(
                'By signing up, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Small helpers ----------
  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? kBrand : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color.shade700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F6F9),
      border: border(Colors.transparent),
      enabledBorder: border(const Color(0xFFE8E3EB)),
      focusedBorder: border(kBrand, 1.5),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red, 1.5),
    );
  }
}

// ---------- Left / top branding panel ----------
class _BrandPanel extends StatelessWidget {
  final bool compact;
  const _BrandPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        28,
        compact ? 56 : 40,
        28,
        compact ? 40 : 40,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBrand, kBrandDark],
        ),
        borderRadius: compact
            ? const BorderRadius.vertical(bottom: Radius.circular(32))
            : BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -60, top: -60, child: _circle(180)),
          Positioned(left: -40, bottom: -50, child: _circle(140)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                kAppName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kTagline,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              if (!compact) ...[
                const SizedBox(height: 36),
                _feature(Icons.local_shipping_outlined, 'Fast delivery'),
                _feature(
                  Icons.verified_user_outlined,
                  'Secure payments with bKash',
                ),
                _feature(Icons.style_outlined, 'Latest fashion collections'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0x14FFFFFF),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}
