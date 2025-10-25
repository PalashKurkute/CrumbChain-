class User {
  final String id;
  final String email;
  final String fullName;
  final String userType; // 'Donor' or 'Receiver'
  final int rewardPoints;
  final int totalOrdersReceived;
  final double rating;
  final int totalRatings;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.rewardPoints = 0,
    this.totalOrdersReceived = 0,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['name'] as String,
      userType: json['userType'] as String,
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      totalOrdersReceived: json['totalOrdersReceived'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': fullName,
      'userType': userType,
      'rewardPoints': rewardPoints,
      'totalOrdersReceived': totalOrdersReceived,
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  bool get isDonor => userType.toLowerCase() == 'donor';
  bool get isReceiver => userType.toLowerCase() == 'receiver';
}
