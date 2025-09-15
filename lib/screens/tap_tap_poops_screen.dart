import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../Theme.dart';

// Basketball data classes
class Ball {
  double x;
  double y;
  double velocityX;
  double velocityY;
  bool isActive;
  
  Ball({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.velocityY = 0,
    this.isActive = false,
  });
}

class Hoop {
  double x;
  double y;
  double direction;
  
  Hoop({required this.x, required this.y, this.direction = 1});
}

// Tap Tap Poops Game
class TapTapPoopsGame extends StatefulWidget {
  const TapTapPoopsGame({super.key});

  @override
  State<TapTapPoopsGame> createState() => _TapTapPoopsGameState();
}

class _TapTapPoopsGameState extends State<TapTapPoopsGame> with TickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _gameTimer;
  
  Ball ball = Ball(x: 200, y: 400);
  Hoop hoop = Hoop(x: 200, y: 150);
  
  int score = 0;
  int consecutiveShots = 0;
  bool gameStarted = false;
  bool ballInAir = false;
  int highScore = 0;
  int maxStreak = 0;

  static const double gravity = 0.5;
  static const double friction = 0.99;
  static const double hoopSpeed = 2.0;
  static const double ballRadius = 15;
  static const double hoopWidth = 80;
  static const double hoopHeight = 60;

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        highScore = prefs.getInt('tap_tap_high_score') ?? 0;
        maxStreak = prefs.getInt('tap_tap_max_streak') ?? 0;
      });
    }
  }

  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('tap_tap_high_score', score);
      highScore = score;
    }
    if (consecutiveShots > maxStreak) {
      await prefs.setInt('tap_tap_max_streak', consecutiveShots);
      maxStreak = consecutiveShots;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
    _loadSavedData().then((_) => _resetGame());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _resetGame() {
    if (!mounted) return;
    setState(() {
      score = 0;
      consecutiveShots = 0;
      gameStarted = false;
      ballInAir = false;
    });
    _resetBall();
    _startGameLoop();
  }

  void _resetBall() {
    if (!mounted) return;
    setState(() {
      ball.x = 200;
      ball.y = 400;
      ball.velocityX = 0;
      ball.velocityY = 0;
      ball.isActive = false;
      ballInAir = false;
    });
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateGame();
    });
  }

  void _updateGame() {
    if (!gameStarted || !mounted) return;

    // Move hoop
    _moveHoop();

    // Update poop physics
    if (ball.isActive) {
      setState(() {
        ball.x += ball.velocityX;
        ball.y += ball.velocityY;
        ball.velocityY += gravity;
        ball.velocityX *= friction;
      });

      // Check toilet collision
      if (_checkToiletCollision()) {
        _scorePoint();
      }

      // Check if poop is off screen
      if (ball.y > 600 || ball.x < -50 || ball.x > 450) {
        _resetBall();
        if (consecutiveShots > 0) {
          setState(() {
            consecutiveShots = 0;
          });
        }
      }
    }
  }

  bool _checkToiletCollision() {
    double poopCenterX = ball.x + ballRadius;
    double poopCenterY = ball.y + ballRadius;
    
    // Check if poop is within toilet boundaries
    bool withinToiletX = poopCenterX >= hoop.x && poopCenterX <= hoop.x + hoopWidth;
    bool withinToiletY = poopCenterY >= hoop.y + hoopHeight - 20 && poopCenterY <= hoop.y + hoopHeight;
    
    // Check if poop is moving downward (falling in)
    bool movingDown = ball.velocityY > 0;
    
    return withinToiletX && withinToiletY && movingDown;
  }

  void _scorePoint() async {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      score += (1 + consecutiveShots ~/ 3); // Bonus for consecutive shots
      consecutiveShots++;
    });
    await _saveGameData();
    _resetBall();
    
    // Show celebration
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(consecutiveShots == 1 ? 'Nice poop!' : 'Streak: $consecutiveShots!'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: AppTheme.greenAccent,
        ),
      );
    }
  }

  void _moveHoop() {
    if (!mounted) return;
    setState(() {
      hoop.x += hoopSpeed * hoop.direction;
      
      if (hoop.x <= 20 || hoop.x >= 300) {
        hoop.direction *= -1;
      }
    });
  }

  void _shootBall(double targetX, double targetY) {
    if (ball.isActive || !mounted) return;
    
    if (!gameStarted) {
      setState(() {
        gameStarted = true;
      });
    }

    HapticFeedback.selectionClick();

    double dx = targetX - (ball.x + ballRadius);
    double dy = targetY - (ball.y + ballRadius);
    double distance = sqrt(dx * dx + dy * dy);

    // Adjust power based on distance
    double power = min(distance / 20, 15);
    
    setState(() {
      ball.velocityX = (dx / distance) * power;
      ball.velocityY = (dy / distance) * power;
      ball.isActive = true;
      ballInAir = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveGameData();
        }
      },
      child: Scaffold(  
        appBar: AppBar(
          title: const Text('🧻 Tap-Tap Poops'),
          backgroundColor: AppTheme.primaryBrown,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async { 
                await _saveGameData();
                _resetGame();
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.creamBackground,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              // Score panel
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreCard('Score', score.toString()),
                    _buildScoreCard('Streak', consecutiveShots.toString()),
                    _buildScoreCard('Best', highScore.toString()),
                  ],
                ),
              ),
              
              // Game area
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.creamBackground.withOpacity(0.5),
                        Colors.white.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.brownPrimary.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brownPrimary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapUp: (details) {
                          if (!ballInAir && mounted) {
                            double tapX = details.localPosition.dx;
                            double tapY = details.localPosition.dy;
                            _shootBall(tapX, tapY);
                          }
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: GamePainter(
                              ball: ball,
                              hoop: hoop,
                            ),
                            child: Container(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!gameStarted)
                      Text(
                        'Tap anywhere to shoot the poop into the moving toilet!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          color: AppTheme.brownPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (gameStarted)
                      Text(
                        'Keep pooping! Build streaks for bonus points!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.orangeAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'High Score: $highScore • Best Streak: $maxStreak',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.softBlack.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.brownPrimary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brownPrimary.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.softBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the poop game
class GamePainter extends CustomPainter {
  final Ball ball;
  final Hoop hoop;

  GamePainter({required this.ball, required this.hoop});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint rimPaint = Paint()
      ..color = AppTheme.brownPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint toiletPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint toiletStrokePaint = Paint()
      ..color = AppTheme.softBlack.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw toilet bowl
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hoop.x - 5, hoop.y, 90, 70),
        const Radius.circular(10),
      ),
      toiletPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hoop.x - 5, hoop.y, 90, 70),
        const Radius.circular(10),
      ),
      toiletStrokePaint,
    );

    // Draw toilet opening (target area)
    canvas.drawOval(
      Rect.fromLTWH(hoop.x + 10, hoop.y + 50, 60, 15),
      Paint()..color = AppTheme.softBlack.withOpacity(0.4),
    );

    // Draw toilet seat
    canvas.drawOval(
      Rect.fromLTWH(hoop.x + 5, hoop.y + 45, 70, 25),
      Paint()
        ..color = AppTheme.brownPrimary.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw poop emoji
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: '💩',
        style: TextStyle(
          fontSize: 30,
          fontFamily: 'Noto Color Emoji',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Center the emoji on the ball position
    textPainter.paint(
      canvas, 
      Offset(
        ball.x + 15 - (textPainter.width / 2), 
        ball.y + 15 - (textPainter.height / 2)
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}