import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helsinco/screens/auth/reset_password.dart';
import 'package:helsinco/screens/auth/sign_up.dart';
import '../home/dashboard_screen.dart';
import 'package:helsinco/widgets/custom_button.dart';
import 'package:helsinco/widgets/text_inputs.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  // User login function
  Future<void> signInUser() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        print("🔥 User logged in: ${user.email}");
        print("📌 User UID: ${user.uid}");

        // Navigate to dashboard screen (AuthStateSwitcher will handle this)
        // The auth state will automatically redirect to DashboardScreen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print("🚨 Firebase Login Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent overflow when keyboard opens
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Fill in the required fields to continue.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              TextInputs(labelText: 'Email', controller: email, isEmail: true),
              const SizedBox(height: 20),
              TextInputs(
                labelText: 'Password',
                controller: password,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              Text(
                "By continuing, you agree to our Terms of Service.\nRead our Privacy Policy.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // "Login" button
              CustomButton(
                label: "Login",
                onPressed: signInUser,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                verticalPadding: 16,
                minHeight: 48,
                elevation: 3,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),

              // "Forgot Password" button
              CustomButton(
                label: "Forgot Password",
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ResetPassword()),
                ),
                backgroundColor: Color(0xFFE8EEF2),
                foregroundColor: Colors.black,
                verticalPadding: 16,
                minHeight: 48,
                elevation:
                    0, // Not in original code, you can set to 3 if desired
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              // "Create Account Now" button
              CustomButton(
                label: "Create Account Now",
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => SignUp()));
                },
                backgroundColor: Color(0xFFE8EEF2),
                foregroundColor: Colors.black,
                verticalPadding: 16,
                minHeight: 48,
                elevation: 0,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
