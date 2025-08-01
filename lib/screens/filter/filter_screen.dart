import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final String? currentLocation;
  final double? currentMinPrice;
  final double? currentMaxPrice;
  final int? currentBedrooms;
  final int? currentBathrooms;
  final String? currentPropertyType;
  final String? currentListingType;

  const FilterScreen({
    super.key,
    this.currentLocation,
    this.currentMinPrice,
    this.currentMaxPrice,
    this.currentBedrooms,
    this.currentBathrooms,
    this.currentPropertyType,
    this.currentListingType,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late TextEditingController _locationController;
  late RangeValues _priceRange;
  int? _selectedBedrooms;
  int? _selectedBathrooms;
  String? _selectedPropertyType;
  String? _selectedListingType;

  final double _minPrice = 0;
  final double _maxPrice = 10000;

  final List<String> _propertyTypes = ['house', 'apartment', 'condo', 'villa', 'studio'];
  final List<String> _listingTypes = ['rent', 'sale'];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.currentLocation ?? '');
    _priceRange = RangeValues(
      widget.currentMinPrice ?? _minPrice,
      widget.currentMaxPrice ?? _maxPrice,
    );
    _selectedBedrooms = widget.currentBedrooms;
    _selectedBathrooms = widget.currentBathrooms;
    _selectedPropertyType = widget.currentPropertyType;
    _selectedListingType = widget.currentListingType;
  }

  void _applyFilters() {
    final filters = {
      'location': _locationController.text.isEmpty ? null : _locationController.text,
      'minPrice': _priceRange.start == _minPrice ? null : _priceRange.start,
      'maxPrice': _priceRange.end == _maxPrice ? null : _priceRange.end,
      'bedrooms': _selectedBedrooms,
      'bathrooms': _selectedBathrooms,
      'propertyType': _selectedPropertyType,
      'listingType': _selectedListingType,
    };

    Navigator.pop(context, filters);
  }

  void _clearFilters() {
    setState(() {
      _locationController.clear();
      _priceRange = RangeValues(_minPrice, _maxPrice);
      _selectedBedrooms = null;
      _selectedBathrooms = null;
      _selectedPropertyType = null;
      _selectedListingType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter city or area',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 100,
                    labels: RangeLabels(
                      '₦${_priceRange.start.round()}',
                      '₦${_priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₦${_priceRange.start.round()}'),
                      Text('₦${_priceRange.end.round()}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Property Type
                  const Text(
                    'Property Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _propertyTypes.map((type) {
                      final isSelected = _selectedPropertyType == type;
                      return FilterChip(
                        label: Text(type.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPropertyType = selected ? type : null;
                          });
                        },
                        selectedColor: const Color(0xFF2E3192).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF2E3192),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Listing Type
                  const Text(
                    'Listing Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _listingTypes.map((type) {
                      final isSelected = _selectedListingType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('FOR ${type.toUpperCase()}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedListingType = selected ? type : null;
                              });
                            },
                            selectedColor: const Color(0xFF2E3192).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF2E3192),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Bedrooms
                  const Text(
                    'Bedrooms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRoomSelector('Any', null, _selectedBedrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('1', 1, _selectedBedrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('2', 2, _selectedBedrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('3', 3, _selectedBedrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('4+', 4, _selectedBedrooms),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bathrooms
                  const Text(
                    'Bathrooms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRoomSelector('Any', null, _selectedBathrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('1', 1, _selectedBathrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('2', 2, _selectedBathrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('3', 3, _selectedBathrooms),
                      const SizedBox(width: 8),
                      _buildRoomSelector('4+', 4, _selectedBathrooms),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3192),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector(String label, int? value, int? currentValue) {
    final isSelected = currentValue == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (label == 'Bedrooms') {
              _selectedBedrooms = isSelected ? null : value;
            } else {
              _selectedBathrooms = isSelected ? null : value;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E3192) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E3192) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
