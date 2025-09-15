import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import '../db_helper.dart';
import '../services/friend_service.dart';
import '../services/stats_service.dart';
import '../services/timer_service.dart'; 
import '../config/constants.dart';
import '../models/chat_message.dart';
import '../Theme.dart';
import '../widgets/timer_status_widget.dart';
import '../services/notification_service.dart';

// Enhanced cartoon border widgets with improved effects
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
    // 1. Enhanced Background with Gradient
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

    // 2. Outer Border (Dark Shadow Outline)
    final outerBorderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 3
      ..strokeCap = StrokeCap.round;

    // 3. Main Border with Gradient
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
      ..strokeWidth = borderWidth + (math.sin(size.width * 0.01) * 0.5).abs() // Hand-drawn wobble
      ..strokeCap = StrokeCap.round;

    // 4. Inner Shadow Paint
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

    // Parameters
    final waveHeight = 4.0;
    final waveLength = 20.0;
    final cornerRadius = 30.0; // ⬅️ now actually used

    // Start at top-left corner (just inside the radius)
    path.moveTo(cornerRadius, 0);

    // ---- Top edge ----
    for (double x = cornerRadius; x <= size.width - cornerRadius; x += waveLength) {
      path.quadraticBezierTo(
        x + waveLength / 2,
        waveHeight * math.sin(x / waveLength * math.pi),
        math.min(x + waveLength, size.width - cornerRadius),
        0,
      );
    }

    // ---- Top-right rounded corner ----
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // ---- Right edge ----
    for (double y = cornerRadius; y <= size.height - cornerRadius; y += waveLength) {
      path.quadraticBezierTo(
        size.width - waveHeight * math.sin(y / waveLength * math.pi),
        y + waveLength / 2,
        size.width,
        math.min(y + waveLength, size.height - cornerRadius),
      );
    }

    // ---- Bottom-right rounded corner ----
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    // ---- Bottom edge ----
    for (double x = size.width - cornerRadius; x >= cornerRadius; x -= waveLength) {
      path.quadraticBezierTo(
        x - waveLength / 2,
        size.height + waveHeight * math.sin(x / waveLength * math.pi),
        math.max(x - waveLength, cornerRadius),
        size.height,
      );
    }

    // ---- Bottom-left rounded corner ----
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // ---- Left edge ----
    for (double y = size.height - cornerRadius; y >= cornerRadius; y -= waveLength) {
      path.quadraticBezierTo(
        -waveHeight * math.sin(y / waveLength * math.pi),
        y - waveLength / 2,
        0,
        math.max(y - waveLength, cornerRadius),
      );
    }

    // ---- Top-left rounded corner ----
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();

    // PAINTING ORDER (layered effect):

    // 1. Enhanced Drop Shadow (thicker & blurrier)
    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 10, false);

    // 2. Outer dark border (creates depth)
    canvas.drawPath(path, outerBorderPaint);

    // 3. Background fill with gradient
    canvas.drawPath(path, paint);

    // 4. Inner shadow for depth
    canvas.drawPath(path, innerShadowPaint);

    // 5. Main decorative border on top
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced CartoonBox with additional customization options
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.uid, required this.username});
  final String uid;       // Firebase UID
  final String username;  // Display name

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StatsService _statsService = StatsService();
  final FriendService _friendService = FriendService();

  int checkinCount = 0;
  int streak = 0;
  int _currentIndex = 0;
  int _pendingRequests = 0;

  // Recent activities
  List<Map<String, dynamic>> recentActivities = [];
  bool isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    

    _loadStats();
    _loadPendingRequests();
    _loadRecentActivities();
    _checkPoopReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔹 Pass lifecycle changes to the **user-specific TimerService**
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.onAppLifecycleStateChanged(state);
  }

  Future<void> _loadPendingRequests() async {
    final request = await _friendService.getPendingRequests(widget.uid);
    setState(() {
      _pendingRequests = request.length;
    });
  }

  Future<void> _loadStats() async {
  final dbHelper = DBHelper();
  final db = await dbHelper.database;

  // Calculate the current streak from checkins (the actual source of truth)
  final calculatedStreak = await dbHelper.getCheckinStreakFixed(widget.uid);
  
  // Update the stats table with the calculated streak
  final existingStats = await db.query('stats', where: 'userId = ?', whereArgs: [widget.uid]);
  
  if (existingStats.isNotEmpty) {
    // Update existing stats record
    await db.update(
      'stats',
      {'streak': calculatedStreak},
      where: 'userId = ?',
      whereArgs: [widget.uid],
    );
  } else {
    // Insert new stats record if none exists
    await db.insert('stats', {
      'userId': widget.uid,
      'streak': calculatedStreak,
      'totalPoops': 0, // Initialize with default value
    });
  }

  // Get check-in count from service
  final count = await _statsService.getCheckinCount(widget.uid);

  setState(() {
    checkinCount = count;
    streak = calculatedStreak; // Use the calculated streak directly
  });
  
  print('Loaded stats - Streak: $calculatedStreak, Checkins: $count');
}

  Future<void> _checkPoopReminder() async {
    final db = DBHelper();
    final lastCheckin = await db.getLastCheckinDate(widget.uid);

    if (lastCheckin == null) {
      await NotificationService.showPoopReminder();
      return;
    }

    final days = DateTime.now().difference(lastCheckin).inDays;
    if (days >= 3) {
      await NotificationService.showPoopReminder();
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() => isLoadingActivities = true);

    try {
      final dbHelper = DBHelper();
      final recentCheckins = await dbHelper.getRecentCheckins(widget.uid, 5);
      final recentTimerSessions = await dbHelper.getRecentTimerSessions(widget.uid, 5);

      List<Map<String, dynamic>> combinedActivities = [];

      if (recentCheckins != null) {
        for (var checkin in recentCheckins) {
          combinedActivities.add({
            'type': 'checkin',
            'title': 'Check-in completed',
            'description':
                'Stool Type ${(checkin['stoolType'] ?? 0) + 1}, Feeling: ${checkin['feeling']}/5',
            'timestamp': checkin['timestamp'],
            'icon': Icons.check_circle,
            'color': AppTheme.greenAccent,
          });
        }
      }

      if (recentTimerSessions != null) {
        for (var session in recentTimerSessions) {
          final duration = (session['duration'] ?? 0.0).toDouble();
          combinedActivities.add({
            'type': 'timer',
            'title': 'Timer session completed',
            'description':
                'Duration: ${_formatDuration(duration)}${session['sizeRating'] != null ? ', Size: ${session['sizeRating']}/5' : ''}',
            'timestamp': session['timestamp'],
            'icon': Icons.timer,
            'color': AppTheme.orangeAccent,
          });
        }
      }

      combinedActivities.sort((a, b) =>
          DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

      recentActivities = combinedActivities.take(3).toList();
    } catch (e) {
      print('Error loading recent activities: $e');
      recentActivities = [];
    } finally {
      setState(() => isLoadingActivities = false);
    }
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toInt()}s';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = (seconds % 60).toInt();
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '${hours}h ${minutes}m';
    }
  }

  String _getRelativeTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PoopleMah',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary,
          ),
        ),
        backgroundColor: const Color(0xFFE0DCC8),
        foregroundColor: AppTheme.brownPrimary,
        elevation: 0,
        actions: [
          TimerStatusWidget(), 
          Stack(
                children: [
                  AppTheme.cartoonIconButton(
                    icon: Icons.notifications,
                    onPressed: () async {
                      final requests = await _friendService.getPendingRequests(widget.uid);

                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white, // Changed from AppTheme.cardBackground to solid white
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                width: 2.5,
                              ),
                            ),
                            title: Text(
                              "Friend Requests",
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                              ),
                            ),
                            content: Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // Ensure content area is also solid white
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: requests.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        "No new requests",
                                        style: GoogleFonts.bubblegumSans(
                                          fontSize: 14,
                                          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: requests.map((req) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5), // Light gray background for each request
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${req['username']} sent you a request",
                                                style: GoogleFonts.bubblegumSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(Icons.check, size: 18),
                                                        label: Text(
                                                          'Accept',
                                                          style: GoogleFonts.bubblegumSans(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          await _friendService.acceptRequest(req['requestId']);
                                                          Navigator.pop(context);
                                                          _loadPendingRequests();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.greenAccent ?? Colors.green,
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                                              width: 2,
                                                            ),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(left: 8),
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(Icons.close, size: 18),
                                                        label: Text(
                                                          'Decline',
                                                          style: GoogleFonts.bubblegumSans(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          await _friendService.deleteRequest(req['requestId']);
                                                          Navigator.pop(context);
                                                          _loadPendingRequests();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                                              width: 2,
                                                            ),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            actions: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                    width: 2,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    size: 45,
                  ),

              // 🔴 Red badge
              if (_pendingRequests > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_pendingRequests',
                      style: GoogleFonts.bubblegumSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFE0DCC8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add timer controls card if timer is active
            Consumer<TimerService>(
              builder: (context, timerService, child) {
                if (timerService.hasStarted) {
                  return Column(
                    children: [
                      _buildTimerControlsCard(),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildWelcomeCard(widget.username, streak),
            const SizedBox(height: 20),
            _buildTodayStats(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.strongCartoonShadow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).pushNamed(
              '/checkin',
              arguments: widget.uid,
            );
            await _loadStats();
            await _loadRecentActivities(); // Reload activities after check-in
          },
          backgroundColor: AppTheme.orangeAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: AppTheme.brownPrimary,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  // Add timer controls card widget
  Widget _buildTimerControlsCard() {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return Container(
          width: double.infinity,
          child: CartoonBox(
            backgroundColor: Colors.white,
            borderColor: AppTheme.brownPrimary,
            borderWidth: 3,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: timerService.isRunning 
                            ? AppTheme.greenAccent.withOpacity(0.1) 
                            : AppTheme.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: timerService.isRunning 
                              ? AppTheme.greenAccent.withOpacity(0.3) 
                              : AppTheme.orangeAccent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        timerService.isRunning ? Icons.timer : Icons.pause,
                        color: timerService.isRunning 
                            ? AppTheme.greenAccent 
                            : AppTheme.orangeAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Timer',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brownPrimary,
                            ),
                          ),
                          Text(
                            timerService.formatTime(),
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.orangeAccent,
                            ),
                          ),
                          Text(
                            timerService.getTimerStatus(),
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.brownPrimary?.withOpacity(0.6) ?? Colors.brown.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: timerService.isRunning 
                            ? AppTheme.greenAccent 
                            : AppTheme.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (timerService.isRunning)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => timerService.pauseTimer(),
                            icon: const Icon(Icons.pause, size: 18),
                            label: Text(
                              'Pause',
                              style: GoogleFonts.bubblegumSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orangeAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            boxShadow: AppTheme.strongCartoonShadow,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => timerService.resumeTimer(),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(
                              'Resume',
                              style: GoogleFonts.bubblegumSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.greenAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          boxShadow: AppTheme.strongCartoonShadow,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/poop_timer',
                              arguments: {
                                'uid': widget.uid,
                                'username': widget.username,
                              },
                            );
                          },
                          icon: const Icon(Icons.launch, size: 18),
                          label: Text(
                            'Open Timer',
                            style: GoogleFonts.bubblegumSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brownPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(String username, int streak) {
    return Container(
      width: double.infinity, // Make it full width
      child: CartoonBox(
        backgroundColor: AppTheme.orangeAccent,
        borderColor: AppTheme.brownPrimary,
        borderWidth: 3,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning, $username!',
              style: GoogleFonts.bubblegumSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How are you feeling today?',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(20, 15),
                      topRight: Radius.elliptical(15, 20),
                      bottomLeft: Radius.elliptical(15, 20),
                      bottomRight: Radius.elliptical(20, 15),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '$streak day streak!',
                        style: GoogleFonts.bubblegumSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add motivational quote or tip
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Text(
                      'Keep it up!',
                      style: GoogleFonts.bubblegumSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Grid layout for multiple stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              title: 'Check-ins',
              value: checkinCount.toString(),
              icon: Icons.check_circle,
              color: AppTheme.greenAccent,
            ),
            _buildStatCard(
              title: 'Current Streak',
              value: streak.toString(),
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Weekly Goal',
              value: '${(checkinCount * 7).clamp(0, 7)}/7', // Assuming daily goal
              icon: Icons.flag,
              color: AppTheme.orangeAccent,
            ),
            _buildStatCard(
              title: 'Health Score',
              value: _calculateHealthScore().toString(),
              icon: Icons.health_and_safety,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar for weekly goal
        _buildWeeklyProgressCard(),
      ],
    );
  }

Widget _buildWeeklyProgressCard() {
    double weeklyProgress = (checkinCount / 7).clamp(0.0, 1.0);
    
    return CartoonBox(
      backgroundColor: Colors.white,
      borderColor: AppTheme.brownPrimary,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownPrimary,
                ),
              ),
              Text(
                '${(weeklyProgress * 100).toInt()}%',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: FractionallySizedBox(
              widthFactor: weeklyProgress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.greenAccent, AppTheme.orangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep going! You\'re doing great this week.',
            style: GoogleFonts.bubblegumSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.brownPrimary?.withOpacity(0.7) ?? Colors.brown.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to calculate a simple health score
  int _calculateHealthScore() {
    // Simple calculation based on streak and check-ins
    int score = (streak * 10 + checkinCount * 5).clamp(0, 100);
    return score;
  }

  Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return CartoonBox(
    backgroundColor: Colors.white,
    borderColor: AppTheme.brownPrimary,
    borderWidth: 3,
    padding: const EdgeInsets.all(16), // Reduced padding
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center content
      mainAxisSize: MainAxisSize.min, // Take minimum space needed
      children: [
        Container(
          padding: const EdgeInsets.all(8), // Reduced padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 28), // Slightly smaller icon
        ),
        const SizedBox(height: 8), // Reduced spacing
        Flexible( // Allow text to shrink if needed
          child: Text(
            value,
            style: GoogleFonts.bubblegumSans(
              fontSize: 24, // Reduced from 32
              fontWeight: FontWeight.w800,
              color: AppTheme.brownPrimary,
              letterSpacing: 1.0, // Reduced letter spacing
            ),
            overflow: TextOverflow.ellipsis, // Handle overflow
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 4),
        Flexible( // Allow title to wrap or shrink
          child: Text(
            title,
            style: GoogleFonts.bubblegumSans(
              fontSize: 12, // Reduced from 16
              fontWeight: FontWeight.w600,
              color: AppTheme.brownPrimary?.withOpacity(0.7) ?? Colors.brown.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2, // Allow title to wrap to 2 lines
          ),
        ),
      ],
    ),
  );
}

  Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quick Actions',
        style: GoogleFonts.bubblegumSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.brownPrimary,
        ),
      ),
      const SizedBox(height: 16),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildActionCard(
            title: 'Timer',
            imagePath: 'assets/images/timer.png', // Replace with your image path
            onTap: () => Navigator.of(context).pushNamed('/poop_timer', arguments: {
              'uid': widget.uid,
              'username': widget.username,
            }),
          ),
          _buildActionCard(
            title: 'Friends',
            imagePath: 'assets/images/friendss.png', // Replace with your image path
            onTap: () => Navigator.of(context).pushNamed('/friends_screen', arguments: widget.uid),
          ),
          _buildActionCard(
            title: 'Game',
            imagePath: 'assets/images/game.png', // Replace with your image path
            onTap: () => Navigator.of(context).pushNamed('/game_menu_screen', arguments: {
              'uid': widget.uid,
              'username': widget.username,
            }),
          ),
          _buildActionCard(
            title: 'Leaderboard',
            imagePath: 'assets/images/leaderboard.png', // You already use this in bottom nav
            onTap: () => Navigator.of(context).pushNamed('/leaderboard', arguments: widget.uid),
          ),
          _buildActionCard(
            title: 'Feed',
            imagePath: 'assets/images/social.png', // Replace with your image path
            onTap: () => Navigator.of(context).pushNamed('/feed_screen', arguments: widget.uid),
          ),
          _buildActionCard(
            title: 'Assistant',
            imagePath: 'assets/images/assistant.png', // Replace with your image path
            onTap: () => Navigator.of(context).pushNamed('/chatbox_screen'),
          ),
        ],
      ),
    ],
  );
}
  Widget _buildActionCard({
  required String title,
  required String imagePath, // Changed from IconData icon to String imagePath
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CartoonBox(
      backgroundColor: Colors.white,
      borderColor: AppTheme.brownPrimary,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(8), // Reduced padding to prevent overflow
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.orangeAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Image.asset(
              imagePath,
              width: 36, // Set explicit width
              height: 36, // Set explicit height
              fit: BoxFit.contain, // Ensure image fits within bounds
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image fails to load
                return Icon(
                  Icons.help_outline,
                  color: AppTheme.orangeAccent,
                  size: 24,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.bubblegumSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.brownPrimary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.bubblegumSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to profile screen's Recent tab
                Navigator.of(context).pushNamed('/profile', arguments: {
                  'uid': widget.uid,
                  'username': widget.username,
                  'initialTab': 1, // Index for Recent tab
                });
              },
              child: Text(
                'View All',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.orangeAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CartoonBox(
          backgroundColor: Colors.white,
          borderColor: AppTheme.brownPrimary,
          borderWidth: 3,
          padding: const EdgeInsets.all(20),
          child: isLoadingActivities 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : recentActivities.isEmpty
              ? Column(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking to see your activities here!',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (int i = 0; i < recentActivities.length; i++) ...[
                      _buildActivityItem(
                        recentActivities[i]['title'],
                        _getRelativeTime(recentActivities[i]['timestamp']),
                        recentActivities[i]['icon'],
                        recentActivities[i]['color'],
                        description: recentActivities[i]['description'],
                      ),
                      if (i < recentActivities.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(thickness: 1.5),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    String? description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.bubblegumSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownPrimary,
                  fontSize: 15,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.brownPrimary?.withOpacity(0.6) ?? Colors.brown.withOpacity(0.6),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.brownPrimary?.withOpacity(0.6) ?? Colors.brown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE8E0D4), // Darker cream background
      border: Border(
        top: BorderSide(
          color: AppTheme.borderColor,
          width: 2,
        ),
      ),
    ),
    child: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 1:
            Navigator.of(context).pushNamed('/friends_screen', arguments: widget.uid);
            break;
          case 2:
            Navigator.of(context).pushNamed('/leaderboard', arguments: widget.uid);
            break;
          case 3:
            Navigator.of(context).pushNamed('/profile', arguments: {
              'uid': widget.uid,
              'username': widget.username,
            });
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      selectedItemColor: AppTheme.brownPrimary,
      unselectedItemColor: Colors.grey[500],
      elevation: 0,
      selectedLabelStyle: GoogleFonts.bubblegumSans(
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.bubblegumSans(
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
      items: [
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/home.png',
            width: 26,
            height: 26,
            color: _currentIndex == 0 ? AppTheme.brownPrimary : Colors.grey[500],
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/friends.png',
            width: 26,
            height: 26,
            color: _currentIndex == 1 ? AppTheme.brownPrimary : Colors.grey[500],
          ),
          label: 'Friends',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/winner.png',
            width: 26,
            height: 26,
            color: _currentIndex == 2 ? AppTheme.brownPrimary : Colors.grey[500],
          ),
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/poop.png',
            width: 26,
            height: 26,
            color: _currentIndex == 3 ? AppTheme.brownPrimary : Colors.grey[500],
          ),
          label: 'Profile',
        ),
      ],
    ),
  );
}
}