import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_service.dart'; 
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user!;
      final username = user.displayName ?? "Unknown";

      // ✅ Ensure user exists in local SQLite
      await FriendService().addUser(user.uid, username);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(uid: user.uid, username: username),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') message = 'No user found with this email';
      if (e.code == 'wrong-password') message = 'Incorrect password';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email', Icons.email,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password',
                        Icons.lock,
                        isPassword: true, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    }),
                    const SizedBox(height: 24),
                    _buildButton(
                      text: _isLoading ? 'Logging in...' : 'Login',
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context)
                              .pushReplacementNamed('/signup'),
                      child: const Text(
                        'Don\'t have an account? Sign Up',
                        style:
                            TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon,
      {bool isPassword = false, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)))
            : Text(
                text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
