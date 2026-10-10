import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/r_logo.dart';
import 'citizen_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Full Name, Email, and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ApiService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${user.fullName}! Account created successfully.'),
          backgroundColor: CivicColors.accentEmerald,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CitizenScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompactScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: CivicColors.darkBg,
      body: Stack(
        children: [
          // 1. Background Watermark Text "WELCOME TO CIVICEYE AI" & Geometric Logo
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle background R logo
                  const RLogoWidget(size: 320, opacity: 0.05),

                  // Watermark text: "WELCOME TO CIVICEYE AI"
                  Positioned(
                    top: isCompactScreen ? 100 : 120,
                    child: Text(
                      'WELCOME TO CIVICEYE AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompactScreen ? 22 : 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFACC15).withValues(alpha: 0.05),
                        letterSpacing: 4,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Register Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactScreen ? 20.0 : 32.0,
                  vertical: 20.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top App Branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CivicColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const RLogoWidget(size: 32, opacity: 1.0),
                          ),
                          const SizedBox(width: 12),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'sans-serif',
                              ),
                              children: [
                                TextSpan(text: 'CivicEye '),
                                TextSpan(
                                  text: 'AI',
                                  style: TextStyle(color: Color(0xFFFACC15)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Professional Register Card Container
                      Container(
                        padding: EdgeInsets.all(isCompactScreen ? 22.0 : 28.0),
                        decoration: BoxDecoration(
                          color: CivicColors.cardBg.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CivicColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Register to report & track civic issues',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 20),

                            // Full Name Field
                            const Text(
                              'Full Name',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _fullNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                                hintText: 'Priya Rajendran',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                filled: true,
                                fillColor: CivicColors.darkBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.primary)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Email Field
                            const Text(
                              'Email Address',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                                hintText: 'priya@domain.com',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                filled: true,
                                fillColor: CivicColors.darkBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.primary)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Mobile Number
                            const Text(
                              'Mobile Number',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                                hintText: '+91 98765 43210',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                filled: true,
                                fillColor: CivicColors.darkBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.primary)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            const Text(
                              'Password',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                                hintText: '••••••••',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                filled: true,
                                fillColor: CivicColors.darkBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivicColors.primary)),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Submit Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CivicColors.accentEmerald,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Register Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Already Have Account? Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: CivicColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Already Have an Account? Sign In', style: TextStyle(color: CivicColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
