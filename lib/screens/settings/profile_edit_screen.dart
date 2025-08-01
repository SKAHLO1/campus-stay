import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _agencyNameController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _preferredLocationController;
  late TextEditingController _maxBudgetController;

  File? _selectedImage;
  bool _isLoading = false;
  String? _preferredPropertyType;

  final List<String> _propertyTypes = ['house', 'apartment', 'condo', 'villa', 'studio'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _agencyNameController = TextEditingController(text: widget.user.agencyName ?? '');
    _licenseNumberController = TextEditingController(text: widget.user.licenseNumber ?? '');
    _preferredLocationController = TextEditingController(text: widget.user.preferredLocation ?? '');
    _maxBudgetController = TextEditingController(
      text: widget.user.maxBudget?.toString() ?? '',
    );
    _preferredPropertyType = widget.user.preferredPropertyType;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final String fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('profiles/$fileName');
      
      final UploadTask uploadTask = ref.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      final Map<String, dynamic> updates = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
      };

      if (imageUrl != null) {
        updates['profileImageUrl'] = imageUrl;
      }

      // Agent-specific fields
      if (widget.user.userType == UserType.agent) {
        updates['bio'] = _bioController.text.isEmpty ? null : _bioController.text;
        updates['agencyName'] = _agencyNameController.text.isEmpty ? null : _agencyNameController.text;
        updates['licenseNumber'] = _licenseNumberController.text.isEmpty ? null : _licenseNumberController.text;
      } else {
        // User-specific fields
        updates['preferredLocation'] = _preferredLocationController.text.isEmpty ? null : _preferredLocationController.text;
        updates['maxBudget'] = _maxBudgetController.text.isEmpty ? null : double.tryParse(_maxBudgetController.text);
        updates['preferredPropertyType'] = _preferredPropertyType;
      }

      await UserService.updateUserProfile(widget.user.id, updates);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (widget.user.profileImageUrl?.isNotEmpty == true
                                    ? NetworkImage(widget.user.profileImageUrl!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null && widget.user.profileImageUrl?.isEmpty != false
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3192),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Basic Information
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Agent-specific fields
                    if (widget.user.userType == UserType.agent) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Agent Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _agencyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Agency Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'License Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                          hintText: 'Tell clients about yourself...',
                        ),
                        maxLines: 3,
                      ),
                    ],

                    // User-specific fields
                    if (widget.user.userType == UserType.user) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _preferredLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _maxBudgetController,
                        decoration: const InputDecoration(
                          labelText: 'Max Budget (₦)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _preferredPropertyType,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Property Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No preference')),
                          ..._propertyTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _preferredPropertyType = value),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E3192),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _agencyNameController.dispose();
    _licenseNumberController.dispose();
    _preferredLocationController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }
}
