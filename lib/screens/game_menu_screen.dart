import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Theme.dart';
import 'poop_crush_screen.dart';
import 'tap_tap_poops_screen.dart';

class GameMenuScreen extends StatefulWidget {
  final String? uid;
  final String username;
  const GameMenuScreen({super.key, required this.uid, required this.username});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  int poopCrushHighScore = 0;
  int poopCrushMaxLevel = 1;
  int tapTapHighScore = 0;
  int tapTapMaxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAllGameData();
  }

  /// 🔹 Load all scores from SharedPreferences
  Future<void> _loadAllGameData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        poopCrushHighScore = prefs.getInt('poop_crush_high_score') ?? 0;
        poopCrushMaxLevel = prefs.getInt('poop_crush_max_level') ?? 1;
        tapTapHighScore = prefs.getInt('tap_tap_high_score') ?? 0;
        tapTapMaxStreak = prefs.getInt('tap_tap_max_streak') ?? 0;
      });
    }
  }

  /// 🔹 Save Poop Crush score & level
  Future<void> _savePoopCrushScore(int score, int level) async {
    final prefs = await SharedPreferences.getInstance();
    int currentHighScore = prefs.getInt('poop_crush_high_score') ?? 0;
    int currentMaxLevel = prefs.getInt('poop_crush_max_level') ?? 1;

    if (score > currentHighScore) {
      await prefs.setInt('poop_crush_high_score', score);
    }
    if (level > currentMaxLevel) {
      await prefs.setInt('poop_crush_max_level', level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.creamBackground,
              Colors.white,
              AppTheme.creamBackground.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section - unchanged
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppTheme.creamBackground,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.brownPrimary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brownPrimary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '💩 Mini poop game',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brownPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'Mini Games Collection',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.orangeAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.001,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brownPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Welcome, ${widget.username}',
                                style: TextStyle(
                                  color: AppTheme.brownPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.03,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Games section
              Expanded(
                flex: 5,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Poop Crush button
                      _buildGameButton(
                        context,
                        title: 'Poop Crush',
                        subtitle: 'Match-3 Adventure!',
                        highScore:
                            'Best: $poopCrushHighScore (Lv.$poopCrushMaxLevel)',
                        color: AppTheme.brownPrimary,
                        accentColor: AppTheme.orangeAccent,
                        icon: '💩',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PoopCrushGame()),
                          );

                          // 🔹 When returning, check for updated score
                          if (result is Map<String, int>) {
                            await _savePoopCrushScore(
                                result['score'] ?? 0, result['level'] ?? 1);
                          }

                          _loadAllGameData(); // refresh UI
                        },
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Tap-Tap Poops button
                      _buildGameButton(
                        context,
                        title: 'Tap-Tap Poops',
                        subtitle: 'Tap to shoot hoops!',
                        highScore:
                            'Best: $tapTapHighScore (Streak: $tapTapMaxStreak)',
                        color: AppTheme.greenAccent,
                        accentColor: AppTheme.orangeAccent,
                        icon: '🧻',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const TapTapPoopsGame()),
                          );
                          if (result == true) _loadAllGameData();
                        },
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section - unchanged
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back,
                              size: screenWidth * 0.045),
                          label: Text(
                            'Back to Main Menu',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.creamBackground,
                            foregroundColor: AppTheme.brownPrimary,
                            side: BorderSide(
                                color: AppTheme.brownPrimary.withOpacity(0.3),
                                width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.brownPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                '🏆',
                                'Total High Score',
                                (poopCrushHighScore + tapTapHighScore)
                                    .toString(),
                                screenWidth),
                            _buildStatItem(
                                '🎯',
                                'Games Played',
                                '${(poopCrushMaxLevel > 1 || tapTapMaxStreak > 0) ? "Active" : "New Player"}',
                                screenWidth),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String icon, String label, String value, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: screenWidth * 0.04)),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            color: AppTheme.brownPrimary.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: AppTheme.brownPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String highScore,
    required Color color,
    required Color accentColor,
    required String icon,
    required VoidCallback onPressed,
    required double screenHeight,
    required double screenWidth,
  }) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                  color.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(fontSize: screenWidth * 0.06),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenHeight * 0.003,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            highScore,
                            style: TextStyle(
                              fontSize: screenWidth * 0.025,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: screenWidth * 0.05,
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
