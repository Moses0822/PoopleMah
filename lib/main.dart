import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:mad/firebase_options.dart';
import 'package:mad/screens/feed_screen.dart';
import 'package:mad/screens/profileScreen.dart';
import 'package:mad/services/timer_service.dart'; // Add this import (create this file)
import 'Theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/game_menu_screen.dart';
import 'screens/check_in.dart';
import 'screens/leaderboard.dart';
import 'screens/timer.dart';
import 'dart:ui' as ui;
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/chatbox_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  ui.PlatformDispatcher.instance.locale.toString(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log("🔥 Firebase initialization successfully！");
  runApp(const DailyPoopApp());
}

class DailyPoopApp extends StatelessWidget {
  const DailyPoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap your MaterialApp with ChangeNotifierProvider
    return ChangeNotifierProvider<TimerService>(
      create: (context) => TimerService(),
      child: MaterialApp(
        title: 'PoopLeMah 💩',
        theme: AppTheme.themeData,
        home: const SplashScreen(),
        routes: {
          '/profile': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ProfileScreen(
              uid: args['uid'] ?? '',
              username: args['username'] ?? 'Anonymous',
            );
          },
          '/checkin': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return CheckinScreen(uid: uid);
          },
          '/poop_timer': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return PoopTimerScreen(
              uid: args?['uid'] ?? '',
              username: args?['username'] ?? 'Anonymous',
            );
          },
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return HomeScreen(
              uid: args['uid'] ?? '',
              username: args['username'] ?? 'Anonymous',
            );
          },
          '/friends_screen': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return FriendsScreen(currentUserId: uid);
          },
          '/game_menu_screen': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is Map<String, String>) {
              return GameMenuScreen(
                uid: args['uid'] ?? '',
                username: args['username'] ?? 'Guest',
              );
            }
            return const GameMenuScreen(uid: '', username: 'Guest');
          },
          '/leaderboard': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return LeaderboardScreen(currentUserId: uid);
          },
          '/feed_screen': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return FeedScreen(currentUserId: uid);
          },
          '/chatbox_screen': (context) {
            final uid = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return ChatScreen(uid: uid);
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}