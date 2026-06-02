import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/status_badge.dart';

class CandidateDetailScreen extends ConsumerStatefulWidget {
  final String candidateId;
  const CandidateDetailScreen({super.key, required this.candidateId});
  @override
  ConsumerState<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends ConsumerState<CandidateDetailScreen> {
  Future<Map<String,dynamic>?> _loadAll() async {
    final sb = Supabase.instance.client;
    final cand = await sb.from('candidates').select('*, profiles(*)').eq('id', widget.candidateId).maybeSingle();
    if (cand == null) return null;
    final emp = await sb.from('employment_history').select().eq('candidate_id', widget.candidateId).order('start_date', ascending: false);
    final checks = await sb.from('background_checks').select().eq('candidate_id', widget.candidateId).order('created_at', ascending: false);
    final docs = await sb.from('documents').select().eq('owner_id', cand['profile_id']);
    return {'cand': cand, 'emp': emp, 'checks': checks, 'docs': docs};
  }

  Future<void> _verifyJob(String jobId) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Verification notes'),
          content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Notes…')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Verify')),
          ],
        );
      },
    );
    if (notes == null) return;
    final uid = Supabase.instance.client.auth.currentUser!.id;
    await ref.read(bgCheckRepoProvider).verifyEmployment(jobId, uid, notes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidate')),
      body: FutureBuilder(
        future: _loadAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data;
          if (data == null) return const Center(child: Text('Not found'));
          final cand = data['cand'] as Map;
          final prof = cand['profiles'] as Map;
          final emp = (data['emp'] as List).cast<Map>();
          final checks = (data['checks'] as List).cast<Map>();
          final docs = (data['docs'] as List).cast<Map>();
          final fmt = DateFormat.yMMM();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text((prof['full_name'] ?? '?').toString().characters.first)),
                  title: Text(prof['full_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Phone: ${prof['phone'] ?? '—'}'),
                    Text('FCN: ${prof['fayda_fcn'] ?? '—'}'),
                  ]),
                  trailing: StatusBadge.fromStatus(prof['fayda_verification_status']),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.add_task),
                onPressed: () => context.go('/hr/new-check?candidate=${widget.candidateId}'),
                label: const Text('Start new background check'),
              ),
              const SizedBox(height: 16),
              const Text('Background checks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              ...checks.map((b) => Card(
                    child: ListTile(
                      title: Text('Check #${(b['id'] as String).substring(0,8)}'),
                      subtitle: Text('Created ${DateTime.parse(b['created_at']).toLocal()}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        StatusBadge.fromStatus(b['status']),
                        const SizedBox(width: 6),
                        StatusBadge.fromRisk(b['risk_level']),
                      ]),
                      onTap: () => context.go('/hr/check/${b['id']}'),
                    ),
                  )),
              const SizedBox(height: 16),
              Text('Employment history (${emp.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              ...emp.map((e) => Card(
                    child: ListTile(
                      title: Text('${e['position_title']} @ ${e['employer_name']}'),
                      subtitle: Text('${fmt.format(DateTime.parse(e['start_date']))} → ${e['end_date'] != null ? fmt.format(DateTime.parse(e['end_date'])) : 'present'}'),
                      trailing: e['verified'] == true
                          ? const StatusBadge(label: 'verified', color: AppTheme.success)
                          : TextButton(onPressed: () => _verifyJob(e['id']), child: const Text('Verify')),
                    ),
                  )),
              const SizedBox(height: 16),
              Text('Documents (${docs.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              ...docs.map((d) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(d['file_name']),
                      subtitle: Text(d['doc_type']),
                      trailing: d['is_verified'] == true
                          ? const Icon(Icons.verified, color: AppTheme.success) : null,
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
