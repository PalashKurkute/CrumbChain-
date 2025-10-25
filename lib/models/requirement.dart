class Requirement {
  final String id;
  final String userId;
  final String userEmail;
  final String organizationName;
  final String organizationType;
  final String operatingHours;
  final String crowdSize;
  final String? foodPreferenceTag;
  final String? category;
  final String? location;
  final String? contactPerson;
  final String? contactPhone;
  final String? additionalNotes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;

  Requirement({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.organizationName,
    required this.organizationType,
    required this.operatingHours,
    required this.crowdSize,
    this.foodPreferenceTag,
    this.category,
    this.location,
    this.contactPerson,
    this.contactPhone,
    this.additionalNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
  });

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      organizationName: json['organizationName'] ?? '',
      organizationType: json['organizationType'] ?? '',
      operatingHours: json['operatingHours'] ?? '',
      crowdSize: json['crowdSize'] ?? '',
      foodPreferenceTag: json['foodPreferenceTag'],
      category: json['category'],
      location: json['location'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      additionalNotes: json['additionalNotes'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userEmail': userEmail,
      'organizationName': organizationName,
      'organizationType': organizationType,
      'operatingHours': operatingHours,
      'crowdSize': crowdSize,
      'foodPreferenceTag': foodPreferenceTag,
      'category': category,
      'location': location,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'additionalNotes': additionalNotes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
