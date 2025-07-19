import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helsinco/screens/auth/log_in.dart';
import 'package:helsinco/screens/auth/sign_up.dart';
import 'package:helsinco/widgets/custom_button.dart';

class VerifyAccount extends StatefulWidget {
  const VerifyAccount({super.key});

  @override
  State<VerifyAccount> createState() => _VerifyAccountState();
}

class _VerifyAccountState extends State<VerifyAccount> {
  // Sends verification email to current user
  Future<void> verifyAccount(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: const Text(
            "Email Sent\nPlease check your email inbox.",
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: const Text(
            "Error\nUser not found or email already verified.",
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Checks user's email verification status
  Future<void> checkVerification(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Refresh user data
      await user.reload();

      if (user.emailVerified) {
        // Create user document in Firestore if it doesn't exist
        final docRef =
            FirebaseFirestore.instance.collection("users").doc(user.uid);
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          await docRef.set({
            "displayName": user.displayName,
            "email": user.email,
            "verifiedAt": DateTime.now(),
          });
        }

        // Clear all previous routes and go to HomeScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LogIn()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Show a SnackBar below
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            duration: const Duration(seconds: 4),
            content: const Text(
              "Account Not Verified\n"
              "Please check your email inbox and click the verification link.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar: Back button works with Get.offAll
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const SignUp())),
          icon: const Icon(Icons.arrow_back),
        ),
        toolbarHeight: 100,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.email_outlined,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Please click the verification link sent to your email",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 30),

              // "Continue" button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: "Continue",
                  onPressed: () => checkVerification(
                    context,
                  ), // Actually calling the function
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  verticalPadding: 16,
                  minHeight: 48,
                  elevation: 5,
                  borderRadius: BorderRadius.zero,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Didn't receive the verification email?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 15),

              // "Resend" button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: "Resend",
                  onPressed: () => verifyAccount(
                    context,
                  ), // Email verification link is being resent
                  backgroundColor: const Color(0xFFE8EEF2),
                  foregroundColor: Colors.black,
                  verticalPadding: 16,
                  minHeight: 48,
                  elevation: 5,
                  borderRadius: BorderRadius.zero,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
