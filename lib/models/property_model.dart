import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final double latitude;
  final double longitude;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final double sqm;
  final String propertyType; // house, apartment, condo
  final String listingType; // rent, sale
  final List<String> imageUrls;
  final String agentId;
  final String agentName;
  final String agentEmail;
  final String agentPhone;
  final String agentImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> features; // garage, pool, garden, etc.
  final double rating;
  final int reviewCount;
  final bool isActive;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.sqm,
    required this.propertyType,
    required this.listingType,
    required this.imageUrls,
    required this.agentId,
    required this.agentName,
    required this.agentEmail,
    required this.agentPhone,
    required this.agentImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.features,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sqm': sqm,
      'propertyType': propertyType,
      'listingType': listingType,
      'imageUrls': imageUrls,
      'agentId': agentId,
      'agentName': agentName,
      'agentEmail': agentEmail,
      'agentPhone': agentPhone,
      'agentImageUrl': agentImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'features': features,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      sqm: (map['sqm'] ?? 0.0).toDouble(),
      propertyType: map['propertyType'] ?? '',
      listingType: map['listingType'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      agentId: map['agentId'] ?? '',
      agentName: map['agentName'] ?? '',
      agentEmail: map['agentEmail'] ?? '',
      agentPhone: map['agentPhone'] ?? '',
      agentImageUrl: map['agentImageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      features: List<String>.from(map['features'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PropertyModel.fromMap(data);
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    double? latitude,
    double? longitude,
    String? address,
    int? bedrooms,
    int? bathrooms,
    double? sqm,
    String? propertyType,
    String? listingType,
    List<String>? imageUrls,
    String? agentId,
    String? agentName,
    String? agentEmail,
    String? agentPhone,
    String? agentImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? features,
    double? rating,
    int? reviewCount,
    bool? isActive,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      sqm: sqm ?? this.sqm,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      imageUrls: imageUrls ?? this.imageUrls,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      agentEmail: agentEmail ?? this.agentEmail,
      agentPhone: agentPhone ?? this.agentPhone,
      agentImageUrl: agentImageUrl ?? this.agentImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      features: features ?? this.features,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
