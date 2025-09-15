import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/post_service.dart';
import '../Theme.dart';
import 'dart:math' as math;
import '../screens/friends_screen.dart';

// Reuse the CartoonBorderPainter from your existing code
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

// Reuse the CartoonBox widget
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

class FeedScreen extends StatefulWidget {
  final String currentUserId;
  const FeedScreen({super.key, required this.currentUserId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final PostService _postService = PostService();
  final TextEditingController _postController = TextEditingController();
  List<Map<String, dynamic>> posts = [];
  Map<int, List<Map<String, dynamic>>> postComments = {};
  Map<int, TextEditingController> commentControllers = {};
  late AnimationController _heartAnimationController;
  String selectedMoodFilter = 'All';
  bool showOnlineUsers = false; // Added missing variable

  final List<String> moodFilters = ['All', 'Neutral', 'Excited'];
  final List<String> quickReactions = ['👍', '❤️', '😂', '😮', '😢', '😠'];

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    loadPosts();
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadPosts() async {
    final data = await _postService.getAllPosts();
    setState(() {
      posts = data;
    });

    for (var post in data) {
      loadComments(post['id']);
    }
  }

  Future<void> loadComments(int postId) async {
    final data = await _postService.getCommentsForPost(postId);
    setState(() {
      postComments[postId] = data;
    });
  }

  Future<void> addPost() async {
    if (_postController.text.isEmpty) return;
    await _postService.addPost(widget.currentUserId, _postController.text);
    _postController.clear();
    await loadPosts();
  }

  Future<void> addComment(int postId) async {
    final controller = commentControllers[postId];
    if (controller == null || controller.text.isEmpty) return;

    await _postService.addComment(postId, widget.currentUserId, controller.text);
    controller.clear();
    await loadComments(postId);
  }

  Future<void> toggleLike(int postId) async {
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });
    
    final isLiked = await _postService.isPostLiked(postId, widget.currentUserId);
    if (isLiked) {
      await _postService.unlikePost(postId, widget.currentUserId);
    } else {
      await _postService.likePost(postId, widget.currentUserId);
    }
    setState(() {});
  }

  // Added missing method
  Widget _buildOnlineUsersOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showOnlineUsers ? 80 : 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CartoonBox(
          backgroundColor: AppTheme.greenAccent?.withOpacity(0.3) ?? 
                           const Color(0xFF90EE90).withOpacity(0.3),
          borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          borderWidth: 2,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showOnlineUsers = !showOnlineUsers;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '12 friends online',
                      style: GoogleFonts.bubblegumSans(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      showOnlineUsers ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                    ),
                  ],
                ),
              ),
              if (showOnlineUsers) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5, // Placeholder count
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
                          child: Text(
                            'U${index + 1}',
                            style: GoogleFonts.bubblegumSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: moodFilters.length,
        itemBuilder: (context, index) {
          final mood = moodFilters[index];
          final isSelected = selectedMoodFilter == mood;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CartoonBox(
              backgroundColor: isSelected 
                  ? (AppTheme.orangeAccent ?? const Color(0xFFFF8C00))
                  : Colors.white,
              borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              borderWidth: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMoodFilter = mood;
                  });
                },
                child: Center(
                  child: Text(
                    mood,
                    style: GoogleFonts.bubblegumSans(
                      color: isSelected 
                          ? Colors.white 
                          : (AppTheme.brownPrimary ?? const Color(0xFF8B4513)),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CartoonBox(
        backgroundColor: Colors.white,
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 3,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
                  child: Text(
                    'U',
                    style: GoogleFonts.bubblegumSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    style: GoogleFonts.bubblegumSans(),
                    decoration: InputDecoration(
                      hintText: "Share your poop journey thoughts! 💭",
                      hintStyle: GoogleFonts.bubblegumSans(
                        color: Colors.grey.shade600,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: quickReactions.map((reaction) => 
                    GestureDetector(
                      onTap: () {
                        _postController.text += ' $reaction';
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(reaction, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ).toList(),
                ),
                CartoonBox(
                  backgroundColor: AppTheme.greenAccent ?? const Color(0xFF90EE90),
                  borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                  borderWidth: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: addPost,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.send, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Post',
                          style: GoogleFonts.bubblegumSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  String _getTimeAgo(String timestamp) {
    final now = DateTime.now();
    final time = DateTime.parse(timestamp);
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Feed',
          style: GoogleFonts.bubblegumSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendsScreen(currentUserId: widget.currentUserId),
                ),
              );
            },
            child: CartoonBox(
              backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
              borderColor: Colors.white,
              borderWidth: 2,
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.people, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: const Color(0xFFE0DCC8),
      body: Column(
        children: [
          // Removed online users overlay completely
          _buildPostInput(),
          
          // Community Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CartoonBox(
              backgroundColor: AppTheme.orangeAccent?.withOpacity(0.3) ?? 
                               const Color(0xFFFF8C00).withOpacity(0.3),
              borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
              borderWidth: 2,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Posts Today', '${posts.length}', Icons.post_add),
                  _buildStatItem('Active Users', '42', Icons.people),
                  _buildStatItem('Support Given', '156', Icons.favorite),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Posts List
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final comments = postComments[post['id']] ?? [];

                commentControllers.putIfAbsent(
                  post['id'],
                  () => TextEditingController(),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CartoonBox(
                    backgroundColor: Colors.white,
                    borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                    borderWidth: 2.5,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
                              radius: 20,
                              child: Text(
                                post['username'][0].toUpperCase(),
                                style: GoogleFonts.bubblegumSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['username'],
                                    style: GoogleFonts.bubblegumSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                    ),
                                  ),
                                  Text(
                                    _getTimeAgo(post['timestamp'].toString()),
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.currentUserId == post['userId'])
                              CartoonBox(
                                backgroundColor: Colors.red.shade100,
                                borderColor: Colors.red,
                                borderWidth: 1.5,
                                padding: const EdgeInsets.all(4),
                                child: GestureDetector(
                                  onTap: () async {
                                    await _postService.deletePost(post['id']);
                                    loadPosts();
                                  },
                                  child: const Icon(Icons.delete, 
                                                 color: Colors.red, size: 16),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Post content
                        Text(
                          post['content'],
                          style: GoogleFonts.bubblegumSans(
                            fontSize: 15,
                            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Like row
                        FutureBuilder<bool>(
                          future: _postService.isPostLiked(post['id'], widget.currentUserId),
                          builder: (context, snapshotLiked) {
                            return FutureBuilder<int>(
                              future: _postService.getLikeCount(post['id']),
                              builder: (context, snapshotCount) {
                                final isLiked = snapshotLiked.data ?? false;
                                final likeCount = snapshotCount.data ?? 0;

                                return Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _heartAnimationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 1.0 + (_heartAnimationController.value * 0.3),
                                          child: CartoonBox(
                                            backgroundColor: isLiked 
                                                ? Colors.red.shade100 
                                                : Colors.grey.shade100,
                                            borderColor: isLiked ? Colors.red : Colors.grey,
                                            borderWidth: 1.5,
                                            padding: const EdgeInsets.all(8),
                                            child: GestureDetector(
                                              onTap: () => toggleLike(post['id']),
                                              child: Icon(
                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                color: isLiked ? Colors.red : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$likeCount likes",
                                      style: GoogleFonts.bubblegumSans(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${comments.length} comments",
                                      style: GoogleFonts.bubblegumSans(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        
                        // Comments
                        if (comments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...comments.map((comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: CartoonBox(
                                  backgroundColor: const Color(0xFFF5F5F0),
                                  borderColor: Colors.grey.shade400,
                                  borderWidth: 1,
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.greenAccent ?? 
                                                         const Color(0xFF90EE90),
                                        radius: 12,
                                        child: Text(
                                          comment['username'][0].toUpperCase(),
                                          style: GoogleFonts.bubblegumSans(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['username'],
                                              style: GoogleFonts.bubblegumSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppTheme.brownPrimary ?? 
                                                       const Color(0xFF8B4513),
                                              ),
                                            ),
                                            Text(
                                              comment['content'],
                                              style: GoogleFonts.bubblegumSans(
                                                fontSize: 13,
                                                color: AppTheme.brownPrimary ?? 
                                                       const Color(0xFF8B4513),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.currentUserId == comment['userId'])
                                        GestureDetector(
                                          onTap: () async {
                                            await _postService.deleteComment(comment['id']);
                                            loadComments(post['id']);
                                          },
                                          child: Icon(Icons.close, 
                                                     color: Colors.red.shade400, size: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              )),
                        ],

                        // Add comment
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CartoonBox(
                                backgroundColor: const Color(0xFFF8F8F8),
                                borderColor: Colors.grey.shade400,
                                borderWidth: 1.5,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: TextField(
                                  controller: commentControllers[post['id']],
                                  style: GoogleFonts.bubblegumSans(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Add a supportive comment...",
                                    hintStyle: GoogleFonts.bubblegumSans(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CartoonBox(
                              backgroundColor: AppTheme.greenAccent ?? const Color(0xFF90EE90),
                              borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
                              borderWidth: 2,
                              padding: const EdgeInsets.all(8),
                              child: GestureDetector(
                                onTap: () => addComment(post['id']),
                                child: const Icon(Icons.send, 
                                                color: Colors.white, size: 16),
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
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.bubblegumSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.bubblegumSans(
            fontSize: 10,
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}