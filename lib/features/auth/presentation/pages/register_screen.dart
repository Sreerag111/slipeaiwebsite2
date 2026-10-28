import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/auth_widgets.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (ok && mounted) {
      Navigator.pop(context);
      return;
    }
    if (!ok && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return ImageBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Logo + Title
                      const FloatingLogo(),
                      const SizedBox(height: 20),
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Join Slipe AI to get started',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: .92),
                            height: 1.3,
                          )),
                      const SizedBox(height: 20),

                      // ── Card
                      Obx(
                        () => Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Name field
                                AuthTextField(
                                  hint: 'Full name',
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: Icons.person_outline_rounded,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // ── Email field
                                AuthTextField(
                                  hint: 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  prefixIcon: Icons.mail_outline_rounded,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 12),

                                // ── Password field
                                AuthTextField(
                                  hint: 'Password',
                                  controller: _passwordController,
                                  textInputAction: TextInputAction.next,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  validator: (value) {
                                    if ((value ?? '').isEmpty) {
                                      return 'Password is required';
                                    }
                                    if ((value ?? '').length < 6) {
                                      return 'Must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // ── Confirm Password field
                                AuthTextField(
                                  hint: 'Confirm password',
                                  controller: _confirmController,
                                  textInputAction: TextInputAction.done,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_clock_outlined,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  validator: (value) {
                                    if ((value ?? '').isEmpty) {
                                      return 'Confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // ── Register button
                                AuthPrimaryButton(
                                  text: 'Sign Up',
                                  isLoading: auth.isLoading,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 22),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 70,
                                      child: Divider(
                                        color:
                                            Colors.white.withValues(alpha: .25),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        "or",
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          color: Colors.white
                                              .withValues(alpha: .9),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Divider(
                                        color:
                                            Colors.white.withValues(alpha: .25),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                AuthGoogleButton(
                                  onPressed: () async {
                                    final ok = await auth.signInWithGoogle();
                                    if (!ok &&
                                        mounted &&
                                        auth.errorMessage != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(auth.errorMessage!),
                                          backgroundColor:
                                              const Color(0xFF1A1A2E),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),

                                const SizedBox(height: 20),

                                // ── Sign In link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
