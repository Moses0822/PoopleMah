import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db_helper.dart';
import '../theme.dart';
import 'dart:math' as math;

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

class EditProfileScreen extends StatefulWidget {
  final String uid;
  final String currentUsername;

  const EditProfileScreen({
    super.key,
    required this.uid,
    required this.currentUsername,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _currentEmail;
  String? _originalUsername;
  String? _originalDisplayName;
  String? _originalBio;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadCurrentData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentEmail = user.email;
        _displayNameController.text = user.displayName ?? '';
        _originalDisplayName = user.displayName ?? '';
      }
      
      _usernameController.text = widget.currentUsername;
      _originalUsername = widget.currentUsername;
      _originalBio = ''; // You might want to add bio field to your database
      _bioController.text = _originalBio ?? '';
      
      // Listen for changes
      _usernameController.addListener(_onFieldChanged);
      _displayNameController.addListener(_onFieldChanged);
      _bioController.addListener(_onFieldChanged);
      
    } catch (e) {
      print('Error loading profile data: $e');
      _showErrorSnackBar('Failed to load profile data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFieldChanged() {
    final hasChanges = _usernameController.text != _originalUsername ||
                      _displayNameController.text != _originalDisplayName ||
                      _bioController.text != _originalBio;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final dbHelper = DBHelper();
      
      // Update display name in Firebase Auth
      if (_displayNameController.text != _originalDisplayName && user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
      }
      
      // Update username in local database
      if (_usernameController.text != _originalUsername) {
        await dbHelper.updateUsername(widget.uid, _usernameController.text.trim());
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: GoogleFonts.bubblegumSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Return the new username to the previous screen
        Navigator.pop(context, _usernameController.text.trim());
      }
      
    } catch (e) {
      print('Error saving profile: $e');
      _showErrorSnackBar('Failed to update profile');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.bubblegumSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
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
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.bubblegumSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.bubblegumSans(
            fontSize: 16,
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.brownPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: GoogleFonts.bubblegumSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFE0DCC8),
        appBar: AppBar(
          backgroundColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: GoogleFonts.bubblegumSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: Text(
                  'Save',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryBrown,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar Section
                      _buildAvatarSection(),
                      const SizedBox(height: 30),
                      
                      // Basic Information Section
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      
                      // Account Information Section
                      _buildAccountInfoSection(),
                      const SizedBox(height: 24),
                      
                      // Additional Information Section
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: 40),
                      
                      // Save Button
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: CartoonBox(
        backgroundColor: AppTheme.orangeAccent ?? const Color(0xFFFF8C00),
        borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        borderWidth: 3,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
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
                      _usernameController.text.isNotEmpty 
                          ? _usernameController.text[0].toUpperCase() 
                          : '?',
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brownPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.brownPrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to change avatar',
              style: GoogleFonts.bubblegumSans(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return CartoonBox(
      backgroundColor: Colors.white,
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.bubblegumSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Username Field
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                return 'Username can only contain letters, numbers, and underscores';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Display Name Field
          _buildTextField(
            controller: _displayNameController,
            label: 'Display Name',
            icon: Icons.badge,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                return 'Display name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return CartoonBox(
      backgroundColor: AppTheme.warmYellow ?? const Color(0xFFFFF8DC),
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: GoogleFonts.bubblegumSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Email Field (Read-only)
          _buildReadOnlyField(
            label: 'Email',
            value: _currentEmail ?? 'Not available',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          
          // Member since (Read-only)
          _buildReadOnlyField(
            label: 'Member Since',
            value: _getMemberSinceDate(),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return CartoonBox(
      backgroundColor: AppTheme.softGreen ?? const Color(0xFF90EE90),
      borderColor: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
      borderWidth: 3,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.bubblegumSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.brownPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Bio Field
          _buildTextField(
            controller: _bioController,
            label: 'Bio (Optional)',
            icon: Icons.description,
            maxLines: 3,
            maxLength: 150,
            validator: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.bubblegumSans(
        fontSize: 16,
        color: AppTheme.brownPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.bubblegumSans(
          fontSize: 16,
          color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.5),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppTheme.brownPrimary ?? const Color(0xFF8B4513),
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2.5,
          ),
        ),
        counterStyle: GoogleFonts.bubblegumSans(
          fontSize: 12,
          color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 12,
                    color: (AppTheme.brownPrimary ?? const Color(0xFF8B4513)).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 16,
                    color: AppTheme.brownPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges 
              ? AppTheme.brownPrimary ?? const Color(0xFF8B4513)
              : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: _hasChanges ? 8 : 2,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _hasChanges ? 'Save Changes' : 'No Changes',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getMemberSinceDate() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.metadata.creationTime != null) {
      final date = user!.metadata.creationTime!;
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }
}