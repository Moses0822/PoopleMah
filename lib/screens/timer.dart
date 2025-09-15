import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Add this import
import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import '../db_helper.dart';
import '../Theme.dart';
import '../services/timer_service.dart'; // Add this import

// Copy the CartoonBorderPainter and CartoonBox from HomeScreen
class CartoonBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;

  CartoonBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          backgroundColor,
          backgroundColor.withOpacity(0.8),
          Colors.white.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final outerBorderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 3
      ..strokeCap = StrokeCap.round;

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor,
          borderColor.withOpacity(0.8),
          borderColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + (math.sin(size.width * 0.01) * 0.5).abs()
      ..strokeCap = StrokeCap.round;

    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.05),
          Colors.black.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
        center: Alignment.topLeft,
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 4.0;
    final waveLength = 20.0;
    final cornerRadius = 30.0;

    path.moveTo(cornerRadius, 0);

    for (double x = cornerRadius; x <= size.width - cornerRadius; x += waveLength) {
      path.quadraticBezierTo(
        x + waveLength / 2,
        waveHeight * math.sin(x / waveLength * math.pi),
        math.min(x + waveLength, size.width - cornerRadius),
        0,
      );
    }

    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    for (double y = cornerRadius; y <= size.height - cornerRadius; y += waveLength) {
      path.quadraticBezierTo(
        size.width - waveHeight * math.sin(y / waveLength * math.pi),
        y + waveLength / 2,
        size.width,
        math.min(y + waveLength, size.height - cornerRadius),
      );
    }

    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    for (double x = size.width - cornerRadius; x >= cornerRadius; x -= waveLength) {
      path.quadraticBezierTo(
        x - waveLength / 2,
        size.height + waveHeight * math.sin(x / waveLength * math.pi),
        math.max(x - waveLength, cornerRadius),
        size.height,
      );
    }

    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    for (double y = size.height - cornerRadius; y >= cornerRadius; y -= waveLength) {
      path.quadraticBezierTo(
        -waveHeight * math.sin(y / waveLength * math.pi),
        y - waveLength / 2,
        0,
        math.max(y - waveLength, cornerRadius),
      );
    }

    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 10, false);
    canvas.drawPath(path, outerBorderPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, innerShadowPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CartoonBox extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  const CartoonBox({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CartoonBorderPainter(
        borderColor: borderColor,
        borderWidth: borderWidth,
        backgroundColor: backgroundColor,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.orangeAccent?.withOpacity(0.3) ?? Colors.orange.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw decorative dots around the circle
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final x = center.dx + (radius - 15) * cos(angle);
      final y = center.dy + (radius - 15) * sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = AppTheme.orangeAccent?.withOpacity(0.5) ?? Colors.orange.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

double cos(double angle) => _cos(angle);
double sin(double angle) => _sin(angle);

double _cos(double x) {
  // Taylor series approximation for cosine
  double result = 1;
  double term = 1;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double _sin(double x) {
  // Taylor series approximation for sine
  double result = x;
  double term = x;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

class PoopTimerScreen extends StatefulWidget {
  final String uid;
  final String username;

  const PoopTimerScreen({
    Key? key,
    required this.uid,
    required this.username,
  }) : super(key: key);

  @override
  _PoopTimerScreenState createState() => _PoopTimerScreenState();
}

class _PoopTimerScreenState extends State<PoopTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final DBHelper _dbHelper = DBHelper();

  final TextEditingController _notesController = TextEditingController();

  final List<String> _qualityOptions = [
    'Excellent 😊',
    'Good 🙂',
    'Normal 😐',
    'Poor 😔',
    'Terrible 😖'
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);

    // Initialize timer service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.initializeSession(widget.uid, widget.username);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.startTimer();
    _rotationController.repeat();
  }

  void _pauseTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.pauseTimer();
    _rotationController.stop();
  }

  void _resumeTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.resumeTimer();
    _rotationController.repeat();
  }

  void _stopTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.stopTimer();
    _rotationController.stop();
    _showSessionSummary();
  }

  void _resetTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.resetTimer();
    _rotationController.stop();
    _rotationController.reset();
    _notesController.clear();
  }

  void _showSessionSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildSessionSummarySheet(setModalState),
      ),
    );
  }

  Widget _buildSessionSummarySheet(StateSetter setModalState) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFFE0DCC8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.brownPrimary?.withOpacity(0.5) ?? Colors.brown.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
              ),
              Text(
                'Session Complete! 🎉',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brownPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              CartoonBox(
                backgroundColor: Colors.white,
                borderColor: AppTheme.brownPrimary,
                borderWidth: 3,
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Duration: ${timerService.formatTime()}',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.orangeAccent,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How was your session?',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brownPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: timerService.selectedQuality,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE0DCC8),
                      ),
                      items: _qualityOptions.map((quality) {
                        return DropdownMenuItem(
                          value: quality,
                          child: Text(
                            quality,
                            style: GoogleFonts.bubblegumSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          timerService.selectedQuality = value ?? 'Normal 😐';
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              CartoonBox(
                backgroundColor: Colors.white,
                borderColor: AppTheme.brownPrimary,
                borderWidth: 3,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Size Rating: ${timerService.selectedSize.toInt()}/5',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brownPrimary,
                      ),
                    ),
                    Slider(
                      value: timerService.selectedSize,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppTheme.orangeAccent,
                      inactiveColor: AppTheme.orangeAccent?.withOpacity(0.3) ?? Colors.orange.withOpacity(0.3),
                      onChanged: (value) {
                        setModalState(() {
                          timerService.selectedSize = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        labelStyle: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE0DCC8),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        timerService.notes = value;
                      },
                    ),
                  ],
                ),
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: AppTheme.strongCartoonShadow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetTimer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Discard',
                          style: GoogleFonts.bubblegumSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: AppTheme.strongCartoonShadow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saving session...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          await _saveSession();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Session',
                          style: GoogleFonts.bubblegumSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSession() async {
    Navigator.pop(context);
    
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    try {
      final sessionData = timerService.getSessionData();
      
      print('Saving session with:');
      print('Duration: ${sessionData['duration']} seconds');
      print('Quality: ${sessionData['quality']}');
      print('Size: ${sessionData['size']}');
      print('Notes: ${sessionData['notes']}');
      print('Timestamp: ${sessionData['timestamp']}');
      print('DateOnly: ${sessionData['dateOnly']}');
      
      await _dbHelper.insertTimerSession(sessionData);
      print('✅ Saved to local database successfully');

      try {
        await FirebaseFirestore.instance.collection('poop_sessions').add({
          'uid': sessionData['userId'],
          'username': sessionData['username'],
          'duration': sessionData['duration'],
          'quality': sessionData['quality'],
          'size': sessionData['size'],
          'notes': sessionData['notes'],
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': sessionData['timestamp'],
        });
        print('✅ Also saved to Firestore as backup');
      } catch (firestoreError) {
        print('⚠️ Firestore backup failed (but local save succeeded): $firestoreError');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Poop session saved successfully! 💩',
            style: GoogleFonts.bubblegumSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.orangeAccent,
          duration: Duration(seconds: 3),
        ),
      );
      _resetTimer();
    } catch (e) {
      print('❌ Error saving poop session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save session: ${e.toString()}',
            style: GoogleFonts.bubblegumSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Poop Timer 💩',
              style: GoogleFonts.bubblegumSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            ),
            backgroundColor: const Color(0xFFE0DCC8),
            foregroundColor: AppTheme.brownPrimary,
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFE0DCC8),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CartoonBox(
                  backgroundColor: AppTheme.orangeAccent,
                  borderColor: AppTheme.brownPrimary,
                  borderWidth: 3,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${widget.username}!',
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ready to time your session?',
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('💩', style: TextStyle(fontSize: 32)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                
                CartoonBox(
                  backgroundColor: Colors.white,
                  borderColor: AppTheme.brownPrimary,
                  borderWidth: 3,
                  padding: const EdgeInsets.all(30),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: timerService.isRunning ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.cardBackground,
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 3,
                            ),
                            boxShadow: AppTheme.strongCartoonShadow,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (timerService.isRunning)
                                AnimatedBuilder(
                                  animation: _rotationAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationAnimation.value * 2 * 3.14159,
                                      child: Container(
                                        width: 240,
                                        height: 240,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.orangeAccent,
                                            width: 4,
                                          ),
                                        ),
                                        child: CustomPaint(
                                          painter: TimerPainter(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '💩',
                                    style: TextStyle(fontSize: 60),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    timerService.formatTime(),
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.brownPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    timerService.getTimerStatus(),
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brownPrimary?.withOpacity(0.7) ?? Colors.brown.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 40),
                
                if (!timerService.hasStarted) ...[
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: AppTheme.strongCartoonShadow,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: AppTheme.brownPrimary, width: 3),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Start Timer',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (timerService.isRunning) ...[
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: _pauseTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pause),
                                SizedBox(width: 6),
                                Text(
                                  'Pause',
                                  style: GoogleFonts.bubblegumSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: _stopTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop),
                                SizedBox(width: 6),
                                Text(
                                  'Finish',
                                  style: GoogleFonts.bubblegumSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: _resumeTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.greenAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 6),
                                Text(
                                  'Resume',
                                  style: GoogleFonts.bubblegumSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: _stopTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop),
                                SizedBox(width: 6),
                                Text(
                                  'Finish',
                                  style: GoogleFonts.bubblegumSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: AppTheme.strongCartoonShadow,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextButton.icon(
                      onPressed: _resetTimer,
                      icon: Icon(Icons.refresh, color: AppTheme.brownPrimary),
                      label: Text(
                        'Reset Timer',
                        style: GoogleFonts.bubblegumSans(
                          color: AppTheme.brownPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}