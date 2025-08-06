import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_room_screen.dart';

class RoommateSeekerScreen extends StatefulWidget {
  const RoommateSeekerScreen({super.key});

  @override
  State<RoommateSeekerScreen> createState() => _RoommateSeekerScreenState();
}

class _RoommateSeekerScreenState extends State<RoommateSeekerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allSeekers = [];
  List<UserModel> _filteredSeekers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoommateSeekers();
  }

  Future<void> _loadRoommateSeekers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final seekers = await UserService.getAllRoommateSeekers();
      setState(() {
        _allSeekers = seekers;
        _filteredSeekers = seekers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading roommate seekers: $e')),
      );
    }
  }

  Future<void> _searchSeekers(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          _filteredSeekers = _allSeekers;
          _isLoading = false;
        });
      } else {
        final results = await UserService.searchRoommateSeekers(query);
        setState(() {
          _filteredSeekers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  Future<void> _startChat(UserModel user) async {
    try {
      final currentUser = await UserService.getCurrentUserProfile();
      if (currentUser == null) return;

      // Create or get existing chat room
      final roomId = await ChatService.createUserToUserChatRoom(
        currentUser.id,
        user.id,
        currentUser.fullName,
        user.fullName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            otherUserName: user.fullName,
            otherUserId: user.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Roommates'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchSeekers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _searchSeekers,
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSeekers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No roommate seekers found'
                                  : 'No results for "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try a different search term',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSeekers.length,
                        itemBuilder: (context, index) {
                          return _buildSeekerCard(_filteredSeekers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekerCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl?.isEmpty != false
                      ? Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.preferredLocation?.isNotEmpty == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              user.preferredLocation!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (user.maxBudget != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Budget: ₦${user.maxBudget!.toInt()}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Chat Button
                ElevatedButton.icon(
                  onPressed: () => _startChat(user),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            // Bio
            if (user.bio?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.bio!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            
            // Preferences
            if (user.preferredPropertyType?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Looking for: ${user.preferredPropertyType}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
