import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Particle Model
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double opacitySpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.opacitySpeed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = Colors.white.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Particle Background
// ─────────────────────────────────────────────────────────────────────────────

class ParticleBackground extends StatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _rng = math.Random();

  static const int _particleCount = 600;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(_particleCount, (_) => _makeParticle());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _controller.repeat();
  }

  _Particle _makeParticle() {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      vx: (_rng.nextDouble() - 0.5) * 0.00018,
      vy: (_rng.nextDouble() - 0.5) * 0.00018,
      size: _rng.nextDouble() * 1.3 + 0.3,
      opacity: _rng.nextDouble() * 0.55 + 0.1,
      opacitySpeed: (_rng.nextDouble() - 0.5) * 0.006,
    );
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.opacity += p.opacitySpeed;

        if (p.x < 0) p.x = 1.0;
        if (p.x > 1) p.x = 0.0;
        if (p.y < 0) p.y = 1.0;
        if (p.y > 1) p.y = 0.0;

        if (p.opacity <= 0.05) p.opacitySpeed = p.opacitySpeed.abs();
        if (p.opacity >= 0.65) p.opacitySpeed = -p.opacitySpeed.abs();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy MeshBackground (kept for backward compat)
// ─────────────────────────────────────────────────────────────────────────────

class MeshBackground extends StatelessWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ParticleBackground(child: child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient Border Painter (static white → blue sweep)
// ─────────────────────────────────────────────────────────────────────────────

class _GradientBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;

  _GradientBorderPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = borderRadius.toRRect(rect);

    // Outer gradient border
    final gradient = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: 0.60),
        const Color(0xFF93C5FD).withValues(alpha: 0.75),
        AppTheme.accent.withValues(alpha: 0.55),
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.60),
      ],
      stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Background
// ─────────────────────────────────────────────────────────────────────────────

class ImageBackground extends StatelessWidget {
  final Widget child;

  const ImageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/login_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay for better readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),

          // Optional blue gradient (matches your app theme)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.6,
                  colors: [
                    Color(0x332563EB),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Card — static gradient border, no animation
// ─────────────────────────────────────────────────────────────────────────────

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(24));
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.10),
            blurRadius: 36,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GradientBorderPainter(borderRadius: radius),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Colors.black.withValues(alpha: 0.65),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Logo with Animation
// ─────────────────────────────────────────────────────────────────────────────

class FloatingLogo extends StatefulWidget {
  const FloatingLogo({super.key});

  @override
  State<FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<FloatingLogo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      // decoration: BoxDecoration(
      //   shape: BoxShape.circle,
      //   boxShadow: [
      //     BoxShadow(
      //       color: const Color(0xFF60A5FA).withValues(alpha: 0.28),
      //       blurRadius: 32,
      //       spreadRadius: 2,
      //     ),
      //   ],
      // ),
      child: Image.asset(
        'assets/logo/new_logo.png',
        width: 90,
        height: 90,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Text Field — pill shaped with icon prefix
// ─────────────────────────────────────────────────────────────────────────────

class AuthTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  const AuthTextField(
      {super.key,
      required this.hint,
      required this.controller,
      this.keyboardType = TextInputType.text,
      this.textInputAction,
      this.obscureText = false,
      this.prefixIcon,
      this.validator,
      this.autofillHints});
  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      validator: widget.validator,
      focusNode: _focusNode,
      autofillHints: widget.autofillHints,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      textInputAction: widget.textInputAction,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: const Color(0xFF93C5FD),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.75),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 22,
                color: _isFocused
                    ? const Color(0xFF93C5FD)
                    : Colors.white.withValues(alpha: 0.85),
              )
            : null,
        suffixIcon: widget.obscureText
            ? Focus(
                canRequestFocus: false,
                descendantsAreFocusable: false,
                child: IconButton(
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0x26FFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0x33FFFFFF),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0x6693C5FD),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.2),
        ),
        errorStyle: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppTheme.danger,
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Primary Button — dark gradient pill
// ─────────────────────────────────────────────────────────────────────────────

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !isLoading;

    return Center(
      child: SizedBox(
        width: 122,
        height: 46,
        child: Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: active ? onPressed : null,
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.black.withValues(alpha: 0.02),
            mouseCursor:
                active ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AuthGoogleButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;

    return Center(
      child: SizedBox(
        width: 235,
        height: 52,
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: active ? onPressed : null,
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.white.withValues(alpha: .05),
            highlightColor: Colors.white.withValues(alpha: .02),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/google_logo.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Outlined Button (Skip / back)
// ─────────────────────────────────────────────────────────────────────────────

class AuthOutlinedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AuthOutlinedButton> createState() => _AuthOutlinedButtonState();
}

class _AuthOutlinedButtonState extends State<AuthOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) async {
        await _pressCtrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.0,
            ),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: Text(
                  widget.text,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
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

// ─────────────────────────────────────────────────────────────────────────────
// OR Divider
// ─────────────────────────────────────────────────────────────────────────────

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Button — Google / Email icon pill
// ─────────────────────────────────────────────────────────────────────────────

class AuthSocialButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  const AuthSocialButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) async {
          await _ctrl.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.09)
                  : const Color(0xFF111118),
              border: Border.all(
                color: Colors.white.withValues(alpha: _hovered ? 0.20 : 0.12),
                width: 1.0,
              ),
            ),
            child: Center(child: widget.icon),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In Button (kept for backward compat)
// ─────────────────────────────────────────────────────────────────────────────

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthOutlinedButton(
      text: 'Continue with Google',
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard (legacy alias)
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
