import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/services/timer_service.dart';
import 'package:provider/provider.dart';
import '../db_helper.dart';
import '../Theme.dart';
import 'dart:math' as math;
import '../screens/edit_profile_screen.dart';

// CartoonBorderPainter class
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

// CartoonBox widget
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

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String username;
  final int? initialTab;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.username,
    this.initialTab,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic> userStats = {
    'totalCheckins': 0,
    'averageFeeling': 0.0,
    'mostCommonType': null,
    'currentStreak': 0,
    'totalSessions': 0,
    'averageDuration': 0.0,
    'totalTime': 0,
    'averageSize': 0.0,
    'mostCommonQuality': null,
  };
  
  List<Map<String, dynamic>> recentCheckins = [];
  List<Map<String, dynamic>> recentTimerSessions = [];
  bool isLoading = true;
  
  String displayName = '';
  String email = '';
  DateTime? joinDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    displayName = widget.username;
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        email = user.email ?? '';
        joinDate = user.metadata.creationTime;
      }

      final dbHelper = DBHelper();
      final combinedStats = await dbHelper.getCombinedStats(widget.uid);
      final recentCheckinsData = await dbHelper.getRecentCheckins(widget.uid, 7);
      final recentTimerData = await dbHelper.getRecentTimerSessions(widget.uid, 7);
      
      userStats = {
        'totalCheckins': (combinedStats['totalCheckins'] ?? 0).toInt(),
        'averageFeeling': (combinedStats['averageFeeling'] ?? 0.0).toDouble(),
        'mostCommonType': combinedStats['mostCommonType'],
        'currentStreak': await _calculateStreak(),
        'totalSessions': (combinedStats['totalSessions'] ?? 0).toInt(),
        'averageDuration': (combinedStats['averageDuration'] ?? 0.0).toDouble(),
        'totalTime': (combinedStats['totalTime'] ?? 0).toInt(),
        'averageSize': (combinedStats['averageSize'] ?? 0.0).toDouble(),
        'mostCommonQuality': combinedStats['mostCommonQuality'],
        'totalActivities': (combinedStats['totalActivities'] ?? 0).toInt(),
      };
      
      recentCheckins = recentCheckinsData ?? [];
      recentTimerSessions = recentTimerData ?? [];
      
    } catch (e) {
      print('Error loading profile data: $e');
      userStats = {
        'totalCheckins': 0,
        'averageFeeling': 0.0,
        'mostCommonType': null,
        'currentStreak': 0,
        'totalSessions': 0,
        'averageDuration': 0.0,
        'totalTime': 0,
        'averageSize': 0.0,
        'mostCommonQuality': null,
        'totalActivities': 0,
      };
      recentCheckins = [];
      recentTimerSessions = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int> _calculateStreak() async {
    return 7; // Mock value
  }

  Future<void> _logout() async {
  final timerService = Provider.of<TimerService>(context, listen: false);
  
  // Check if user has an active timer and modify the dialog content
  String dialogContent = 'Are you sure you want to logout?';
  if (timerService.hasStarted) {
    dialogContent = 'You have an active timer running (${timerService.formatTime()}). '
                   'Logging out will reset your timer. Are you sure you want to logout?';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          width: 2.5,
        ),
      ),
      title: Row(
        children: [
          Text(
            'Logout',
            style: GoogleFonts.bubblegumSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
            ),
          ),
          // Show warning icon if timer is active
          if (timerService.hasStarted) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.timer,
              color: AppTheme.orangeAccent ?? Colors.orange,
              size: 20,
            ),
          ],
        ],
      ),
      content: Text(
        dialogContent,
        style: GoogleFonts.bubblegumSans(
          fontSize: 16,
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        ),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              width: 2,
            ),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.brownPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              width: 2,
            ),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // Clean up timer data for the current user before logout
    if (timerService.uid.isNotEmpty) {
      timerService.logoutUser(timerService.uid);
    }
    
    await FirebaseAuth.instance.signOut();
    
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brownPrimary,
                ),
              ),
              const SizedBox(height: 20),
             ListTile(
              leading: Icon(Icons.person, color: AppTheme.brownPrimary ?? const Color(0xFF8B4513)),
              title: Text(
                'Edit Profile',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brownPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet first
                
                // Navigate to edit profile screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      uid: widget.uid,
                      currentUsername: displayName,
                    ),
                  ),
                );
                
                // If the username was updated, refresh the profile data
                if (result != null && result is String) {
                  setState(() {
                    displayName = result;
                  });
                  // Optionally reload all profile data
                  _loadProfileData();
                }
              },
            ),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: AppTheme.brownPrimary ?? const Color(0xFF8B4513)),
                title: Text(
                  'Privacy',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brownPrimary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyBottomSheet();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Privacy & Policies',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPrivacySection(
                    title: 'Privacy Policy',
                    icon: Icons.shield_outlined,
                    content: _getPrivacyPolicyContent(),
                  ),
                  const SizedBox(height: 24),
                  _buildPrivacySection(
                    title: 'Data Usage Policy',
                    icon: Icons.data_usage_outlined,
                    content: _getDataUsagePolicyContent(),
                  ),
                  const SizedBox(height: 24),
                  _buildPrivacySection(
                    title: 'Terms of Service',
                    icon: Icons.description_outlined,
                    content: _getTermsOfServiceContent(),
                  ),
                  const SizedBox(height: 24),
                  _buildPrivacySection(
                    title: 'Contact & Support',
                    icon: Icons.support_agent_outlined,
                    content: _getContactSupportContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return CartoonBox(
      backgroundColor: Colors.white,
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 2.5,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brownPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.bubblegumSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getPrivacyPolicyContent() {
    return '''We are committed to protecting your privacy and personal information. This health tracking app collects and processes your health data locally on your device.

Data Collection:
• Health check-in information (stool types, feelings, timestamps)
• Timer session data (duration, ratings, quality assessments)
• User profile information (username, email)

Data Storage:
• All health data is stored securely on your device
• Cloud backup is encrypted and anonymized
• No personal health information is shared with third parties

Data Usage:
• Information is used solely for providing personalized health insights
• Aggregate anonymous data may be used to improve app functionality
• You can request data deletion at any time

Your data, your control.''';
  }

  String _getDataUsagePolicyContent() {
    return '''Our app processes your health data to provide valuable insights and tracking capabilities.

How We Use Your Data:
• Generate personalized health statistics and trends
• Provide reminders and notifications (if enabled)
• Create backup copies for data recovery
• Improve app performance and user experience

Data Processing:
• All processing happens locally on your device
• No AI models or external services access your raw health data
• Statistical analysis is performed anonymously
• Data is never sold or shared for commercial purposes

Third-Party Services:
• Firebase Authentication for secure login
• Google Fonts for typography (no data shared)
• No analytics or tracking services are used

You maintain full ownership and control of your health data.''';
  }

  String _getTermsOfServiceContent() {
    return '''By using this health tracking application, you agree to the following terms:

App Purpose:
• This app is designed for personal health tracking and wellness monitoring
• It is not intended as a substitute for professional medical advice
• Always consult healthcare professionals for medical concerns

User Responsibilities:
• Provide accurate information for better insights
• Use the app responsibly and appropriately
• Keep your account credentials secure
• Report any bugs or issues promptly

Limitations:
• Health insights are based on user-provided data only
• The app cannot diagnose medical conditions
• Results should be discussed with healthcare providers
• We are not liable for decisions made based on app data

Account Management:
• You can delete your account and data at any time
• Inactive accounts may be cleaned up after extended periods
• Account sharing is not recommended for privacy reasons

Updates and Changes:
• Terms may be updated periodically with app updates
• Continued use implies acceptance of updated terms''';
  }

  String _getContactSupportContent() {
    return '''Need help or have questions about privacy and data usage?

Support Options:
• Email support: support@healthtracker.app
• Privacy questions: privacy@healthtracker.app

Response Time:
• General inquiries: 24-48 hours
• Privacy concerns: 12-24 hours
• Technical issues: 48-72 hours

Data Rights:
• Request data export (JSON format)
• Request data deletion (permanent)
• Update privacy preferences
• Report data concerns

App Information:
• Version: 1.0.0
• Last updated: September 2025
• Privacy compliance: GDPR, CCPA

We're here to help ensure your privacy and data are protected while you focus on your health and wellness journey.''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0DCC8), // Same as HomeScreen
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(),
              ],
              body: _buildTabBarView(),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      title: Text(
        'Profile',
        style: GoogleFonts.bubblegumSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _showSettingsBottomSheet,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: CartoonBox(
          backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
          borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          borderWidth: 3,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight),
                _buildProfileHeader(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(),
            indicatorColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            dividerColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelStyle: GoogleFonts.bubblegumSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.bubblegumSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Stats', icon: Icon(Icons.analytics, size: 20)),
              Tab(text: 'Recent', icon: Icon(Icons.history, size: 20)),
              Tab(text: 'Achievements', icon: Icon(Icons.emoji_events, size: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: GoogleFonts.bubblegumSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (joinDate != null)
                Text(
                  'Member since ${joinDate!.day}/${joinDate!.month}/${joinDate!.year}',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildStatsTab(),
        _buildRecentTab(),
        _buildAchievementsTab(),
      ],
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
      children: [
        _buildDetailedStatsCard(),
        const SizedBox(height: 16),
        _buildTimerStatsCard(),
        const SizedBox(height: 16),
        _buildHealthInsightsCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailedStatsCard() {
    final totalCheckins = userStats['totalCheckins'] as int;
    final averageFeeling = userStats['averageFeeling'] as double;
    final mostCommonType = userStats['mostCommonType'];
    
    return CartoonBox(
      backgroundColor: Colors.white,
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check-in Statistics',
            style: GoogleFonts.bubblegumSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Check-ins', '$totalCheckins', Icons.assignment_turned_in),
          _buildStatRow('Average Feeling', '${averageFeeling.toStringAsFixed(1)}/5.0', Icons.mood),
          _buildStatRow('Most Common Type', 
              mostCommonType != null 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppTheme.getStoolTypeImage(mostCommonType),
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              AppTheme.getStoolTypeEmoji(mostCommonType),
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brownPrimary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Type ${mostCommonType + 1}',
                          style: GoogleFonts.bubblegumSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brownPrimary,
                          ),
                        ),
                      ],
                    )
                  : 'No data', 
              Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildTimerStatsCard() {
    final totalSessions = userStats['totalSessions'] as int;
    final averageDuration = userStats['averageDuration'] as double;
    final totalTime = userStats['totalTime'] as int;
    final averageSize = userStats['averageSize'] as double;
    final mostCommonQuality = userStats['mostCommonQuality'];
    
    return CartoonBox(
      backgroundColor: AppTheme.warmYellow ?? const Color(0xFFFFF8DC),
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppTheme.funnyEmojis['timer'] ?? '⏱', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Timer Statistics',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brownPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Timer Sessions', '$totalSessions', Icons.timer),
          _buildStatRow('Average Duration', 
              averageDuration > 0 
                  ? AppTheme.formatDuration(averageDuration)
                  : 'No data', 
              Icons.schedule),
          _buildStatRow('Total Time Tracked', 
              totalTime > 0 
                  ? AppTheme.formatTotalTime(totalTime)
                  : 'No data', 
              Icons.access_time),
          _buildStatRow('Average Size Rating', 
              averageSize > 0 
                  ? '${averageSize.toStringAsFixed(1)}/5.0'
                  : 'No data', 
              Icons.straighten),
          _buildStatRow('Most Common Quality', 
              mostCommonQuality != null 
                  ? '${AppTheme.getQualityEmoji(mostCommonQuality)} ${mostCommonQuality.split(' ')[0]}'
                  : 'No data', 
              Icons.sentiment_satisfied),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brownPrimary ?? const Color(0xFF8B4513)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.8),
              ),
            ),
          ),
          if (value is String)
            Text(
              value,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            )
          else if (value is Widget)
            value,
        ],
      ),
    );
  }

  Widget _buildHealthInsightsCard() {
    return CartoonBox(
      backgroundColor: AppTheme.softGreen ?? const Color(0xFF90EE90),
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Health Insights',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brownPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightTile(
            'Current Streak',
            '${userStats['currentStreak']} days',
            Icons.local_fire_department,
            Colors.orange,
          ),
          _buildInsightTile(
            'Weekly Trend',
            _getWeeklyTrend(),
            Icons.trending_up,
            Colors.green,
          ),
          _buildInsightTile(
            'Health Score',
            _calculateHealthScore(),
            Icons.health_and_safety,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 12,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brownPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recentCheckins.isNotEmpty) ...[
          Text(
            'Recent Check-ins',
            style: GoogleFonts.bubblegumSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...recentCheckins.map((checkin) => _buildRecentCheckinCard(checkin)),
          const SizedBox(height: 24),
        ],
        if (recentTimerSessions.isNotEmpty) ...[
          Text(
            'Recent Timer Sessions',
            style: GoogleFonts.bubblegumSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...recentTimerSessions.map((session) => _buildRecentTimerCard(session)),
        ],
        if (recentCheckins.isEmpty && recentTimerSessions.isEmpty) ...[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text('📝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking to see your recent activities here',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 14,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentCheckinCard(Map<String, dynamic> checkin) {
    final date = DateTime.parse(checkin['timestamp']);
    final stoolType = checkin['stoolType'];
    final feeling = checkin['feelingRating'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CartoonBox(
        backgroundColor: Colors.white,
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 2.5,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: stoolType != null && stoolType >= 0 && stoolType < 7
                    ? Image.asset(
                        AppTheme.getStoolTypeImage(stoolType),
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.help_outline,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type ${(stoolType ?? 0) + 1} Check-in',
                    style: GoogleFonts.bubblegumSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feeling: $feeling/5',
                    style: GoogleFonts.bubblegumSans(
                      color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppTheme.formatDate(date),
                    style: GoogleFonts.bubblegumSans(
                      color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTimerCard(Map<String, dynamic> session) {
    final date = DateTime.parse(session['timestamp']);
    final duration = (session['duration'] ?? 0.0).toDouble();
    final sizeRating = session['sizeRating'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CartoonBox(
        backgroundColor: AppTheme.warmYellow ?? const Color(0xFFFFF8DC),
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 2.5,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('⏱', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timer Session',
                    style: GoogleFonts.bubblegumSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${AppTheme.formatDuration(duration)}',
                    style: GoogleFonts.bubblegumSans(
                      color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sizeRating != null)
                    Text(
                      'Size: $sizeRating/5',
                      style: GoogleFonts.bubblegumSans(
                        color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    AppTheme.formatDate(date),
                    style: GoogleFonts.bubblegumSans(
                      color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = _getAchievements();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Your Achievements',
          style: GoogleFonts.bubblegumSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (achievements.isNotEmpty)
          ...achievements.map((achievement) => _buildAchievementCard(achievement))
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No achievements yet',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep tracking to unlock achievements!',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 14,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CartoonBox(
        backgroundColor: isUnlocked ? AppTheme.softGreen ?? const Color(0xFF90EE90) : Colors.grey[100]!,
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 2.5,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? Colors.yellow.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isUnlocked 
                      ? Colors.yellow.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  achievement['emoji'],
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: GoogleFonts.bubblegumSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUnlocked ? AppTheme.brownPrimary : (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    style: GoogleFonts.bubblegumSans(
                      color: isUnlocked ? (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.8) : (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (achievement['progress'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: achievement['progress'],
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked ? AppTheme.brownPrimary ?? const Color(0xFF8B4513) : Colors.grey,
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
  }

  List<Map<String, dynamic>> _getAchievements() {
    final totalCheckins = userStats['totalCheckins'] as int;
    final totalSessions = userStats['totalSessions'] as int;
    final currentStreak = userStats['currentStreak'] as int;
    
    return [
      {
        'emoji': '🎯',
        'title': 'First Steps',
        'description': 'Complete your first check-in',
        'unlocked': totalCheckins >= 1,
        'progress': totalCheckins >= 1 ? 1.0 : 0.0,
      },
      {
        'emoji': '📊',
        'title': 'Data Collector',
        'description': 'Complete 10 check-ins',
        'unlocked': totalCheckins >= 10,
        'progress': (totalCheckins / 10.0).clamp(0.0, 1.0),
      },
      {
        'emoji': '⏱',
        'title': 'Timer Novice',
        'description': 'Complete 5 timer sessions',
        'unlocked': totalSessions >= 5,
        'progress': (totalSessions / 5.0).clamp(0.0, 1.0),
      },
      {
        'emoji': '🔥',
        'title': 'Streak Master',
        'description': 'Maintain a 7-day streak',
        'unlocked': currentStreak >= 7,
        'progress': (currentStreak / 7.0).clamp(0.0, 1.0),
      },
      {
        'emoji': '💪',
        'title': 'Consistency Champion',
        'description': 'Complete 30 check-ins',
        'unlocked': totalCheckins >= 30,
        'progress': (totalCheckins / 30.0).clamp(0.0, 1.0),
      },
      {
        'emoji': '🏆',
        'title': 'Health Guru',
        'description': 'Complete 100 total activities',
        'unlocked': (totalCheckins + totalSessions) >= 100,
        'progress': ((totalCheckins + totalSessions) / 100.0).clamp(0.0, 1.0),
      },
    ];
  }

  String _getWeeklyTrend() {
    // Mock logic - in real app, calculate based on recent data
    final recentCount = recentCheckins.length;
    if (recentCount >= 5) return 'Excellent 📈';
    if (recentCount >= 3) return 'Good 📊';
    if (recentCount >= 1) return 'Getting Started 📉';
    return 'No Data 📊';
  }

  String _calculateHealthScore() {
    // Mock calculation - in real app, use complex algorithm
    final totalCheckins = userStats['totalCheckins'] as int;
    final totalSessions = userStats['totalSessions'] as int;
    final totalActivities = totalCheckins + totalSessions;
    final averageFeeling = userStats['averageFeeling'] as double;
    final currentStreak = userStats['currentStreak'] as int;
    
    if (totalActivities == 0) return 'No Data';
    
    double score = 0;
    score += (totalActivities * 0.1).clamp(0.0, 30.0); // Max 30 points for activity
    score += (averageFeeling * 10.0); // Max 50 points for feelings
    score += (currentStreak * 2.0).clamp(0.0, 20.0); // Max 20 points for streak
    
    score = score.clamp(0.0, 100.0);
    
    if (score >= 80) return 'Excellent 🌟';
    if (score >= 60) return 'Good 😊';
    if (score >= 40) return 'Fair 😐';
    return 'Needs Work 😔';
  }
}