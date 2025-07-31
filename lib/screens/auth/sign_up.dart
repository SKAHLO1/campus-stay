import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helsinco/screens/auth/verify_account.dart';
import 'package:helsinco/screens/home/dashboard_screen.dart';
import 'package:helsinco/widgets/custom_button.dart';
import 'package:helsinco/widgets/text_inputs.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/google_auth_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController fullName = TextEditingController();
  final TextEditingController lastName = TextEditingController();

  UserType _selectedUserType = UserType.user;

  Future<void> signUpUser() async {
    try {
      // Create user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update user display name
        await user.updateDisplayName("${fullName.text} ${lastName.text}");
        await user.reload();

        // Send verification email
        await user.sendEmailVerification();

        // Create user profile
        final userModel = UserModel(
          id: user.uid,
          email: email.text.trim(),
          firstName: fullName.text.trim(),
          lastName: lastName.text.trim(),
          userType: _selectedUserType,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await UserService.createUserProfile(userModel);

        // Navigate to verification screen
        if (mounted) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => VerifyAccount()));
        }
      }
    } catch (e) {
      print("🔥 Firebase Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text("Account could not be created: $e")));
    }
  }

  // Google sign up function
  Future<void> signUpWithGoogle() async {
    try {
      final User? user =
          await GoogleAuthService.signUpWithGoogle(_selectedUserType);

      if (user != null) {
        print("🔥 User signed up with Google: ${user.email}");
        print("📌 User UID: ${user.uid}");

        // Navigate to dashboard screen (AuthStateSwitcher will handle this)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print("🚨 Google Sign Up Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign up failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 50,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
              const SizedBox(height: 20),
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Sign Up to Get Started!",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // TextInputs widgets
              TextInputs(labelText: 'First Name', controller: fullName),
              const SizedBox(height: 20),
              TextInputs(labelText: 'Last Name', controller: lastName),
              const SizedBox(height: 20),
              TextInputs(labelText: 'Email', controller: email, isEmail: true),
              const SizedBox(height: 20),
              TextInputs(
                labelText: 'Password',
                controller: password,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // User Type Selection
              const Text(
                'I am a:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserType>(
                      title: const Text('Roommate Seeker'),
                      subtitle: const Text('I\'m looking for a roommate/room'),
                      value: UserType.user,
                      groupValue: _selectedUserType,
                      onChanged: (value) =>
                          setState(() => _selectedUserType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserType>(
                      title: const Text('Agent'),
                      subtitle: const Text('Listing properties'),
                      value: UserType.agent,
                      groupValue: _selectedUserType,
                      onChanged: (value) =>
                          setState(() => _selectedUserType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "By continuing, you agree to our Terms of Service.\nRead our Privacy Policy.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // "Sign Up" button
              CustomButton(
                label: "Sign Up",
                onPressed: signUpUser,
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

              const SizedBox(height: 16),

              // "Or" divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // Google Sign Up button
              Container(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: signUpWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_icon.png',
                    height: 20,
                    width: 20,
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
