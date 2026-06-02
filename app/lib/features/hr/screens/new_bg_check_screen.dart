import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
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
  late Future<List<Map<String, dynamic>>> _candidatesFuture;
  String? _err;

  final _allTypes = const [
    'identity', 'employment_history', 'education', 'criminal_record',
    'reference', 'credit', 'driving_record'
  ];

  @override
  void initState() {
    super.initState();
    _candidatesFuture = _loadCandidates();
  }

  Future<List<Map<String, dynamic>>> _loadCandidates() async {
    try {
      final r = await Supabase.instance.client
          .from('v_candidate_summary')
          .select()
          .limit(100);
      return (r as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _create() async {
    if (_candidateId == null) return;
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
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
    } catch (e) {
      setState(() {
        _saving = false;
        _err = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New background check')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _candidatesFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cands = snap.data ?? const [];
          if (cands.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    const Text('No candidates found',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Candidates appear after they sign up and have a profile row. '
                      'Make sure the Supabase schema migrations are applied.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _candidatesFuture = _loadCandidates()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Select candidate',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _candidateId,
                isExpanded: true,
                items: cands
                    .map((c) => DropdownMenuItem(
                          value: c['candidate_id'] as String,
                          child: Text(
                            '${c['full_name']} '
                            '(${c['fayda_verification_status'] ?? 'pending'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _candidateId = v),
                decoration: const InputDecoration(hintText: 'Choose candidate…'),
              ),
              const SizedBox(height: 20),
              const Text('Check types',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _allTypes
                    .map((t) => FilterChip(
                          label: Text(t.replaceAll('_', ' ')),
                          selected: _types.contains(t),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _types.add(t);
                            } else {
                              _types.remove(t);
                            }
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)')),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving || _candidateId == null ? null : _create,
                icon: const Icon(Icons.send),
                label: _saving
                    ? const Text('Creating…')
                    : const Text('Create & submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
