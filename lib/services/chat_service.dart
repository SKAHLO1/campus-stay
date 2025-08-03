import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _roomsCollection = 'chat_rooms';
  static const String _messagesCollection = 'messages';

  // Create or get existing chat room
  static Future<String> createOrGetChatRoom({
    required String userId,
    required String userName,
    required String agentId,
    required String agentName,
    String? propertyId,
    String? propertyTitle,
  }) async {
    try {
      // Use a deterministic room ID to avoid multiple where clauses
      final String potentialRoomId = '${userId}_${agentId}';
      
      // Check if chat room already exists
      final DocumentSnapshot existingRoom = await _firestore
          .collection(_roomsCollection)
          .doc(potentialRoomId)
          .get();

      if (existingRoom.exists) {
        return potentialRoomId;
      }

      // Create new chat room
      final String roomId = potentialRoomId;
      final ChatRoom chatRoom = ChatRoom(
        id: roomId,
        userId: userId,
        userName: userName,
        agentId: agentId,
        agentName: agentName,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_roomsCollection).doc(roomId).set(chatRoom.toMap());
      return roomId;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Send message
  static Future<void> sendMessage({
    required String roomId,
    String? receiverId,
    String? receiverName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get chat room details to determine receiver
      final DocumentSnapshot roomDoc = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();
      
      if (!roomDoc.exists) throw Exception('Chat room not found');
      
      final Map<String, dynamic> roomData = roomDoc.data() as Map<String, dynamic>;
      
      // Determine receiver ID and name based on room type
      String finalReceiverId;
      String finalReceiverName;
      
      if (roomData.containsKey('participants')) {
        // User-to-user chat
        final List<String> participants = List<String>.from(roomData['participants']);
        finalReceiverId = participants.firstWhere((id) => id != currentUser.uid);
        final Map<String, dynamic> participantNames = Map<String, dynamic>.from(roomData['participantNames']);
        finalReceiverName = participantNames[finalReceiverId] ?? '';
      } else {
        // Agent-user chat
        if (currentUser.uid == roomData['userId']) {
          finalReceiverId = roomData['agentId'];
          finalReceiverName = roomData['agentName'];
        } else {
          finalReceiverId = roomData['userId'];
          finalReceiverName = roomData['userName'];
        }
      }

      final String messageId = const Uuid().v4();
      final DateTime now = DateTime.now();

      final ChatMessage chatMessage = ChatMessage(
        id: messageId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? '',
        receiverId: finalReceiverId,
        receiverName: finalReceiverName,
        message: message,
        timestamp: now,
        type: type,
      );

      // Add message to subcollection
      await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(chatMessage.toMap());

      // Update chat room with last message
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'lastMessage': message,
        'lastMessageTime': now,
        'updatedAt': now,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat room
  static Stream<List<ChatMessage>> getMessages(String roomId) {
    return _firestore
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Get chat rooms for current user (includes both as user and in user-to-user chats)
  static Stream<List<ChatRoom>> getChatRooms() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_roomsCollection)
        .snapshots()
        .map((snapshot) {
          List<ChatRoom> rooms = [];
          
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              
              // Check if user is participant in this chat room
              bool isParticipant = false;
              
              // Check if it's a user-agent chat where current user is the user
              if (data['userId'] == currentUser.uid) {
                isParticipant = true;
              }
              
              // Check if it's a user-to-user chat where current user is in participants
              else if (data.containsKey('participants')) {
                final List<dynamic> participants = data['participants'] ?? [];
                if (participants.contains(currentUser.uid)) {
                  isParticipant = true;
                }
              }
              
              if (isParticipant) {
                // Handle different chat room types
                if (data.containsKey('participants')) {
                  // User-to-user chat room - convert to ChatRoom format
                  final List<dynamic> participants = data['participants'] ?? [];
                  final Map<String, dynamic> participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
                  
                  // Find the other participant
                  final String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
                  final String otherUserName = participantNames[otherUserId] ?? 'Unknown User';
                  
                  rooms.add(ChatRoom(
                    id: doc.id,
                    userId: currentUser.uid,
                    userName: participantNames[currentUser.uid] ?? '',
                    agentId: otherUserId, // Store other user ID here for convenience
                    agentName: otherUserName, // Store other user name here for convenience
                    lastMessage: data['lastMessage'] ?? '',
                    lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  ));
                } else {
                  // Regular user-agent chat room
                  rooms.add(ChatRoom.fromFirestore(doc));
                }
              }
            } catch (e) {
              print('Error processing chat room ${doc.id}: $e');
            }
          }
          
          // Sort by last message time client-side
          rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          return rooms;
        });
  }

  // Get chat rooms for agent (only agent-user chats, not user-to-user)
  static Stream<List<ChatRoom>> getAgentChatRooms() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_roomsCollection)
        .where('agentId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          List<ChatRoom> rooms = snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
          
          // Sort by last message time client-side
          rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          return rooms;
        });
  }

  // Create or get user-to-user chat room (for roommate seekers)
  static Future<String> createUserToUserChatRoom(
    String user1Id,
    String user2Id,
    String user1Name,
    String user2Name,
  ) async {
    try {
      // Create a consistent room ID by sorting user IDs
      final List<String> sortedIds = [user1Id, user2Id]..sort();
      final String roomId = '${sortedIds[0]}_${sortedIds[1]}';

      // Check if chat room already exists
      final DocumentSnapshot existingRoom = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();

      if (existingRoom.exists) {
        return roomId;
      }

      // Create new user-to-user chat room
      final Map<String, dynamic> chatRoomData = {
        'id': roomId,
        'participants': [user1Id, user2Id],
        'participantNames': {user1Id: user1Name, user2Id: user2Name},
        'lastMessage': 'Chat started',
        'lastMessageTime': DateTime.now(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'type': 'user_to_user', // To distinguish from agent chats
      };

      await _firestore.collection(_roomsCollection).doc(roomId).set(chatRoomData);
      return roomId;
    } catch (e) {
      throw Exception('Failed to create user chat room: $e');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      // Get all messages for the user and filter client-side
      final QuerySnapshot allMessages = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .get();

      final WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in allMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count
  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      // This is a simplified version - in production, you might want to use Cloud Functions
      // to maintain unread counts more efficiently
      final QuerySnapshot rooms = await _firestore
          .collection(_roomsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalUnread = 0;
      for (QueryDocumentSnapshot room in rooms.docs) {
        final QuerySnapshot allMessages = await _firestore
            .collection(_roomsCollection)
            .doc(room.id)
            .collection(_messagesCollection)
            .where('receiverId', isEqualTo: userId)
            .get();
        
        // Count unread messages client-side
        for (QueryDocumentSnapshot message in allMessages.docs) {
          final data = message.data() as Map<String, dynamic>;
          if (data['isRead'] == false) {
            totalUnread++;
          }
        }
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}
