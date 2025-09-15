import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db_helper.dart';
import '../Theme.dart';
import 'dart:math' as math;

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

class CheckinScreen extends StatefulWidget {
  final String uid;
  
  const CheckinScreen({super.key, required this.uid});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int selectedType = 0;
  double feeling = 3.0;
  String notes = '';

  final List<Map<String, dynamic>> poopTypes = [
    {'name': 'Type 1', 'description': 'Pellet', 'image': 'assets/images/pellet.png'},
    {'name': 'Type 2', 'description': 'Rock', 'image': 'assets/images/rocks.png'},
    {'name': 'Type 3', 'description': 'Crackle', 'image': 'assets/images/crackle.png'},
    {'name': 'Type 4', 'description': 'Soft', 'image': 'assets/images/soft.png'},
    {'name': 'Type 5', 'description': 'Blob', 'image': 'assets/images/blobs.png'},
    {'name': 'Type 6', 'description': 'Mushy', 'image': 'assets/images/gas.png'},
    {'name': 'Type 7', 'description': 'Liquidy', 'image': 'assets/images/liquid.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Check-in',
          style: GoogleFonts.bubblegumSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.textDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE0DCC8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildFeelingSlider(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bristol Stool Chart',
        style: GoogleFonts.bubblegumSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513), // Added fallback color
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: poopTypes.length,
          itemBuilder: (context, index) {
            final isSelected = selectedType == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedType = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                child: CartoonBox(
                  backgroundColor: isSelected 
                      ? (AppTheme.orangeAccent ?? const Color(0xFFFF8C00)) 
                      : Colors.white,
                  borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                  borderWidth: 2.5,
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          poopTypes[index]['image'],
                          width: 33,
                          height: 33,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image fails to load
                            return Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          poopTypes[index]['name'],
                          style: GoogleFonts.bubblegumSans(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : (AppTheme.brownPrimary ?? const Color(0xFF8B4513)),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            poopTypes[index]['description'],
                            style: GoogleFonts.bubblegumSans(
                              fontSize: 15,
                              color: isSelected 
                                  ? Colors.white70 
                                  : (AppTheme.brownPrimary?.withOpacity(0.6) ?? 
                                     const Color(0xFF8B4513).withOpacity(0.6)),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildFeelingSlider() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Overall Feeling',
        style: GoogleFonts.bubblegumSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        ),
      ),
      const SizedBox(height: 16),
      CartoonBox(
        backgroundColor: Colors.white,
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 3,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/1.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sentiment_very_dissatisfied),
                    );
                  },
                ),
                Image.asset(
                  'assets/images/2.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sentiment_dissatisfied),
                    );
                  },
                ),
                Image.asset(
                  'assets/images/3.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sentiment_neutral),
                    );
                  },
                ),
                Image.asset(
                  'assets/images/4.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sentiment_satisfied),
                    );
                  },
                ),
                Image.asset(
                  'assets/images/5.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sentiment_very_satisfied),
                    );
                  },
                ),
              ],
            ),
            Slider(
              value: feeling,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              activeColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
              inactiveColor: (AppTheme.orangeAccent ?? const Color(0xFFFF8C00)).withOpacity(0.3),
              thumbColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
              onChanged: (value) {
                setState(() {
                  feeling = value;
                });
              },
            ),
            Text(
              'Rating: ${feeling.round()}/5',
              style: GoogleFonts.bubblegumSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: GoogleFonts.bubblegumSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary,
          ),
        ),
        const SizedBox(height: 16),
        CartoonBox(
          backgroundColor: Colors.white,
          borderColor: AppTheme.brownPrimary,
          borderWidth: 3,
          padding: const EdgeInsets.all(20),
          child: TextField(
            maxLines: 4,
            style: GoogleFonts.bubblegumSans(
              fontSize: 14,
              color: AppTheme.brownPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'How are you feeling? Any pain or discomfort?',
              hintStyle: GoogleFonts.bubblegumSans(
                fontSize: 14,
                color: AppTheme.brownPrimary?.withOpacity(0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              notes = value;
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveCheckin() async {
    final dbHelper = DBHelper();
    final now = DateTime.now();
    
    final checkinData = {
      'userId': widget.uid,
      'stoolType': selectedType,
      'feelingRating': feeling,
      'notes': notes,
      'hasPhoto': 0,
      'photoPath': null,
      'timestamp': now.toIso8601String(),
      'dateOnly': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    };
    
    try {
      final result = await dbHelper.insertCheckin(checkinData);
      print('✅ Check-in saved with ID: $result');
      print('   User ID: ${checkinData['userId']}');
      print('   Stool Type: ${checkinData['stoolType']}');
      print('   Feeling: ${checkinData['feelingRating']}');
      
      // ADD THIS LINE - Update streak after inserting checkin
      await dbHelper.updateStreakAfterCheckin(widget.uid);
      
      final savedCheckins = await dbHelper.getCheckins(widget.uid);
      print('   Total check-ins for user: ${savedCheckins.length}');
      
    } catch (e) {
      print('❌ Error saving check-in: $e');
    }
  }
  Widget _buildSubmitButton() {
    return CartoonBox(
      backgroundColor: AppTheme.greenAccent,
      borderColor: AppTheme.brownPrimary,
      borderWidth: 3,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: TextButton(
          onPressed: () async {
            await _saveCheckin();
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: AppTheme.brownPrimary,
                      width: 2.5,
                    ),
                  ),
                  title: Text(
                    'Check-in Saved!',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                  content: Text(
                    'Your daily check-in has been recorded successfully.',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 16,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                  actions: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.greenAccent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppTheme.brownPrimary,
                          width: 2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'OK',
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
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            'Save Check-in',
            style: GoogleFonts.bubblegumSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}