import 'package:flutter/material.dart';
import 'dart:async';

class UserTimerData {
  Timer? timer;
  DateTime? startTime;
  DateTime? pausedTime;
  int secondsElapsed = 0;
  int pausedSeconds = 0;
  bool isRunning = false;
  bool hasStarted = false;
  String selectedQuality = 'Normal 😐';
  double selectedSize = 3.0;
  String notes = '';
}

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final Map<String, UserTimerData> _userTimers = {};
  String _currentUserId = '';
  String _currentUsername = '';

  // Get current user's timer data
  UserTimerData get _currentUserData {
    if (!_userTimers.containsKey(_currentUserId)) {
      _userTimers[_currentUserId] = UserTimerData();
    }
    return _userTimers[_currentUserId]!;
  }

  // Getters
  int get secondsElapsed => _currentUserData.secondsElapsed;
  bool get isRunning => _currentUserData.isRunning;
  bool get hasStarted => _currentUserData.hasStarted;
  String get username => _currentUsername;
  String get uid => _currentUserId;
  String get selectedQuality => _currentUserData.selectedQuality;
  double get selectedSize => _currentUserData.selectedSize;
  String get notes => _currentUserData.notes;
  DateTime? get startTime => _currentUserData.startTime;

  // Setters for session data
  set selectedQuality(String quality) {
    _currentUserData.selectedQuality = quality;
    notifyListeners();
  }

  set selectedSize(double size) {
    _currentUserData.selectedSize = size;
    notifyListeners();
  }

  set notes(String notes) {
    _currentUserData.notes = notes;
    notifyListeners();
  }

  void initializeSession(String uid, String username) {
    _currentUserId = uid;
    _currentUsername = username;
    
    // Ensure user has timer data
    if (!_userTimers.containsKey(uid)) {
      _userTimers[uid] = UserTimerData();
    }
    
    notifyListeners();
  }

  // NEW: User logout method
  void logoutUser(String uid) {
    // Get the user's timer data
    final userData = _userTimers[uid];
    
    if (userData != null) {
      // Stop and clean up the timer
      userData.timer?.cancel();
      
      // Reset all timer data for this user
      userData.secondsElapsed = 0;
      userData.pausedSeconds = 0;
      userData.isRunning = false;
      userData.hasStarted = false;
      userData.startTime = null;
      userData.pausedTime = null;
      userData.selectedQuality = 'Normal 😐';
      userData.selectedSize = 3.0;
      userData.notes = '';
      
      // Remove the user's timer data completely
      _userTimers.remove(uid);
    }
    
    // If this was the current user, clear current user data
    if (_currentUserId == uid) {
      _currentUserId = '';
      _currentUsername = '';
    }
    
    notifyListeners();
  }

  // NEW: Complete logout (clears all data and resets service)
  void completeLogout() {
    // Stop all timers
    for (final userData in _userTimers.values) {
      userData.timer?.cancel();
    }
    
    // Clear all user data
    _userTimers.clear();
    _currentUserId = '';
    _currentUsername = '';
    
    notifyListeners();
  }

  void startTimer() {
    final userData = _currentUserData;
    
    if (!userData.hasStarted) {
      userData.startTime = DateTime.now();
      userData.hasStarted = true;
      userData.secondsElapsed = 0;
      userData.pausedSeconds = 0;
    }
    
    userData.isRunning = true;
    userData.timer = Timer.periodic(Duration(seconds: 1), (timer) {
      userData.secondsElapsed++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    final userData = _currentUserData;
    userData.timer?.cancel();
    userData.isRunning = false;
    userData.pausedTime = DateTime.now();
    userData.pausedSeconds = userData.secondsElapsed;
    notifyListeners();
  }

  void resumeTimer() {
    final userData = _currentUserData;
    if (userData.hasStarted && !userData.isRunning) {
      userData.isRunning = true;
      userData.timer = Timer.periodic(Duration(seconds: 1), (timer) {
        userData.secondsElapsed++;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void stopTimer() {
    final userData = _currentUserData;
    userData.timer?.cancel();
    userData.isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    final userData = _currentUserData;
    userData.timer?.cancel();
    userData.secondsElapsed = 0;
    userData.pausedSeconds = 0;
    userData.isRunning = false;
    userData.hasStarted = false;
    userData.startTime = null;
    userData.pausedTime = null;
    userData.selectedQuality = 'Normal 😐';
    userData.selectedSize = 3.0;
    userData.notes = '';
    notifyListeners();
  }

  String formatTime() {
    final userData = _currentUserData;
    int minutes = userData.secondsElapsed ~/ 60;
    int seconds = userData.secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Calculate actual elapsed time considering app lifecycle
  void _recalculateElapsedTime() {
    final userData = _currentUserData;
    if (userData.startTime != null && userData.isRunning) {
      final now = DateTime.now();
      final actualElapsed = now.difference(userData.startTime!).inSeconds;
      userData.secondsElapsed = actualElapsed;
      notifyListeners();
    }
  }

  // Handle app lifecycle changes
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    final userData = _currentUserData;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is going to background
        if (userData.isRunning) {
          // Don't pause the timer, but stop the UI updates
          userData.timer?.cancel();
        }
        break;
      case AppLifecycleState.resumed:
        // App is coming back from background
        if (userData.hasStarted && userData.isRunning) {
          // Recalculate elapsed time based on actual time passed
          _recalculateElapsedTime();
          // Restart the UI update timer
          userData.timer = Timer.periodic(Duration(seconds: 1), (timer) {
            _recalculateElapsedTime();
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Handle inactive/hidden states if needed
        break;
    }
  }

  // Get session data for saving
  Map<String, dynamic> getSessionData() {
    final userData = _currentUserData;
    final now = DateTime.now();
    return {
      'userId': _currentUserId,
      'username': _currentUsername,
      'duration': userData.secondsElapsed,
      'quality': userData.selectedQuality,
      'size': userData.selectedSize.toInt(),
      'notes': userData.notes,
      'timestamp': now.toIso8601String(),
      'dateOnly': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'startTime': userData.startTime?.toIso8601String(),
    };
  }

  // Get timer status for UI
  String getTimerStatus() {
    final userData = _currentUserData;
    if (!userData.hasStarted) return 'Ready to Start';
    if (userData.isRunning) return 'In Progress...';
    return 'Paused';
  }

  // Check if timer has been running for a long time (for notifications)
  bool get isLongSession => _currentUserData.secondsElapsed > 300; // 5 minutes

  // Get all active timers (for debugging or admin purposes)
  Map<String, UserTimerData> get allUserTimers => Map.unmodifiable(_userTimers);

  // Clean up inactive timers (optional - call this periodically)
  void cleanupInactiveTimers() {
    final now = DateTime.now();
    _userTimers.removeWhere((userId, userData) {
      // Remove timers that haven't been used in 24 hours and aren't running
      if (!userData.isRunning && 
          userData.startTime != null && 
          now.difference(userData.startTime!).inHours > 24) {
        userData.timer?.cancel();
        return true;
      }
      return false;
    });
  }

  // Switch to a different user's timer
  void switchUser(String uid, String username) {
    // Stop current user's timer UI updates but keep the timer running
    final currentUserData = _userTimers[_currentUserId];
    if (currentUserData?.isRunning == true) {
      currentUserData?.timer?.cancel();
      // Timer continues running in background via _recalculateElapsedTime
    }
    
    // Switch to new user
    initializeSession(uid, username);
    
    // If new user has a running timer, restart UI updates
    final newUserData = _currentUserData;
    if (newUserData.isRunning && newUserData.hasStarted) {
      _recalculateElapsedTime();
      newUserData.timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _recalculateElapsedTime();
      });
    }
  }

  // NEW: Check if a specific user has an active timer
  bool userHasActiveTimer(String uid) {
    final userData = _userTimers[uid];
    return userData?.hasStarted ?? false;
  }

  // NEW: Get timer info for a specific user
  Map<String, dynamic>? getUserTimerInfo(String uid) {
    final userData = _userTimers[uid];
    if (userData == null || !userData.hasStarted) return null;
    
    return {
      'isRunning': userData.isRunning,
      'secondsElapsed': userData.secondsElapsed,
      'hasStarted': userData.hasStarted,
      'formattedTime': _formatTime(userData.secondsElapsed),
    };
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final userData in _userTimers.values) {
      userData.timer?.cancel();
    }
    _userTimers.clear();
    super.dispose();
  }
}