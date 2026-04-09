import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC: FORGOT PASSWORD ---
  Future<void> _resetPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email address first.", Colors.orange);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Password reset link sent to your email!", Colors.green);
    } catch (e) {
      _showSnackBar("Network connection required!", Colors.redAccent);
    }
  }

  // --- LOGIC: GOOGLE SIGN IN ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '143587575907-45jop533ebhha22b8qvmogvonfjechbr.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } catch (e) {
      _showSnackBar("Google login failed.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // --- BRAND LOGO ---
                Column(
                  children: [
                    Container(
                      height: 120,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.psychology_outlined, size: 80, color: Colors.black),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: const Column(
                        children: [
                          Text("NeuroPad", style: TextStyle(color: Colors.black, fontSize: 32, letterSpacing: 2.0)),
                          Text("Sync your thoughts.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock_outlined,
                    isPassword: true
                ),

                const SizedBox(height: 10),

                // --- FORGOT PASSWORD ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        _showSnackBar("Please enter both email and password.", Colors.orange);
                        return;
                      }

                      setState(() => _isLoading = true);
                      try {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        if (mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        }
                      } on FirebaseAuthException catch (e) {
                        _showSnackBar(e.message ?? "Login failed", Colors.redAccent);
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Login", style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("OR CONTINUE WITH", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                    Expanded(child: Divider(color: Colors.black12)),
                  ],
                ),
                const SizedBox(height: 30),

                // --- SOCIAL LOGINS ---
                Row(
                  children: [
                    Expanded(child: _socialButton("Google", "assets/images/google_logo.png", onTap: _signInWithGoogle)),
                  ],
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                      },
                      child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _socialButton(String label, String assetPath, {required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: _isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            height: 22,
            width: 22,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.account_circle_outlined, size: 22, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}