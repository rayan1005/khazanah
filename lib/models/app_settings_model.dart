import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final double commissionRate; // e.g. 4.0 = 4%
  final String bankName;
  final String bankAccount;
  final String photoWarningText;
  final String mediatorWarningText;
  final String termsAndConditions;
  final String privacyPolicy;
  final String supportEmail;

  const AppSettingsModel({
    this.commissionRate = 4.0,
    this.bankName = '',
    this.bankAccount = '',
    this.photoWarningText = 'يمنع نشر الصور العارية أو المخالفة',
    this.mediatorWarningText = 'تطبيق خزانة وسيط بين البائع والمشتري ولا يتحمل مسؤولية أي عملية بيع أو شراء',
    this.termsAndConditions = '',
    this.privacyPolicy = '',
    this.supportEmail = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'commissionRate': commissionRate,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'photoWarningText': photoWarningText,
      'mediatorWarningText': mediatorWarningText,
      'termsAndConditions': termsAndConditions,
      'privacyPolicy': privacyPolicy,
      'supportEmail': supportEmail,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 4.0,
      bankName: map['bankName'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
      photoWarningText: map['photoWarningText'] ?? 'يمنع نشر الصور العارية أو المخالفة',
      mediatorWarningText: map['mediatorWarningText'] ?? 'تطبيق خزانة وسيط بين البائع والمشتري ولا يتحمل مسؤولية أي عملية بيع أو شراء',
      termsAndConditions: map['termsAndConditions'] ?? '',
      privacyPolicy: map['privacyPolicy'] ?? '',
      supportEmail: map['supportEmail'] ?? '',
    );
  }

  factory AppSettingsModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return const AppSettingsModel();
    return AppSettingsModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  AppSettingsModel copyWith({
    double? commissionRate,
    String? bankName,
    String? bankAccount,
    String? photoWarningText,
    String? mediatorWarningText,
    String? termsAndConditions,
    String? privacyPolicy,
    String? supportEmail,
  }) {
    return AppSettingsModel(
      commissionRate: commissionRate ?? this.commissionRate,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      photoWarningText: photoWarningText ?? this.photoWarningText,
      mediatorWarningText: mediatorWarningText ?? this.mediatorWarningText,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      supportEmail: supportEmail ?? this.supportEmail,
    );
  }
}
