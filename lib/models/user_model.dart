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
  // Boutique fields
  final String accountType; // 'user' or 'boutique'
  final String? boutiqueName;
  final String? boutiqueLogo;
  final String? boutiqueCover;
  final String? boutiqueDescription;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? snapchatUrl;
  final String? maaroofUrl;
  final String? maaroofCertificateUrl;
  final bool boutiqueActive; // admin can suspend
  final bool showInstagram; // admin controls visibility
  final bool showTiktok;
  final bool showSnapchat;
  final bool showMaaroof;

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
    this.accountType = 'user',
    this.boutiqueName,
    this.boutiqueLogo,
    this.boutiqueCover,
    this.boutiqueDescription,
    this.instagramUrl,
    this.tiktokUrl,
    this.snapchatUrl,
    this.maaroofUrl,
    this.maaroofCertificateUrl,
    this.boutiqueActive = true,
    this.showInstagram = true,
    this.showTiktok = true,
    this.showSnapchat = true,
    this.showMaaroof = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isBoutique => accountType == 'boutique';

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
    String? accountType,
    String? boutiqueName,
    String? boutiqueLogo,
    String? boutiqueCover,
    String? boutiqueDescription,
    String? instagramUrl,
    String? tiktokUrl,
    String? snapchatUrl,
    String? maaroofUrl,
    String? maaroofCertificateUrl,
    bool? boutiqueActive,
    bool? showInstagram,
    bool? showTiktok,
    bool? showSnapchat,
    bool? showMaaroof,
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
      accountType: accountType ?? this.accountType,
      boutiqueName: boutiqueName ?? this.boutiqueName,
      boutiqueLogo: boutiqueLogo ?? this.boutiqueLogo,
      boutiqueCover: boutiqueCover ?? this.boutiqueCover,
      boutiqueDescription: boutiqueDescription ?? this.boutiqueDescription,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      snapchatUrl: snapchatUrl ?? this.snapchatUrl,
      maaroofUrl: maaroofUrl ?? this.maaroofUrl,
      maaroofCertificateUrl: maaroofCertificateUrl ?? this.maaroofCertificateUrl,
      boutiqueActive: boutiqueActive ?? this.boutiqueActive,
      showInstagram: showInstagram ?? this.showInstagram,
      showTiktok: showTiktok ?? this.showTiktok,
      showSnapchat: showSnapchat ?? this.showSnapchat,
      showMaaroof: showMaaroof ?? this.showMaaroof,
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
      'accountType': accountType,
      'boutiqueName': boutiqueName,
      'boutiqueLogo': boutiqueLogo,
      'boutiqueCover': boutiqueCover,
      'boutiqueDescription': boutiqueDescription,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'snapchatUrl': snapchatUrl,
      'maaroofUrl': maaroofUrl,
      'maaroofCertificateUrl': maaroofCertificateUrl,
      'boutiqueActive': boutiqueActive,
      'showInstagram': showInstagram,
      'showTiktok': showTiktok,
      'showSnapchat': showSnapchat,
      'showMaaroof': showMaaroof,
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
      accountType: map['accountType'] ?? 'user',
      boutiqueName: map['boutiqueName'],
      boutiqueLogo: map['boutiqueLogo'],
      boutiqueCover: map['boutiqueCover'],
      boutiqueDescription: map['boutiqueDescription'],
      instagramUrl: map['instagramUrl'],
      tiktokUrl: map['tiktokUrl'],
      snapchatUrl: map['snapchatUrl'],
      maaroofUrl: map['maaroofUrl'],
      maaroofCertificateUrl: map['maaroofCertificateUrl'],
      boutiqueActive: map['boutiqueActive'] ?? true,
      showInstagram: map['showInstagram'] ?? true,
      showTiktok: map['showTiktok'] ?? true,
      showSnapchat: map['showSnapchat'] ?? true,
      showMaaroof: map['showMaaroof'] ?? true,
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
