import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/property_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../property/property_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../chat/chat_list_screen.dart';
import '../agent/upload_property_screen.dart';
import '../agent/agent_properties_screen.dart';
import '../property/search_screen.dart';
import '../roommate/roommate_seekers_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  Position? _userPosition;
  List<PropertyModel> _nearbyProperties = [];
  List<PropertyModel> _allProperties = [];
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserLocation();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await UserService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _userPosition = position;
      });

      if (position != null) {
        final nearby = await PropertyService.getNearbyProperties(
          position.latitude,
          position.longitude,
          50.0, // 50km radius
        );
        setState(() {
          _nearbyProperties = nearby;
        });
      }
    } catch (e) {
      print('Error loading location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_currentUser?.firstName ?? 'User'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.userType == UserType.agent
                      ? 'Manage your properties and connect with clients'
                      : 'Find your perfect home and connect with roommates',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions for Agents
          if (_currentUser?.userType == UserType.agent) ...[
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.add_home,
                    title: 'Upload Property',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UploadPropertyScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.business,
                    title: 'My Properties',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AgentPropertiesScreen(agentId: _currentUser!.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions for Roommate Seekers
          if (_currentUser?.userType == UserType.user) ...[
            const Text(
              'Find Roommates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.people_alt,
                    title: 'Find Roommates',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RoommateSeekerScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'My Chats',
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Nearby Properties Section
          if (_nearbyProperties.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Near You',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyProperties.length,
                itemBuilder: (context, index) {
                  return _buildPropertyCard(_nearbyProperties[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // All Properties Section
          const Text(
            'All Properties',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<PropertyModel>>(
            stream: PropertyService.getAllProperties(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final properties = snapshot.data ?? [];

              if (properties.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No properties available'),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  return _buildPropertyListItem(properties[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2E3192)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: property.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(property.imageUrls.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: property.imageUrls.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.home,
                            size: 48, color: Colors.grey),
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: property.listingType == 'rent'
                                    ? Colors.blue
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'FOR ${property.listingType.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              // Property Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${property.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF2E3192),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPropertySpec(Icons.bed, '${property.bedrooms}'),
                        const SizedBox(width: 8),
                        _buildPropertySpec(
                            Icons.bathroom, '${property.bathrooms}'),
                        const SizedBox(width: 8),
                        _buildPropertySpec(
                            Icons.square_foot, '${property.sqm.toInt()}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyListItem(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(property: property),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Property Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: property.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(property.imageUrls.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: property.imageUrls.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.home, color: Colors.grey),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${property.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF2E3192),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPropertySpec(Icons.bed, '${property.bedrooms}'),
                        const SizedBox(width: 8),
                        _buildPropertySpec(
                            Icons.bathroom, '${property.bathrooms}'),
                        const SizedBox(width: 8),
                        _buildPropertySpec(
                            Icons.square_foot, '${property.sqm.toInt()}'),
                      ],
                    ),
                  ],
                ),
              ),
              // Listing Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: property.listingType == 'rent'
                      ? Colors.blue
                      : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  property.listingType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySpec(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Stay'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const SearchScreen(),
          _currentUser != null ? ChatListScreen(currentUser: _currentUser!) : const Center(child: CircularProgressIndicator()),
          _currentUser != null ? SettingsScreen(currentUser: _currentUser!) : const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E3192),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
