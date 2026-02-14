class UserModel{

  final String uid;
  final String email;
  final String name;
  final String shopName;
  final String phone;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.shopName,
    required this.phone,
    required this.role,
    required this.createdAt,});

  Map<String,dynamic> toMap(){

    return {
      'uid': uid,
      'name': name,
      'email': email,
      'shop_name': shopName,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String,dynamic>map){
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      shopName: map['shop_name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Admin',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }




}