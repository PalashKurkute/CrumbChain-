class User {
  final String id;
  final String email;
  final String fullName;
  final String userType; // 'Donor' or 'Receiver'

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['name'] as String,
      userType: json['userType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': fullName, 'userType': userType};
  }

  bool get isDonor => userType.toLowerCase() == 'donor';
  bool get isReceiver => userType.toLowerCase() == 'receiver';
}
