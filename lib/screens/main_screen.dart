import 'package:flutter/material.dart';
import 'package:helsinco/screens/auth/log_in.dart';
import 'package:helsinco/screens/auth/sign_up.dart';
import 'package:helsinco/widgets/custom_button.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          // Center on main axis if desired:
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Expanded: ensures the button takes equal share of available space
            Expanded(
              child: CustomButton(
                label: 'Login',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => LogIn())),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            // Use width for horizontal spacing in Row
            SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: 'Sign Up',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => SignUp())),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
