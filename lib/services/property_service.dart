import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/property_model.dart';

class PropertyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'properties';

  // Create a new property
  static Future<String> createProperty(PropertyModel property) async {
    try {
      final docRef = await _firestore.collection(_collection).add(property.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  // Upload images to Firebase Storage
  static Future<List<String>> uploadPropertyImages(List<File> images, String propertyId) async {
    List<String> imageUrls = [];
    
    try {
      for (int i = 0; i < images.length; i++) {
        final String fileName = '${const Uuid().v4()}_${i}.jpg';
        final Reference ref = _storage.ref().child('properties/$propertyId/$fileName');
        
        final UploadTask uploadTask = ref.putFile(images[i]);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Get all properties
  static Stream<List<PropertyModel>> getAllProperties() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .where((property) => property.isActive ?? true)
            .toList());
  }

  // Get properties by agent
  static Stream<List<PropertyModel>> getPropertiesByAgent(String agentId) {
    return _firestore
        .collection(_collection)
        .where('agentId', isEqualTo: agentId)
        .snapshots()
        .map((snapshot) {
          List<PropertyModel> properties = snapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();
          
          // Sort by creation date client-side
          properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return properties;
        });
  }

  // Get nearby properties based on user location
  static Future<List<PropertyModel>> getNearbyProperties(double latitude, double longitude, double radiusInKm) async {
    try {
      // Convert radius from kilometers to degrees (rough approximation)
      double latDelta = radiusInKm / 111.0; // 1 degree ≈ 111 km

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('latitude', isGreaterThan: latitude - latDelta)
          .where('latitude', isLessThan: latitude + latDelta)
          .get();

      List<PropertyModel> allProperties = snapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .where((property) => property.isActive ?? true)
          .toList();

      // Filter by longitude and calculate exact distance
      List<PropertyModel> nearbyProperties = [];
      for (PropertyModel property in allProperties) {
        double distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          property.latitude,
          property.longitude,
        ) / 1000; // Convert to kilometers

        if (distance <= radiusInKm) {
          nearbyProperties.add(property);
        }
      }

      // Sort by distance
      nearbyProperties.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(latitude, longitude, a.latitude, a.longitude);
        double distanceB = Geolocator.distanceBetween(latitude, longitude, b.latitude, b.longitude);
        return distanceA.compareTo(distanceB);
      });

      return nearbyProperties;
    } catch (e) {
      throw Exception('Failed to get nearby properties: $e');
    }
  }

  // Search properties
  static Future<List<PropertyModel>> searchProperties({
    String? query,
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? propertyType,
    String? listingType,
  }) async {
    try {
      Query queryRef = _firestore.collection(_collection);

      // Start with the most selective filter
      if (propertyType != null && propertyType.isNotEmpty) {
        queryRef = queryRef.where('propertyType', isEqualTo: propertyType);
      } else if (listingType != null && listingType.isNotEmpty) {
        queryRef = queryRef.where('listingType', isEqualTo: listingType);
      } else if (bedrooms != null) {
        queryRef = queryRef.where('bedrooms', isEqualTo: bedrooms);
      } else if (bathrooms != null) {
        queryRef = queryRef.where('bathrooms', isEqualTo: bathrooms);
      }

      final QuerySnapshot snapshot = await queryRef.get();
      List<PropertyModel> properties = snapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .where((property) => property.isActive ?? true)
          .toList();

      // Apply client-side filtering for remaining criteria
      if (location != null && location.isNotEmpty) {
        properties = properties.where((property) =>
            property.location.toLowerCase().contains(location.toLowerCase())).toList();
      }

      if (minPrice != null) {
        properties = properties.where((property) => property.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        properties = properties.where((property) => property.price <= maxPrice).toList();
      }

      if (bedrooms != null && (propertyType == null || propertyType.isEmpty)) {
        properties = properties.where((property) => property.bedrooms == bedrooms).toList();
      }

      if (bathrooms != null && (propertyType == null || propertyType.isEmpty) && bedrooms == null) {
        properties = properties.where((property) => property.bathrooms == bathrooms).toList();
      }

      if (propertyType != null && propertyType.isNotEmpty && 
          !(queryRef.toString().contains('propertyType'))) {
        properties = properties.where((property) => property.propertyType == propertyType).toList();
      }

      if (listingType != null && listingType.isNotEmpty && 
          !(queryRef.toString().contains('listingType')) && 
          (propertyType == null || propertyType.isEmpty)) {
        properties = properties.where((property) => property.listingType == listingType).toList();
      }

      // Filter by title if query is provided
      if (query != null && query.isNotEmpty) {
        properties = properties.where((property) =>
            property.title.toLowerCase().contains(query.toLowerCase()) ||
            property.description.toLowerCase().contains(query.toLowerCase())).toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Update property
  static Future<void> updateProperty(String propertyId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _firestore.collection(_collection).doc(propertyId).update(updates);
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  // Delete property
  static Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection(_collection).doc(propertyId).update({
        'isActive': false,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  // Get property by ID
  static Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(propertyId).get();
      if (doc.exists) {
        return PropertyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get property: $e');
    }
  }
}


