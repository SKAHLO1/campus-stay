import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../services/property_service.dart';
import '../../services/user_service.dart';
import 'property_detail_screen.dart';
import '../filter/filter_screen.dart';
import '../chat/chat_room_screen.dart';
import '../../services/chat_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _filteredProperties = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Filter variables
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;
  int? _selectedBedrooms;
  int? _selectedBathrooms;
  String? _selectedPropertyType;
  String? _selectedListingType;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all properties
      PropertyService.getAllProperties().listen((properties) {
        setState(() {
          _allProperties = properties;
          _applyFilters();
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load properties: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<PropertyModel> filtered = _allProperties;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) {
        return property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               property.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               property.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((property) {
        return property.location.toLowerCase().contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

    // Apply price filters
    if (_minPrice != null) {
      filtered = filtered.where((property) => property.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((property) => property.price <= _maxPrice!).toList();
    }

    // Apply bedroom filter
    if (_selectedBedrooms != null) {
      filtered = filtered.where((property) => property.bedrooms == _selectedBedrooms).toList();
    }

    // Apply bathroom filter
    if (_selectedBathrooms != null) {
      filtered = filtered.where((property) => property.bathrooms == _selectedBathrooms).toList();
    }

    // Apply property type filter
    if (_selectedPropertyType != null && _selectedPropertyType!.isNotEmpty) {
      filtered = filtered.where((property) => property.propertyType == _selectedPropertyType).toList();
    }

    // Apply listing type filter
    if (_selectedListingType != null && _selectedListingType!.isNotEmpty) {
      filtered = filtered.where((property) => property.listingType == _selectedListingType).toList();
    }

    setState(() {
      _filteredProperties = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _showFilterDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterScreen(
        currentLocation: _selectedLocation,
        currentMinPrice: _minPrice,
        currentMaxPrice: _maxPrice,
        currentBedrooms: _selectedBedrooms,
        currentBathrooms: _selectedBathrooms,
        currentPropertyType: _selectedPropertyType,
        currentListingType: _selectedListingType,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'];
        _minPrice = result['minPrice'];
        _maxPrice = result['maxPrice'];
        _selectedBedrooms = result['bedrooms'];
        _selectedBathrooms = result['bathrooms'];
        _selectedPropertyType = result['propertyType'];
        _selectedListingType = result['listingType'];
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search Properties'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search properties...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E3192)),
                ),
              ),
            ),
          ),

          // Filter Chips and Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('House'),
                        _buildFilterChip('Apartment'),
                        _buildFilterChip('Condo'),
                        _buildFilterChip('For Rent'),
                        _buildFilterChip('For Sale'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_filteredProperties.length} ${_filteredProperties.length == 1 ? 'result' : 'results'} found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Properties List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No properties found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          return _buildPropertyCard(_filteredProperties[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = false;
    
    // Determine if chip is selected based on current filters
    switch (label.toLowerCase()) {
      case 'house':
        isSelected = _selectedPropertyType == 'house';
        break;
      case 'apartment':
        isSelected = _selectedPropertyType == 'apartment';
        break;
      case 'condo':
        isSelected = _selectedPropertyType == 'condo';
        break;
      case 'for rent':
        isSelected = _selectedListingType == 'rent';
        break;
      case 'for sale':
        isSelected = _selectedListingType == 'sale';
        break;
      case 'all':
        isSelected = _selectedPropertyType == null && _selectedListingType == null;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            switch (label.toLowerCase()) {
              case 'house':
                _selectedPropertyType = selected ? 'house' : null;
                break;
              case 'apartment':
                _selectedPropertyType = selected ? 'apartment' : null;
                break;
              case 'condo':
                _selectedPropertyType = selected ? 'condo' : null;
                break;
              case 'for rent':
                _selectedListingType = selected ? 'rent' : null;
                break;
              case 'for sale':
                _selectedListingType = selected ? 'sale' : null;
                break;
              case 'all':
                _selectedPropertyType = null;
                _selectedListingType = null;
                break;
            }
          });
          _applyFilters();
        },
        selectedColor: const Color(0xFF2E3192).withOpacity(0.2),
        checkmarkColor: const Color(0xFF2E3192),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                      child: const Center(
                        child: Icon(Icons.home, size: 48, color: Colors.grey),
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: property.listingType == 'rent' ? Colors.blue : Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'FOR ${property.listingType.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${property.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF2E3192),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPropertySpec(Icons.bed, '${property.bedrooms}'),
                      const SizedBox(width: 16),
                      _buildPropertySpec(Icons.bathroom, '${property.bathrooms}'),
                      const SizedBox(width: 16),
                      _buildPropertySpec(Icons.square_foot, '${property.sqm.toInt()}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySpec(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
