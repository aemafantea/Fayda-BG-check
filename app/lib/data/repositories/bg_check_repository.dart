import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'auth_repository.dart';

class BgCheckRepository {
  final SupabaseClient _sb;
  BgCheckRepository(this._sb);

  // ---------- Candidate ----------
  Future<Candidate?> getOrCreateCandidate(String profileId) async {
    final found = await _sb.from('candidates').select().eq('profile_id', profileId).maybeSingle();
    if (found != null) return Candidate.fromMap(found);
    final created = await _sb.from('candidates').insert({'profile_id': profileId}).select().single();
    return Candidate.fromMap(created);
  }

  Future<Candidate?> getCandidateById(String id) async {
    final r = await _sb.from('candidates').select().eq('id', id).maybeSingle();
    return r == null ? null : Candidate.fromMap(r);
  }

  Future<void> updateCandidate(String id, Map<String, dynamic> patch) =>
      _sb.from('candidates').update(patch).eq('id', id);

  // ---------- Employment ----------
  Future<List<EmploymentRecord>> listEmployment(String candidateId) async {
    final rows = await _sb.from('employment_history').select().eq('candidate_id', candidateId).order('start_date', ascending: false);
    return (rows as List).map((e) => EmploymentRecord.fromMap(e)).toList();
  }

  Future<EmploymentRecord> addEmployment(Map<String, dynamic> data) async {
    final r = await _sb.from('employment_history').insert(data).select().single();
    return EmploymentRecord.fromMap(r);
  }

  Future<void> updateEmployment(String id, Map<String, dynamic> patch) =>
      _sb.from('employment_history').update(patch).eq('id', id);

  Future<void> deleteEmployment(String id) => _sb.from('employment_history').delete().eq('id', id);

  Future<void> verifyEmployment(String id, String verifierId, String notes) =>
      _sb.from('employment_history').update({
        'verified': true,
        'verified_by': verifierId,
        'verified_at': DateTime.now().toIso8601String(),
        'verification_notes': notes,
      }).eq('id', id);

  // ---------- Background checks ----------
  Future<List<BackgroundCheck>> listChecks({String? candidateId, String? status}) async {
    var q = _sb.from('background_checks').select();
    if (candidateId != null) q = q.eq('candidate_id', candidateId);
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false);
    return (rows as List).map((e) => BackgroundCheck.fromMap(e)).toList();
  }

  Future<BackgroundCheck> createCheck(Map<String, dynamic> data) async {
    final r = await _sb.from('background_checks').insert(data).select().single();
    return BackgroundCheck.fromMap(r);
  }

  Future<BackgroundCheck> getCheck(String id) async {
    final r = await _sb.from('background_checks').select().eq('id', id).single();
    return BackgroundCheck.fromMap(r);
  }

  Future<void> updateCheck(String id, Map<String, dynamic> patch) =>
      _sb.from('background_checks').update(patch).eq('id', id);

  Future<void> giveConsent(String checkId) =>
      _sb.from('background_checks').update({
        'consent_given': true,
        'consent_signed_at': DateTime.now().toIso8601String(),
      }).eq('id', checkId);

  Future<Map<String, dynamic>> runRiskScore(String checkId) async {
    final res = await _sb.functions.invoke('risk-score', body: {'background_check_id': checkId});
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> generateReport(String checkId) async {
    final res = await _sb.functions.invoke('generate-pdf', body: {'background_check_id': checkId});
    return (res.data as Map).cast<String, dynamic>();
  }

  // ---------- Documents ----------
  Future<List<AppDocument>> listDocuments(String ownerId) async {
    final rows = await _sb.from('documents').select().eq('owner_id', ownerId).order('uploaded_at', ascending: false);
    return (rows as List).map((e) => AppDocument.fromMap(e)).toList();
  }

  Future<AppDocument> uploadDocument({
    required String ownerId,
    required String docType,
    required String fileName,
    required List<int> bytes,
    String? mimeType,
    String? backgroundCheckId,
  }) async {
    final path = '$ownerId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await _sb.storage.from('documents').uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );
    final inserted = await _sb.from('documents').insert({
      'owner_id': ownerId,
      'background_check_id': backgroundCheckId,
      'doc_type': docType,
      'file_name': fileName,
      'file_path': path,
      'file_size': bytes.length,
      'mime_type': mimeType,
    }).select().single();
    return AppDocument.fromMap(inserted);
  }

  Future<String> signedDocUrl(String path, {int expiresIn = 600}) async {
    return await _sb.storage.from('documents').createSignedUrl(path, expiresIn);
  }

  Future<void> deleteDocument(AppDocument doc) async {
    await _sb.storage.from('documents').remove([doc.filePath]);
    await _sb.from('documents').delete().eq('id', doc.id);
  }

  // ---------- References ----------
  Future<List<Map<String, dynamic>>> listReferences(String checkId) async {
    final rows = await _sb.from('references').select().eq('background_check_id', checkId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addReference(Map<String, dynamic> data) =>
      _sb.from('references').insert(data);

  Future<void> updateReference(String id, Map<String, dynamic> patch) =>
      _sb.from('references').update(patch).eq('id', id);

  // ---------- Criminal records ----------
  Future<List<Map<String, dynamic>>> listCriminal(String checkId) async {
    final rows = await _sb.from('criminal_records').select().eq('background_check_id', checkId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addCriminal(Map<String, dynamic> data) =>
      _sb.from('criminal_records').insert(data);

  // ---------- HR dashboard ----------
  Future<Map<String, dynamic>> dashboardStats() async {
    final r = await _sb.from('v_hr_dashboard_stats').select().single();
    return r;
  }

  Future<List<Map<String, dynamic>>> candidateSummaries({String? search}) async {
    var q = _sb.from('v_candidate_summary').select();
    if (search != null && search.isNotEmpty) {
      q = q.ilike('full_name', '%$search%');
    }
    final rows = await q.limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

final bgCheckRepoProvider = Provider<BgCheckRepository>(
  (ref) => BgCheckRepository(ref.watch(supabaseProvider)),
);
