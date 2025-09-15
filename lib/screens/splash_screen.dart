import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _textController;
  late AnimationController _bubbleController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _backgroundController;
  late AnimationController _poopBounceController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _poopBounceAnimation;
  
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _textController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _bubbleController = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );

    _poopBounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Curves.bounceOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _poopBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _poopBounceController, curve: Curves.elasticOut),
    );
  }

  void _startAnimationSequence() {
    _backgroundController.forward();
    
    _bubbleController.repeat();

    _pulseController.repeat(reverse: true);
    
    _waveController.repeat();

    _controller.forward();

    Future.delayed(Duration(milliseconds: 500), () {
      if (!_disposed) {
        _poopBounceController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 1000), () {
      if (!_disposed) {
        _textController.forward();
      }
    });

    Future.delayed(Duration(seconds: 4), () {
      if (!_disposed) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(Color(0xFF8D6E63), Color(0xFF6D4C41), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFFA1887F), Color(0xFF8D6E63), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFFBCAAA4), Color(0xFFA1887F), _backgroundAnimation.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  ...List.generate(12, (index) => _buildDigestionBubble(index)),
                  
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: WavePainter(_waveAnimation.value),
                        );
                      },
                    ),
                  ),
                  
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _scaleAnimation,
                            _pulseAnimation,
                            _poopBounceAnimation,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value * _pulseAnimation.value * 
                                     (0.8 + 0.2 * _poopBounceAnimation.value),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFFF5F5DC),
                                      Color(0xFFE8E8D0),
                                      Color(0xFFDDD8C0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(75),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 25,
                                      offset: Offset(0, 15),
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: Color(0xFF4CAF50).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 0),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Replace the Icon with Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(35),
                                      child: Image.asset(
                                        'assets/images/logo.png', // Replace with your image path
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.contain,
                                        // Add error handling
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback to icon if image fails to load
                                          return Icon(
                                            Icons.healing,
                                            size: 70,
                                            color: Color(0xFF6D4C41),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 35,
                                      right: 35,
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value * 0.6,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 40),
                        

                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _poopBounceAnimation,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(0, -5 * math.sin(_poopBounceAnimation.value * math.pi)),
                                              child: Text(
                                                '💩',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(width: 10),
                                        ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
                                            colors: [Colors.white, Color(0xFFF5F5DC)],
                                          ).createShader(bounds),
                                          child: Text(
                                            'PoopleMah',
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 2.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        AnimatedBuilder(
                                          animation: _poopBounceAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 0.8 + 0.2 * _poopBounceAnimation.value,
                                              child: Text(
                                                '💚',
                                                style: TextStyle(fontSize: 24),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                
                                SizedBox(height: 15),
                                
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value * 0.8,
                                      child: Text(
                                        'Track Your Health Journey',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                SizedBox(height: 10),
                                
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value * 0.6,
                                      child: Text(
                                        'A Healthy Future Starts with Your Gut 🌱',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white60,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                SizedBox(height: 25),
                                
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF4CAF50).withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Loading health data...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 创建消化气泡效果
  Widget _buildDigestionBubble(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 6 + 3;
    final initialX = random.nextDouble();
    final initialY = random.nextDouble();
    final speed = random.nextDouble() * 0.3 + 0.1;
    final color = [
      Color(0xFF4CAF50).withOpacity(0.3),
      Color(0xFF8BC34A).withOpacity(0.2),
      Color(0xFFCDDC39).withOpacity(0.2),
    ][index % 3];
    
    return AnimatedBuilder(
      animation: _bubbleAnimation,
      builder: (context, child) {
        final progress = (_bubbleAnimation.value * speed + random.nextDouble()) % 1.0;
        final yPosition = (initialY + progress) % 1.0;
        final opacity = (math.sin(progress * math.pi * 2) * 0.5 + 0.5) * 0.4;
        
        return Positioned(
          left: MediaQuery.of(context).size.width * initialX,
          top: MediaQuery.of(context).size.height * yPosition,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(opacity * 0.5),
                  blurRadius: size * 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    _textController.dispose();
    _bubbleController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _backgroundController.dispose();
    _poopBounceController.dispose();
    super.dispose();
  }
}

// 波浪绘制器（模拟肠道蠕动）
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 3;

    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.3 + i * size.height * 0.2;
      path.reset();
      
      for (double x = 0; x <= size.width; x += 1) {
        final waveY = y + waveHeight * 
          math.sin((x / waveLength + animationValue + i * 0.5) * 2 * math.pi);
        
        if (x == 0) {
          path.moveTo(x, waveY);
        } else {
          path.lineTo(x, waveY);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}