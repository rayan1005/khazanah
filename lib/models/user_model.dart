import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? whatsapp;
  final String city;
  final String? photoUrl;
  final String role; // 'user' or 'admin'
  final bool isBanned;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.whatsapp,
    required this.city,
    this.photoUrl,
    this.role = 'user',
    this.isBanned = false,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? whatsapp,
    String? city,
    String? photoUrl,
    String? role,
    bool? isBanned,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'city': city,
      'photoUrl': photoUrl,
      'role': role,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'],
      city: map['city'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
      isBanned: map['isBanned'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
