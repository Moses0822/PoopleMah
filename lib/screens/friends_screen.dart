import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/friend_service.dart';
import '../Theme.dart';
import 'dart:math' as math;

// Copy the CartoonBorderPainter from HomeScreen
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
      ..strokeWidth = borderWidth + (math.sin(size.width * 0.01) * 0.5).abs()
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
    final cornerRadius = 30.0;

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
    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 10, false);
    canvas.drawPath(path, outerBorderPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, innerShadowPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Copy the CartoonBox from HomeScreen
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

class FriendsScreen extends StatefulWidget {
  final String currentUserId;
  const FriendsScreen({super.key, required this.currentUserId});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _service = FriendService();
  List<Map<String, dynamic>> friends = [];
  final TextEditingController _usernameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {
    setState(() => _loading = true);
    final data = await _service.getFriends(widget.currentUserId);
    setState(() {
      friends = data;
      _loading = false;
    });
  }

  Future<void> addFriend() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    final friendUid = await _service.getUserIdByUsername(username);
    if (friendUid != null) {
      if (friendUid == widget.currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You cannot add yourself",
              style: GoogleFonts.bubblegumSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        await _service.sendFriendRequest(widget.currentUserId, friendUid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Friend request sent to $username",
              style: GoogleFonts.bubblegumSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.greenAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No user found with username $username",
            style: GoogleFonts.bubblegumSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    _usernameController.clear();
    await loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Friends',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary,
          ),
        ),
        backgroundColor: const Color(0xFFE0DCC8),
        foregroundColor: AppTheme.brownPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.brownPrimary),
      ),
      backgroundColor: const Color(0xFFE0DCC8),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Friend Section
            Text(
              'Add New Friend',
              style: GoogleFonts.bubblegumSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            ),
            const SizedBox(height: 12),
            CartoonBox(
              backgroundColor: Colors.white,
              borderColor: AppTheme.brownPrimary,
              borderWidth: 3,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brownPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter friend's username",
                        hintStyle: GoogleFonts.bubblegumSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppTheme.brownPrimary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppTheme.orangeAccent,
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.orangeAccent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppTheme.brownPrimary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white, size: 24),
                      onPressed: addFriend,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Friends List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friends List',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brownPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.orangeAccent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${friends.length} friends',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brownPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Friends List
            Expanded(
              child: CartoonBox(
                backgroundColor: Colors.white,
                borderColor: AppTheme.brownPrimary,
                borderWidth: 3,
                padding: const EdgeInsets.all(4),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: loadFriends,
                        color: AppTheme.orangeAccent,
                        child: friends.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No friends yet",
                                      style: GoogleFonts.bubblegumSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Add friends to start connecting!",
                                      style: GoogleFonts.bubblegumSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: friends.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final friend = friends[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.orangeAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.orangeAccent.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.greenAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.greenAccent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: AppTheme.greenAccent,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        friend['username'],
                                        style: GoogleFonts.bubblegumSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.brownPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Status: ${friend['status']}",
                                        style: GoogleFonts.bubblegumSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.brownPrimary?.withOpacity(0.7),
                                        ),
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.brownPrimary,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 3,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            // Show confirmation dialog
                                            final confirm = await showDialog<bool>(
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
                                                  'Remove Friend',
                                                  style: GoogleFonts.bubblegumSans(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.brownPrimary,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Are you sure you want to remove ${friend['username']} from your friends?',
                                                  style: GoogleFonts.bubblegumSans(
                                                    fontSize: 14,
                                                    color: AppTheme.brownPrimary,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts.bubblegumSans(
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    child: Text(
                                                      'Remove',
                                                      style: GoogleFonts.bubblegumSans(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            
                                            if (confirm == true) {
                                              await _service.removeFriend(
                                                  widget.currentUserId,
                                                  friend['id'].toString());
                                              await loadFriends();
                                            }
                                          },
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}