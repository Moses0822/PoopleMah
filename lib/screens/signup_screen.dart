import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_service.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(Icons.healing,
                                size: 40, color: Color(0xFF8D6E63)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Join DailyPoop',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(_nameController, 'Username', Icons.person,
                            validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          if (value.trim().length < 2) {
                            return 'Username must be at least 2 characters';
                          }
                          return null;
                        }),
                        const SizedBox(height: 16),
                        _buildTextField(_emailController, 'Email', Icons.email,
                            validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        }),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Password',
                            Icons.lock,
                            isPassword: true, validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        }),
                        const SizedBox(height: 16),
                        _buildTextField(_confirmPasswordController,
                            'Confirm Password', Icons.lock_outline,
                            isPassword: true,
                            isConfirmPassword: true, validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        }),
                        const SizedBox(height: 24),
                        _buildButton(
                          text: _isLoading
                              ? 'Creating Account...'
                              : 'Sign Up',
                          onPressed:
                              _isLoading ? null : _handleSignup,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context)
                          .pushReplacementNamed('/login'),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon,
      {bool isPassword = false,
      bool isConfirmPassword = false,
      String? Function(String?)? validator}) {
    bool isVisible = isPassword
        ? (isConfirmPassword
            ? _isConfirmPasswordVisible
            : _isPasswordVisible)
        : false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      isVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF8D6E63)),
                  onPressed: () => setState(() {
                    if (isConfirmPassword) {
                      _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
                    } else {
                      _isPasswordVisible = !_isPasswordVisible;
                    }
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildButton(
      {required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF8D6E63),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 5),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)))
            : Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user!;
      final username = _nameController.text.trim();

      // ✅ Update Firebase displayName
      await user.updateDisplayName(username);
      await user.reload();

      // ✅ Save to SQLite (so friends can search by username)
      await FriendService().addUser(user.uid, username);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') message = 'Email already in use';
      if (e.code == 'invalid-email') message = 'Invalid email';
      if (e.code == 'weak-password') message = 'Password is too weak';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
