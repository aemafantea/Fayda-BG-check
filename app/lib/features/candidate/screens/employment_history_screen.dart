import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/db_status_banner.dart';
import '../../shared/widgets/status_badge.dart';

class EmploymentHistoryScreen extends ConsumerStatefulWidget {
  const EmploymentHistoryScreen({super.key});
  @override
  ConsumerState<EmploymentHistoryScreen> createState() =>
      _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState
    extends ConsumerState<EmploymentHistoryScreen> {
  Candidate? _candidate;
  List<EmploymentRecord> _list = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile == null) {
        setState(() {
          _loading = false;
          _err = 'No profile';
        });
        return;
      }
      final repo = ref.read(bgCheckRepoProvider);
      final c = await repo.getOrCreateCandidate(profile.id);
      final list = c == null ? <EmploymentRecord>[] : await repo.listEmployment(c.id);
      if (!mounted) return;
      setState(() {
        _candidate = c;
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = e.toString();
      });
    }
  }

  Future<void> _openForm({EmploymentRecord? existing}) async {
    if (_candidate == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EmploymentForm(
          existing: existing, candidateId: _candidate!.id),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employment history')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _build(),
      ),
      floatingActionButton: _candidate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }

  Widget _build() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null) {
      return ListView(
        children: [
          const DbStatusBanner(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.danger, size: 48),
                const SizedBox(height: 12),
                Text(_err!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }
    if (_list.isEmpty) {
      return ListView(
        children: [
          const DbStatusBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                const Icon(Icons.work_off,
                    size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                const Text('No employment history yet'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add first job'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final fmt = DateFormat.yMMM();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _list.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) return const DbStatusBanner();
        final e = _list[i - 1];
        return Card(
          child: ListTile(
            title: Text(e.positionTitle,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${e.employerName} • ${fmt.format(e.startDate)} → '
                '${e.endDate == null ? "present" : fmt.format(e.endDate!)}'),
            trailing: e.verified
                ? const StatusBadge(label: 'verified', color: AppTheme.success)
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openForm(existing: e),
                  ),
          ),
        );
      },
    );
  }
}

class _EmploymentForm extends ConsumerStatefulWidget {
  final EmploymentRecord? existing;
  final String candidateId;
  const _EmploymentForm({this.existing, required this.candidateId});
  @override
  ConsumerState<_EmploymentForm> createState() => _EmploymentFormState();
}

class _EmploymentFormState extends ConsumerState<_EmploymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _employer = TextEditingController(text: widget.existing?.employerName);
  late final _position = TextEditingController(text: widget.existing?.positionTitle);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _supName = TextEditingController(text: widget.existing?.supervisorName);
  late final _supPhone = TextEditingController(text: widget.existing?.supervisorPhone);
  late final _supEmail = TextEditingController(text: widget.existing?.supervisorEmail);
  late final _resp = TextEditingController(text: widget.existing?.responsibilities);
  late final _reason = TextEditingController(text: widget.existing?.reasonForLeaving);
  late DateTime? _start = widget.existing?.startDate;
  late DateTime? _end = widget.existing?.endDate;
  late bool _current = widget.existing?.isCurrent ?? widget.existing?.endDate == null;
  bool _saving = false;
  String? _err;

  Future<void> _pickDate(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => start ? _start = d : _end = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null) {
      setState(() => _err = 'Pick a start date');
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    final data = {
      'candidate_id': widget.candidateId,
      'employer_name': _employer.text.trim(),
      'position_title': _position.text.trim(),
      'location': _location.text.trim(),
      'supervisor_name': _supName.text.trim(),
      'supervisor_phone': _supPhone.text.trim(),
      'supervisor_email': _supEmail.text.trim(),
      'responsibilities': _resp.text.trim(),
      'reason_for_leaving': _reason.text.trim(),
      'start_date': _start!.toIso8601String().substring(0, 10),
      'end_date': _current ? null : _end?.toIso8601String().substring(0, 10),
      'is_current': _current,
    };
    try {
      final repo = ref.read(bgCheckRepoProvider);
      if (widget.existing == null) {
        await repo.addEmployment(data);
      } else {
        await repo.updateEmployment(widget.existing!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _err = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existing == null ? 'Add job' : 'Edit job',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employer,
                decoration: const InputDecoration(labelText: 'Employer'),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _position,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_start == null
                          ? 'Start date'
                          : fmt.format(_start!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _current ? null : () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_current
                          ? 'present'
                          : _end == null
                              ? 'End date'
                              : fmt.format(_end!)),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _current,
                onChanged: (v) => setState(() => _current = v ?? false),
                title: const Text('I currently work here'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              const Text('Supervisor (for reference)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supName,
                decoration: const InputDecoration(labelText: 'Supervisor name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supPhone,
                decoration: const InputDecoration(labelText: 'Supervisor phone'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supEmail,
                decoration: const InputDecoration(labelText: 'Supervisor email'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _resp,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Responsibilities'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reason,
                decoration:
                    const InputDecoration(labelText: 'Reason for leaving'),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, style: const TextStyle(color: AppTheme.danger)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
