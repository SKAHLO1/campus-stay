import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google sign-in error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign up with Google and create user profile
  static Future<User?> signUpWithGoogle(UserType userType) async {
    try {
      final User? user = await signInWithGoogle();
      
      if (user != null) {
        // Check if user profile already exists
        final existingUser = await UserService.getUserProfile(user.uid);
        
        if (existingUser == null) {
          // Create new user profile
          final nameParts = user.displayName?.split(' ') ?? ['Unknown'];
          final firstName = nameParts.first;
          final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
          
          final userModel = UserModel(
            id: user.uid,
            email: user.email ?? '',
            firstName: firstName,
            lastName: lastName,
            profileImageUrl: user.photoURL,
            userType: userType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: true, // Google accounts are already verified
          );

          await UserService.createUserProfile(userModel);
        }
      }
      
      return user;
    } catch (e) {
      print('Google sign-up error: $e');
      throw Exception('Failed to sign up with Google: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Google sign-out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Check if user is signed in with Google
  static bool isSignedInWithGoogle() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return user.providerData.any((provider) => provider.providerId == 'google.com');
    }
    return false;
  }
}
