import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final UserModel? currentUser;
  
  const ChatListScreen({super.key, this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    if (_currentUser == null) {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _currentUser!.userType == UserType.agent
            ? ChatService.getAgentChatRooms()
            : ChatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser!.userType == UserType.agent
                        ? 'Roommate seekers will appear here when they contact you'
                        : 'Start chatting with agents and other roommate seekers to see conversations here',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              return _buildChatRoomTile(chatRooms[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom chatRoom) {
    String otherUserName = '';
    String otherUserId = '';
    
    // For all chats, we now store the other participant's info in agentName/agentId
    // regardless of whether it's user-to-user or user-to-agent
    if (_currentUser!.userType == UserType.agent && chatRoom.propertyId != null) {
      // Agent viewing user-to-agent chat
      otherUserName = chatRoom.userName;
      otherUserId = chatRoom.userId;
    } else {
      // User viewing any chat (user-to-user or user-to-agent)
      otherUserName = chatRoom.agentName;
      otherUserId = chatRoom.agentId;
    }

    return Container(
      decoration: BoxDecoration(
        color: chatRoom.unreadCount > 0 ? const Color(0xFF2E3192).withOpacity(0.05) : null,
        border: chatRoom.unreadCount > 0 ? Border(
          left: BorderSide(
            color: const Color(0xFF2E3192),
            width: 4,
          ),
        ) : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: chatRoom.unreadCount > 0 
                  ? const Color(0xFF2E3192) 
                  : Colors.grey[400],
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            if (chatRoom.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    chatRoom.unreadCount > 99 ? '99+' : '${chatRoom.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            otherUserName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (chatRoom.propertyTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              'Re: ${chatRoom.propertyTitle}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        chatRoom.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: chatRoom.unreadCount > 0 ? Colors.black87 : Colors.grey,
          fontWeight:
              chatRoom.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chatRoom.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: chatRoom.unreadCount > 0
                  ? const Color(0xFF2E3192)
                  : Colors.grey,
            ),
          ),
          if (chatRoom.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3192),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chatRoom.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: chatRoom.id,
              otherUserName: otherUserName,
              otherUserId: otherUserId,
            ),
          ),
        );
      },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
