import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
// import '../../services/api_service.dart'; // Uncomment jika ingin menggunakan validasi token



class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  bool _show = false;
  bool _showContent = false;
  bool _showProgress = false;
  
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _progressController;
  
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Initialize animations
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _startAnimations();
    _navigate();
  }

  void _startAnimations() async {
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Show initial content
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _show = true);
    _scaleController.forward();
    
    // Show text content
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showContent = true);
    _fadeController.forward();
    
    // Show progress bar
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showProgress = true);
    _progressController.forward();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Tampilkan splash minimal 2.5 detik untuk animasi yang smooth
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Untuk development: selalu clear token saat hot restart
    // Ini memastikan user selalu login ulang setelah hot restart
    // Hapus baris di bawah ini jika ingin tetap login setelah hot restart
    await prefs.remove('auth_token');
    
    // Setelah clear token, selalu masuk ke login
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
    
    // Kode di bawah ini untuk production (jika ingin tetap login setelah hot restart)
    // Uncomment jika ingin menggunakan validasi token
    /*
    // Validasi token dengan API jika token ada
    if (token != null && token.isNotEmpty) {
      try {
        final api = ApiService();
        // Coba ambil profile untuk validasi token dengan timeout pendek
        await api.getProfile().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw Exception('Timeout validating token');
          },
        );
        // Token valid, masuk ke dashboard
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } catch (e) {
        // Token tidak valid, expired, atau error koneksi - hapus token dan masuk ke login
        await prefs.remove('auth_token');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      // Tidak ada token, masuk ke login
      Navigator.of(context).pushReplacementNamed('/login');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Enhanced background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withOpacity(0.15),
                  colors.secondary.withOpacity(0.12),
                  colors.tertiary.withOpacity(0.08),
                  colors.primaryContainer.withOpacity(0.06),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Animated floating particles
          ...List.generate(8, (index) => _FloatingParticle(
            index: index,
            size: size,
            pulseAnim: _pulseAnim,
          )),
          
          // Decorative animated blobs
          Positioned(
            top: -80,
            left: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: 0.9 + _pulseAnim.value * 0.15,
                child: Transform.rotate(
                  angle: _pulseAnim.value * 0.1,
                  child: _AnimatedBlob(
                    size: 200,
                    colors: [
                      colors.primary.withOpacity(0.6),
                      colors.primary.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: -90,
            right: -40,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: 1.0 - _pulseAnim.value * 0.1,
                child: Transform.rotate(
                  angle: -_pulseAnim.value * 0.08,
                  child: _AnimatedBlob(
                    size: 240,
                    colors: [
                      colors.secondary.withOpacity(0.55),
                      colors.primaryContainer.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: size.height * 0.2,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: 0.85 + _pulseAnim.value * 0.12,
                child: Transform.rotate(
                  angle: _pulseAnim.value * 0.06,
                  child: _AnimatedBlob(
                    size: 160,
                    colors: [
                      colors.tertiary.withOpacity(0.5),
                      colors.secondary.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with enhanced animations
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.98 + _pulseAnim.value * 0.04,
                            child: _EnhancedAppLogo(size: 120),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // App title and description
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _showContent ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Text(
                        'Gajayana Kost',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temukan kamar idealmu dengan mudah',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Enhanced progress indicator
                      if (_showProgress)
                        AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (context, child) {
                            return Container(
                              width: 200,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: colors.surfaceVariant.withOpacity(0.3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressAnim.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        colors.primary,
                                        colors.secondary,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom loading text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: _showProgress ? 1.0 : 0.0,
              child: Text(
                'Memuat aplikasi...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

class _AnimatedBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  
  const _AnimatedBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            center: Alignment.topLeft,
            radius: 0.8,
          ),
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final int index;
  final Size size;
  final Animation<double> pulseAnim;
  
  const _FloatingParticle({
    required this.index,
    required this.size,
    required this.pulseAnim,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle> {
  late double x, y;
  late double speed;
  late double size;
  
  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.index);
    x = random.nextDouble() * widget.size.width;
    y = random.nextDouble() * widget.size.height;
    speed = 0.5 + random.nextDouble() * 1.0;
    size = 2 + random.nextDouble() * 4;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: widget.pulseAnim,
      builder: (context, child) {
        return Positioned(
          left: x + math.sin(widget.pulseAnim.value * 2 * math.pi + widget.index) * 20,
          top: y + math.cos(widget.pulseAnim.value * 2 * math.pi + widget.index) * 15,
          child: Opacity(
            opacity: 0.3 + widget.pulseAnim.value * 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnhancedAppLogo extends StatelessWidget {
  final double size;
  
  const _EnhancedAppLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
            colors.tertiary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colors.secondary.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: Icon(
          Icons.home_rounded,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}
