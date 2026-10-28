import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/auth_widgets.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';
import '../../../../core/version/app_version_service.dart';
import '../../../../core/version/app_update_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _enterCtrl.forward();
      final status = await AppVersionService.instance.checkUpdateStatus();
      if (status == AppUpdateStatus.forceUpdateRequired && mounted) {
        await showAppUpdateDialog(context, isMandatory: true);
      } else if (status == AppUpdateStatus.softUpdateAvailable && mounted) {
        await showAppUpdateDialog(context, isMandatory: false);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
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

  void _goToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const RegisterScreen(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
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
                      // ── Logo + Title
                      const FloatingLogo(),
                      const SizedBox(height: 22),
                      Text(
                        'Welcome to Slipe AI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: .92),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 20),
                      // ── Card
                      Obx(
                        () => Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Email field
                                AuthTextField(
                                  hint: 'Email',
                                  controller: _emailController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  validator: _validateEmail,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // ── Password field
                                AuthTextField(
                                  hint: 'Password',
                                  controller: _passwordController,
                                  textInputAction: TextInputAction.done,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (value) {
                                    if ((value ?? '').isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                  autofillHints: const [
                                    AutofillHints.password,
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color:
                                            Colors.white.withValues(alpha: .9),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ── Login button
                                AuthPrimaryButton(
                                  text: 'Log In',
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
                                        style: GoogleFonts.inter(
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
                                const SizedBox(height: 20),

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

                                const SizedBox(height: 24),

                                // ── Sign Up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _goToRegister,
                                      child: Text(
                                        ' Sign Up',
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
