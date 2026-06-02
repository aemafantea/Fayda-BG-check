import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/bg_check_repository.dart';

class NewBgCheckScreen extends ConsumerStatefulWidget {
  const NewBgCheckScreen({super.key});
  @override
  ConsumerState<NewBgCheckScreen> createState() => _NewBgCheckScreenState();
}

class _NewBgCheckScreenState extends ConsumerState<NewBgCheckScreen> {
  String? _candidateId;
  final _types = <String>{'identity', 'employment_history'};
  final _notes = TextEditingController();
  bool _saving = false;

  final _allTypes = const [
    'identity','employment_history','education','criminal_record','reference','credit','driving_record'
  ];

  Future<List<Map<String,dynamic>>> _candidates() async {
    final r = await Supabase.instance.client.from('v_candidate_summary').select().limit(100);
    return (r as List).cast<Map<String,dynamic>>();
  }

  Future<void> _create() async {
    if (_candidateId == null) return;
    setState(() => _saving = true);
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final bg = await ref.read(bgCheckRepoProvider).createCheck({
      'candidate_id': _candidateId,
      'requested_by': uid,
      'assigned_to': uid,
      'check_types': _types.toList(),
      'status': 'submitted',
      'notes': _notes.text.trim(),
      'submitted_at': DateTime.now().toIso8601String(),
    });
    if (mounted) context.go('/hr/check/${bg.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New background check')),
      body: FutureBuilder(
        future: _candidates(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final cands = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Select candidate', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _candidateId,
                items: cands.map((c) => DropdownMenuItem(
                    value: c['candidate_id'] as String,
                    child: Text('${c['full_name']} (${c['fayda_verification_status'] ?? 'pending'})'))).toList(),
                onChanged: (v) => setState(() => _candidateId = v),
                decoration: const InputDecoration(hintText: 'Choose candidate…'),
              ),
              const SizedBox(height: 20),
              const Text('Check types', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: _allTypes.map((t) => FilterChip(
                    label: Text(t.replaceAll('_',' ')),
                    selected: _types.contains(t),
                    onSelected: (sel) => setState(() => sel ? _types.add(t) : _types.remove(t)),
                  )).toList()),
              const SizedBox(height: 20),
              TextField(controller: _notes, maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving || _candidateId == null ? null : _create,
                icon: const Icon(Icons.send),
                label: const Text('Create & submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
