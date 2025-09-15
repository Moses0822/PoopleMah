import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/timer_service.dart';
import '../Theme.dart';

class TimerStatusWidget extends StatelessWidget {
  const TimerStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        // Check if current user has a timer, if not check for any active timers
        bool hasActiveTimer = timerService.hasStarted;
        String displayUid = timerService.uid;
        String displayUsername = timerService.username;
        
        // If current user doesn't have an active timer, check for any running timers
        if (!hasActiveTimer) {
          final activeTimer = _findAnyActiveTimer(timerService);
          if (activeTimer != null) {
            hasActiveTimer = true;
            displayUid = activeTimer['uid']!;
            displayUsername = activeTimer['username']!;
            // Temporarily switch to show the active timer
            timerService.switchUser(displayUid, displayUsername);
          }
        }
        
        if (!hasActiveTimer) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: () {
            // Navigate back to timer screen
            Navigator.pushNamed(
              context,
              '/poop_timer',
              arguments: {
                'uid': displayUid,
                'username': displayUsername,
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timerService.isRunning 
                  ? AppTheme.greenAccent 
                  : AppTheme.orangeAccent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.brownPrimary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💩 ', style: TextStyle(fontSize: 16)),
                Icon(
                  timerService.isRunning ? Icons.timer : Icons.pause,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  timerService.formatTime(),
                  style: GoogleFonts.bubblegumSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                // Show initials if different user
                if (displayUid != timerService.uid) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayUsername.isNotEmpty ? displayUsername[0].toUpperCase() : '?',
                      style: GoogleFonts.bubblegumSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  // Helper method to find any active timer across all users
  Map<String, String>? _findAnyActiveTimer(TimerService timerService) {
    final allTimers = timerService.allUserTimers;
    
    for (final entry in allTimers.entries) {
      final userId = entry.key;
      final userData = entry.value;
      
      if (userData.hasStarted && userData.isRunning) {
        // Try to get username - you might need to store this in UserTimerData
        // For now, we'll use a placeholder
        return {
          'uid': userId,
          'username': 'User', // You'd need to store actual username in UserTimerData
        };
      }
    }
    
    // Check for paused timers if no running ones found
    for (final entry in allTimers.entries) {
      final userId = entry.key;
      final userData = entry.value;
      
      if (userData.hasStarted) {
        return {
          'uid': userId,
          'username': 'User',
        };
      }
    }
    
    return null;
  }
}

// Timer controls card for home screen - shows current user's timer
class TimerControlsCard extends StatelessWidget {
  const TimerControlsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        if (!timerService.hasStarted) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.brownPrimary, width: 2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: AppTheme.strongCartoonShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('💩', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${timerService.username}\'s Timer',
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brownPrimary,
                            ),
                          ),
                          Text(
                            timerService.formatTime(),
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.orangeAccent,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (timerService.isRunning)
                      ElevatedButton.icon(
                        onPressed: () => timerService.pauseTimer(),
                        icon: const Icon(Icons.pause, size: 16),
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
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => timerService.resumeTimer(),
                        icon: const Icon(Icons.play_arrow, size: 16),
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
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: AppTheme.brownPrimary, width: 2),
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/poop_timer',
                          arguments: {
                            'uid': timerService.uid,
                            'username': timerService.username,
                          },
                        );
                      },
                      icon: const Icon(Icons.launch, size: 16),
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
                          borderRadius: BorderRadius.circular(20),
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
}

// Alternative: Multi-user timer overview widget
class AllActiveTimersWidget extends StatelessWidget {
  const AllActiveTimersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        final activeTimers = _getActiveTimers(timerService);
        
        if (activeTimers.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.brownPrimary, width: 2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: AppTheme.strongCartoonShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Timers',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brownPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...activeTimers.map((timer) => _buildTimerRow(context, timer)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getActiveTimers(TimerService timerService) {
    final List<Map<String, dynamic>> activeTimers = [];
    final allTimers = timerService.allUserTimers;
    
    for (final entry in allTimers.entries) {
      final userId = entry.key;
      final userData = entry.value;
      
      if (userData.hasStarted) {
        activeTimers.add({
          'uid': userId,
          'userData': userData,
          'username': 'User $userId', // You'd store actual username in UserTimerData
        });
      }
    }
    
    return activeTimers;
  }

  Widget _buildTimerRow(BuildContext context, Map<String, dynamic> timer) {
    final userData = timer['userData'];
    final username = timer['username'];
    final uid = timer['uid'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0DCC8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brownPrimary, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: userData.isRunning 
                  ? AppTheme.greenAccent 
                  : AppTheme.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.bubblegumSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.brownPrimary,
                  ),
                ),
                Text(
                  _formatTime(userData.secondsElapsed),
                  style: GoogleFonts.bubblegumSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/poop_timer',
                arguments: {
                  'uid': uid,
                  'username': username,
                },
              );
            },
            icon: const Icon(Icons.launch, size: 16),
            color: AppTheme.brownPrimary,
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}