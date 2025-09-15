import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors based on PooPie screenshot - more vibrant and cartoonish
  static const Color creamBackground = Color(0xFFE0DCC8); // light cream
  static const Color brownPrimary = Color(0xFF4A3728);    // darker poop brown
  static const Color orangeAccent = Color(0xFF8D6E63);    // warm orange
  static const Color greenAccent = Color.fromARGB(255, 102, 83, 49);     // soft green
  static const Color softBlack = Color(0xFF2D2D2D);       // darker text
  static const Color cardBackground = Color(0xFFFDF5);  // slightly off-white for cards
  static const Color borderColor = Color(0xFF8B7355); 
  static const Color softGreen = Color(0xFF6FC276);   // brown border color
  static const Color lightPurple = Color(0xFFE0B0FF);
  
  // Additional colors from original profile screen theme
  static const Color primaryBrown = Color(0xFF8D6E63);
  static const Color lightBrown = Color(0xFFBCAAA4);
  static const Color textDark = Color(0xFF5D4037);
  static const Color textMedium = Color(0xFF8D6E63);
  static const Color textLight = Color(0xFFBCAAA4);
  static const Color softPink = Color(0xFFFCE4EC);
  static const Color friendlyGreen = Color(0xFFE8F5E8);
  static const Color warmYellow = Color(0xFFFFF8E1);
  static const Color playfulOrange = Color(0xFFFF9800);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F5DC), Color(0xFFEFEBE9)],
  );

  static const LinearGradient welcomeCardGradient = LinearGradient(
    colors: [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
  );

  // Custom shadows for cartoon effect
  static const List<BoxShadow> cartoonShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(2, 4),
    ),
  ];

  static const List<BoxShadow> strongCartoonShadow = [
    BoxShadow(
      color: Color(0x25000000),
      blurRadius: 12,
      offset: Offset(3, 6),
    ),
  ];

  // Card shadows from original theme
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Border radius
  static BorderRadius get irregularRadius => BorderRadius.circular(16);

  // Box decorations
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: cardShadow,
  );

  // Fun emojis
  static const Map<String, String> funnyEmojis = {
    'streak': '🔥',
    'poop': '💩',
    'happy': '😊',
    'celebration': '🎉',
    'timer': '⏱️',
    'trophy': '🏆',
  };

  // ThemeData with BubblegumSans as default font
  static ThemeData get themeData => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: creamBackground,
        primaryColor: brownPrimary,
        textTheme: GoogleFonts.bubblegumSansTextTheme(), // Apply to entire text theme
        colorScheme: const ColorScheme.light(
          primary: brownPrimary,
          secondary: Color.fromARGB(255, 85, 59, 36),
          surface: creamBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: softBlack,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: creamBackground,
          elevation: 0,
          iconTheme: const IconThemeData(color: brownPrimary, size: 28),
          titleTextStyle: GoogleFonts.bubblegumSans(
            color: brownPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: creamBackground,
          selectedItemColor: brownPrimary,
          unselectedItemColor: const Color(0xFF8B8B8B),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.bubblegumSans(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.bubblegumSans(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: borderColor,
              width: 2.5,
            ),
          ),
          shadowColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 92, 60, 32),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(
                color: brownPrimary,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.bubblegumSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: borderColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: borderColor,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: brownPrimary,
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );

  // Text styles using Google Fonts BubblegumSans
  static TextStyle cartoonTitle = GoogleFonts.bubblegumSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: brownPrimary,
  );

  static TextStyle cartoonSubtitle = GoogleFonts.bubblegumSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: softBlack,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static TextStyle cartoonBody = GoogleFonts.bubblegumSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: softBlack,
    height: 1.4,
  );

  static TextStyle cartoonCaption = GoogleFonts.bubblegumSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF666666),
    letterSpacing: 0.3,
  );

  // Original text styles from profile screen
  static const TextStyle welcomeTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  // Custom widget helpers for cartoon style
  static Widget cartoonCard({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
    double borderWidth = 2.5,
    Color? borderColor,
    double borderRadius = 20,
    bool hasShadow = true,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.borderColor,
          width: borderWidth,
        ),
        boxShadow: hasShadow ? cartoonShadow : null,
      ),
      child: child,
    );
  }

  static Widget cartoonButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    EdgeInsets? padding,
    double borderRadius = 25,
    IconData? icon,
  }) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: cartoonShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? orangeAccent,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(
              color: brownPrimary,
              width: 2,
            ),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.bubblegumSans(
            fontSize: fontSize ?? 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: (fontSize ?? 16) + 4),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text),
      ),
    );
  }

  static Widget cartoonIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double size = 50,
    double borderRadius = 15,
  }) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: cartoonShadow,
      ),
      child: Material(
        color: backgroundColor ?? cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor ?? brownPrimary,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
  static String getStoolTypeImage(int? stoolType) {
  if (stoolType == null) return 'assets/images/pellet.png'; // Default fallback
  
  switch (stoolType) {
    case 0: // Type 1 - Pellet
      return 'assets/images/pellet.png';
    case 1: // Type 2 - Rock  
      return 'assets/images/rocks.png';
    case 2: // Type 3 - Crackle
      return 'assets/images/crackle.png';
    case 3: // Type 4 - Soft
      return 'assets/images/soft.png';
    case 4: // Type 5 - Blob
      return 'assets/images/blobs.png';
    case 5: // Type 6 - Mushy
      return 'assets/images/gas.png';
    case 6: // Type 7 - Liquidy
      return 'assets/images/liquid.png';
    default:
      return 'assets/images/pellet.png'; // Default fallback
  }
}

static String getStoolTypeEmoji(int? stoolType) {
  if (stoolType == null) return '❓';
  
  switch (stoolType) {
    case 0: // Type 1 - Pellet
      return '⚫';
    case 1: // Type 2 - Rock  
      return '🪨';
    case 2: // Type 3 - Crackle
      return '🥜';
    case 3: // Type 4 - Soft
      return '🌭';
    case 4: // Type 5 - Blob
      return '🍯';
    case 5: // Type 6 - Mushy
      return '🌊';
    case 6: // Type 7 - Liquidy
      return '💧';
    default:
      return '❓';
  }
}

  static String getQualityEmoji(String? quality) {
    if (quality == null) return '😐';
    if (quality.contains('😊')) return '😊';
    if (quality.contains('🙂')) return '🙂';
    if (quality.contains('😐')) return '😐';
    if (quality.contains('😔')) return '😔';
    if (quality.contains('😖')) return '😖';
    return '😐';
  }

  static String formatDuration(double seconds) {
    int totalSeconds = seconds.round();
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  static String formatTotalTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${totalSeconds}s';
    }
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      // Today - show time
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String getHealthInsight(Map<String, dynamic> userStats) {
    final avgFeeling = userStats['averageFeeling'] as double;
    final avgDuration = userStats['averageDuration'] as double;
    final totalSessions = userStats['totalSessions'] as int;
    
    if (totalSessions == 0 && userStats['totalCheckins'] == 0) {
      return "Start tracking your digestive health with check-ins or timer sessions to get personalized insights!";
    }
    
    if (avgFeeling >= 4.0) {
      return "Your average feeling rating is excellent. Keep up the healthy habits! ${AppTheme.funnyEmojis['celebration']}";
    } else if (avgFeeling >= 3.0) {
      return "You're doing well! Consider tracking what makes you feel better on your best days.";
    } else if (avgFeeling > 0) {
      return "Consider consulting with a healthcare professional about your digestive health patterns.";
    }
    
    if (totalSessions > 0) {
      if (avgDuration > 300) {
        return "You're taking your time! Longer sessions can be normal, but consider consulting a healthcare provider if you have concerns.";
      } else if (avgDuration > 0) {
        return "Your timing data shows consistency. Keep tracking to identify patterns that work best for you.";
      }
    }
    
    return "Start logging more data to get personalized health insights based on your patterns.";
  }
}