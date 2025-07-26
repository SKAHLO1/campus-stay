import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/property_service.dart';
import '../../services/user_service.dart';

class UploadPropertyScreen extends StatefulWidget {
  const UploadPropertyScreen({super.key});

  @override
  State<UploadPropertyScreen> createState() => _UploadPropertyScreenState();
}

class _UploadPropertyScreenState extends State<UploadPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _sqmController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  String _propertyType = 'house';
  String _listingType = 'rent';
  List<File> _selectedImages = [];
  List<String> _selectedFeatures = [];
  bool _isLoading = false;
  UserModel? _currentAgent;

  final List<String> _propertyTypes = [
    'house',
    'apartment',
    'condo',
    'villa',
    'studio'
  ];
  final List<String> _listingTypes = ['rent', 'sale'];
  final List<String> _availableFeatures = [
    'garage',
    'swimming_pool',
    'garden',
    'balcony',
    'gym',
    'security',
    'elevator',
    'parking',
    'air_conditioning',
    'heating',
    'furnished',
    'pet_friendly',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAgent();
  }

  Future<void> _loadCurrentAgent() async {
    try {
      final agent = await UserService.getCurrentUserProfile();
      setState(() {
        _currentAgent = agent;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load agent profile: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }
    if (_currentAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent profile not loaded')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String propertyId = const Uuid().v4();

      // Upload images first
      final List<String> imageUrls = await PropertyService.uploadPropertyImages(
          _selectedImages, propertyId);

      // Create property
      final PropertyModel property = PropertyModel(
        id: propertyId,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        location: _locationController.text,
        latitude: 0.0, // TODO: Implement geocoding
        longitude: 0.0, // TODO: Implement geocoding
        address: _addressController.text,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        sqm: double.parse(_sqmController.text),
        propertyType: _propertyType,
        listingType: _listingType,
        imageUrls: imageUrls,
        agentId: _currentAgent!.id,
        agentName: _currentAgent!.fullName,
        agentEmail: _currentAgent!.email,
        agentPhone: _currentAgent!.phone ?? '',
        agentImageUrl: _currentAgent!.profileImageUrl ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        features: _selectedFeatures,
      );

      await PropertyService.createProperty(property);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property uploaded successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload property: $e')),
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
        title: const Text('Upload Property'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Property Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (double.tryParse(value!) == null)
                          return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Property Type and Listing Type
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _propertyType,
                            decoration: const InputDecoration(
                              labelText: 'Property Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _propertyTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _propertyType = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _listingType,
                            decoration: const InputDecoration(
                              labelText: 'Listing Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _listingTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _listingType = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (City, State)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Bedrooms, Bathrooms, SQM
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bedrooms',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bathrooms',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _sqmController,
                            decoration: const InputDecoration(
                              labelText: 'Sq/m',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (double.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Features
                    const Text('Features:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableFeatures.map((feature) {
                        final isSelected = _selectedFeatures.contains(feature);
                        return FilterChip(
                          label:
                              Text(feature.replaceAll('_', ' ').toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFeatures.add(feature);
                              } else {
                                _selectedFeatures.remove(feature);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Images
                    const Text('Images:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImages.isEmpty
                          ? InkWell(
                              onTap: _pickImages,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 48, color: Colors.grey),
                                  Text('Tap to add images'),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _selectedImages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length) {
                                  return InkWell(
                                    onTap: _pickImages,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.grey),
                                    ),
                                  );
                                }
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image:
                                              FileImage(_selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitProperty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E3192),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Upload Property'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _sqmController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }
}
