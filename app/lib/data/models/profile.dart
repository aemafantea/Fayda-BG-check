class Profile {
  final String id;
  final String role; // admin | hr | candidate
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? faydaFcn;
  final String? faydaFin;
  final DateTime? faydaVerifiedAt;
  final String? faydaVerificationStatus;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? organizationId;

  Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.faydaFcn,
    this.faydaFin,
    this.faydaVerifiedAt,
    this.faydaVerificationStatus,
    this.dateOfBirth,
    this.gender,
    this.organizationId,
  });

  bool get isFaydaVerified => faydaVerificationStatus == 'verified';

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        role: (m['role'] ?? 'candidate') as String,
        fullName: m['full_name'] as String?,
        phone: m['phone'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        faydaFcn: m['fayda_fcn'] as String?,
        faydaFin: m['fayda_fin'] as String?,
        faydaVerifiedAt: m['fayda_verified_at'] != null ? DateTime.tryParse(m['fayda_verified_at']) : null,
        faydaVerificationStatus: m['fayda_verification_status'] as String?,
        dateOfBirth: m['date_of_birth'] != null ? DateTime.tryParse(m['date_of_birth']) : null,
        gender: m['gender'] as String?,
        organizationId: m['organization_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'fayda_fcn': faydaFcn,
        'fayda_fin': faydaFin,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'organization_id': organizationId,
      }..removeWhere((_, v) => v == null);
}
