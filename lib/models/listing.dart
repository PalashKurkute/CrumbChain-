class Listing {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String foodType;
  final String description;
  final String quantity;
  final String? datePrepared;
  final String dietaryTag;
  final String temperatureStatus;
  final String location;
  final String? pickupTime;
  final String packagingType;
  final bool isPaidDonation;
  final double amount;
  final String imageUrl;
  final String status; // active, claimed, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional: Geographic coordinates if available
  final double? latitude;
  final double? longitude;
  
  // Donor rating information
  final double? donorRating;
  final int? donorTotalRatings;

  // Claim information (when order is claimed)
  final String? claimedBy;
  final String? claimedByEmail;
  final String? claimedByName;
  final DateTime? claimedAt;
  final String? orderStatus; // pending_approval, approved, in_transit, out_for_delivery, delivered, completed

  Listing({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.foodType,
    required this.description,
    required this.quantity,
    this.datePrepared,
    required this.dietaryTag,
    required this.temperatureStatus,
    required this.location,
    this.pickupTime,
    required this.packagingType,
    required this.isPaidDonation,
    required this.amount,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.donorRating,
    this.donorTotalRatings,
    this.claimedBy,
    this.claimedByEmail,
    this.claimedByName,
    this.claimedAt,
    this.orderStatus,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      userName: json['userName'] as String? ?? '',
      foodType: json['foodType'] as String,
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as String,
      datePrepared: json['datePrepared'] as String?,
      dietaryTag: json['dietaryTag'] as String,
      temperatureStatus: json['temperatureStatus'] as String,
      location: json['location'] as String,
      pickupTime: json['pickupTime'] as String?,
      packagingType: json['packagingType'] as String,
      isPaidDonation: json['isPaidDonation'] as bool? ?? false,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      donorRating: (json['donorRating'] as num?)?.toDouble(),
      donorTotalRatings: json['donorTotalRatings'] as int?,
      claimedBy: json['claimedBy'] as String?,
      claimedByEmail: json['claimedByEmail'] as String?,
      claimedByName: json['claimedByName'] as String?,
      claimedAt: json['claimedAt'] is String
          ? DateTime.parse(json['claimedAt'])
          : null,
      orderStatus: json['orderStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'foodType': foodType,
      'description': description,
      'quantity': quantity,
      'datePrepared': datePrepared,
      'dietaryTag': dietaryTag,
      'temperatureStatus': temperatureStatus,
      'location': location,
      'pickupTime': pickupTime,
      'packagingType': packagingType,
      'isPaidDonation': isPaidDonation,
      'amount': amount,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  bool get isActive => status == 'active';
  bool get isClaimed => status == 'claimed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
