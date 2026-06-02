export 'profile.dart';

class Candidate {
  final String id;
  final String profileId;
  final String? currentPosition;
  final int? yearsExperience;
  final String? linkedinUrl;
  final String? bio;
  final List<String> skills;
  final List<String> languages;

  Candidate({
    required this.id,
    required this.profileId,
    this.currentPosition,
    this.yearsExperience,
    this.linkedinUrl,
    this.bio,
    this.skills = const [],
    this.languages = const [],
  });

  factory Candidate.fromMap(Map<String, dynamic> m) => Candidate(
        id: m['id'],
        profileId: m['profile_id'],
        currentPosition: m['current_position'],
        yearsExperience: m['years_experience'],
        linkedinUrl: m['linkedin_url'],
        bio: m['bio'],
        skills: (m['skills'] as List?)?.cast<String>() ?? [],
        languages: (m['languages'] as List?)?.cast<String>() ?? [],
      );
}

class EmploymentRecord {
  final String id;
  final String candidateId;
  final String employerName;
  final String positionTitle;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? location;
  final String? responsibilities;
  final String? reasonForLeaving;
  final String? supervisorName;
  final String? supervisorPhone;
  final String? supervisorEmail;
  final num? monthlySalary;
  final bool verified;

  EmploymentRecord({
    required this.id,
    required this.candidateId,
    required this.employerName,
    required this.positionTitle,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    this.responsibilities,
    this.reasonForLeaving,
    this.supervisorName,
    this.supervisorPhone,
    this.supervisorEmail,
    this.monthlySalary,
    this.verified = false,
  });

  factory EmploymentRecord.fromMap(Map<String, dynamic> m) => EmploymentRecord(
        id: m['id'],
        candidateId: m['candidate_id'],
        employerName: m['employer_name'],
        positionTitle: m['position_title'],
        startDate: DateTime.parse(m['start_date']),
        endDate: m['end_date'] != null ? DateTime.parse(m['end_date']) : null,
        isCurrent: m['is_current'] ?? false,
        location: m['location'],
        responsibilities: m['responsibilities'],
        reasonForLeaving: m['reason_for_leaving'],
        supervisorName: m['supervisor_name'],
        supervisorPhone: m['supervisor_phone'],
        supervisorEmail: m['supervisor_email'],
        monthlySalary: m['monthly_salary'],
        verified: m['verified'] ?? false,
      );
}

class BackgroundCheck {
  final String id;
  final String candidateId;
  final String? assignedTo;
  final List<String> checkTypes;
  final String status;
  final String? riskLevel;
  final int? riskScore;
  final List<dynamic> riskFactors;
  final bool consentGiven;
  final String? notes;
  final String? reportUrl;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  BackgroundCheck({
    required this.id,
    required this.candidateId,
    this.assignedTo,
    this.checkTypes = const [],
    required this.status,
    this.riskLevel,
    this.riskScore,
    this.riskFactors = const [],
    this.consentGiven = false,
    this.notes,
    this.reportUrl,
    this.submittedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory BackgroundCheck.fromMap(Map<String, dynamic> m) => BackgroundCheck(
        id: m['id'],
        candidateId: m['candidate_id'],
        assignedTo: m['assigned_to'],
        checkTypes: (m['check_types'] as List?)?.cast<String>() ?? [],
        status: m['status'],
        riskLevel: m['risk_level'],
        riskScore: m['risk_score'],
        riskFactors: (m['risk_factors'] as List?) ?? [],
        consentGiven: m['consent_given'] ?? false,
        notes: m['notes'],
        reportUrl: m['report_url'],
        submittedAt: m['submitted_at'] != null ? DateTime.parse(m['submitted_at']) : null,
        completedAt: m['completed_at'] != null ? DateTime.parse(m['completed_at']) : null,
        createdAt: DateTime.parse(m['created_at']),
      );
}

class AppDocument {
  final String id;
  final String ownerId;
  final String? backgroundCheckId;
  final String docType;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final bool isVerified;
  final DateTime uploadedAt;

  AppDocument({
    required this.id,
    required this.ownerId,
    this.backgroundCheckId,
    required this.docType,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.isVerified = false,
    required this.uploadedAt,
  });

  factory AppDocument.fromMap(Map<String, dynamic> m) => AppDocument(
        id: m['id'],
        ownerId: m['owner_id'],
        backgroundCheckId: m['background_check_id'],
        docType: m['doc_type'],
        fileName: m['file_name'],
        filePath: m['file_path'],
        fileSize: m['file_size'],
        mimeType: m['mime_type'],
        isVerified: m['is_verified'] ?? false,
        uploadedAt: DateTime.parse(m['uploaded_at']),
      );
}

class AppNotification {
  final String id;
  final String title;
  final String? body;
  final String? type;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.type,
    this.link,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'],
        title: m['title'],
        body: m['body'],
        type: m['type'],
        link: m['link'],
        isRead: m['is_read'] ?? false,
        createdAt: DateTime.parse(m['created_at']),
      );
}
