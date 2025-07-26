import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { user, agent }

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImageUrl;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  
  // Agent-specific fields
  final String? agencyName;
  final String? licenseNumber;
  final String? bio;
  final double? rating;
  final int? reviewCount;
  
  // User preferences
  final String? preferredLocation;
  final double? maxBudget;
  final String? preferredPropertyType;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImageUrl,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.agencyName,
    this.licenseNumber,
    this.bio,
    this.rating,
    this.reviewCount,
    this.preferredLocation,
    this.maxBudget,
    this.preferredPropertyType,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'userType': userType.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isVerified': isVerified,
      'agencyName': agencyName,
      'licenseNumber': licenseNumber,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'preferredLocation': preferredLocation,
      'maxBudget': maxBudget,
      'preferredPropertyType': preferredPropertyType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      userType: UserType.values.firstWhere(
        (e) => e.name == map['userType'],
        orElse: () => UserType.user,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      agencyName: map['agencyName'],
      licenseNumber: map['licenseNumber'],
      bio: map['bio'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
      preferredLocation: map['preferredLocation'],
      maxBudget: map['maxBudget']?.toDouble(),
      preferredPropertyType: map['preferredPropertyType'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? agencyName,
    String? licenseNumber,
    String? bio,
    double? rating,
    int? reviewCount,
    String? preferredLocation,
    double? maxBudget,
    String? preferredPropertyType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      agencyName: agencyName ?? this.agencyName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      maxBudget: maxBudget ?? this.maxBudget,
      preferredPropertyType: preferredPropertyType ?? this.preferredPropertyType,
    );
  }
}
