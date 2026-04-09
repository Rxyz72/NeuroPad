import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // To show a loading spinner

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show messages
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LOGIC: EMAIL/PASSWORD SIGN UP ---
  Future<void> signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please fill in all fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _showMessage("Account created successfully! Welcome.");

      // Small delay to let them read the success message
      await Future.delayed(const Duration(seconds: 2));

      // If you aren't using an Auth Listener in main.dart, uncomment below:
      // if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "An error occurred", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: GOOGLE SIGN UP ---
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      _showMessage(isNewUser ? "Account created with Google!" : "Logged in successfully!");

      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      _showMessage("Google sign up failed.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),

              // Sign Up Button or Loading Spinner
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // Google Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signUpWithGoogle,
                  icon: Image.asset('assets/images/google_logo.png', height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30),
                  ),
                  label: const Text("Sign up with Google", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Login", style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}