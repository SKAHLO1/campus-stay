import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? userName; // Optional - for fallback display

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await UserService.getUserProfile(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.fullName ?? widget.userName ?? 'Profile'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Unable to load profile'),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(child: Text('Profile not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Header
                          _buildProfileHeader(),
                          const SizedBox(height: 24),

                          // Basic Information
                          _buildInfoSection('Basic Information', [
                            _buildInfoRow('Name', _user!.fullName),
                            _buildInfoRow('Email', _user!.email),
                            if (_user!.phone?.isNotEmpty == true)
                              _buildInfoRow('Phone', _user!.phone!),
                            if (_user!.gender?.isNotEmpty == true)
                              _buildInfoRow('Gender', _user!.gender!),
                          ]),

                          const SizedBox(height: 16),

                          // User Type Specific Information
                          if (_user!.userType == UserType.agent)
                            _buildAgentInfo()
                          else
                            _buildUserInfo(),

                          const SizedBox(height: 16),

                          // Bio Section
                          if (_user!.userType == UserType.agent && _user!.bio?.isNotEmpty == true)
                            _buildBioSection('About Agent', _user!.bio!)
                          else if (_user!.userType == UserType.user && _user!.userBio?.isNotEmpty == true)
                            _buildBioSection('About', _user!.userBio!),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image
        CircleAvatar(
          radius: 60,
          backgroundImage: _user!.profileImageUrl?.isNotEmpty == true
              ? NetworkImage(_user!.profileImageUrl!)
              : null,
          child: _user!.profileImageUrl?.isEmpty != false
              ? Icon(
                  _user!.userType == UserType.agent ? Icons.business : Icons.person,
                  size: 60,
                  color: Colors.grey[400],
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Name and Type Badge
        Text(
          _user!.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // User Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _user!.userType == UserType.agent
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _user!.userType == UserType.agent
                  ? Colors.green
                  : Colors.blue,
            ),
          ),
          child: Text(
            _user!.userType == UserType.agent ? 'AGENT' : 'USER',
            style: TextStyle(
              color: _user!.userType == UserType.agent
                  ? Colors.green
                  : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        // Rating (for agents)
        if (_user!.userType == UserType.agent && _user!.rating != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_user!.rating!.toStringAsFixed(1)} (${_user!.reviewCount ?? 0} reviews)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAgentInfo() {
    return _buildInfoSection('Agent Information', [
      if (_user!.agencyName?.isNotEmpty == true)
        _buildInfoRow('Agency', _user!.agencyName!),
      if (_user!.licenseNumber?.isNotEmpty == true)
        _buildInfoRow('License Number', _user!.licenseNumber!),
      _buildInfoRow('Verified', _user!.isVerified ? 'Yes' : 'No'),
      _buildInfoRow('Member Since', _formatDate(_user!.createdAt)),
    ]);
  }

  Widget _buildUserInfo() {
    return _buildInfoSection('User Preferences', [
      if (_user!.preferredLocation?.isNotEmpty == true)
        _buildInfoRow('Preferred Location', _user!.preferredLocation!),
      if (_user!.maxBudget != null)
        _buildInfoRow('Max Budget', '₦${_user!.maxBudget!.toInt()}'),
      if (_user!.preferredPropertyType?.isNotEmpty == true)
        _buildInfoRow('Preferred Property', _user!.preferredPropertyType!.toUpperCase()),
      if (_user!.level?.isNotEmpty == true)
        _buildInfoRow('Level', _user!.level!),
      if (_user!.religion?.isNotEmpty == true)
        _buildInfoRow('Religion', _user!.religion!),
      _buildInfoRow('Member Since', _formatDate(_user!.createdAt)),
    ]);
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(String title, String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
