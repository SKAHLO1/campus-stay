import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'users';

  // Create user profile
  static Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(currentUser.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get user profile by ID
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _firestore.collection(_collection).doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get all agents
  static Future<List<UserModel>> getAllAgents() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'agent')
          .get();

      List<UserModel> agents = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      // Sort by rating client-side
      agents.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      
      return agents;
    } catch (e) {
      throw Exception('Failed to get agents: $e');
    }
  }

  // Check if user exists
  static Future<bool> userExists(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Stream current user profile
  static Stream<UserModel?> getCurrentUserStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(_collection)
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Get all roommate seekers (excluding current user)
  static Future<List<UserModel>> getAllRoommateSeekers() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'user')
          .get();

      List<UserModel> seekers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.id != currentUser.uid)
          .toList();
      
      // Sort by creation date client-side
      seekers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return seekers;
    } catch (e) {
      throw Exception('Failed to get roommate seekers: $e');
    }
  }

  // Search roommate seekers by location or name
  static Future<List<UserModel>> searchRoommateSeekers(String query) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'user')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => 
              user.id != currentUser.uid &&
              (user.fullName.toLowerCase().contains(query.toLowerCase()) ||
               (user.preferredLocation?.toLowerCase().contains(query.toLowerCase()) ?? false)))
          .toList();
    } catch (e) {
      throw Exception('Failed to search roommate seekers: $e');
    }
  }
}
