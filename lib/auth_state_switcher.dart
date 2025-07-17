import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helsinco/screens/home_screen.dart';

import 'package:helsinco/screens/auth/verify_account.dart';
import 'package:helsinco/screens/main_screen.dart';

class AuthStateSwitcher extends StatefulWidget {
  const AuthStateSwitcher({super.key});

  @override
  State<AuthStateSwitcher> createState() => _AuthStateSwitcherState();
}

class _AuthStateSwitcherState extends State<AuthStateSwitcher> {
  Future<void> _reloadIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.reload();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _reloadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            return HomeScreen();
          } else {
            return VerifyAccount();
          }
        } else {
          return MainScreen();
        }
      },
    );
  }
}
