import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/bg_check_repository.dart';
import '../../shared/widgets/status_badge.dart';

class BgCheckDetailScreen extends ConsumerStatefulWidget {
  final String checkId;
  const BgCheckDetailScreen({super.key, required this.checkId});
  @override
  ConsumerState<BgCheckDetailScreen> createState() =>
      _BgCheckDetailScreenState();
}

class _BgCheckDetailScreenState extends ConsumerState<BgCheckDetailScreen> {
  bool _busy = false;
  Future<_BgData?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BgData?> _load() async {
    final repo = ref.read(bgCheckRepoProvider);
    final bg = await repo.getCheck(widget.checkId);
    if (bg == null) return null;
    final refs = await repo.listReferences(widget.checkId);
    final crims = await repo.listCriminal(widget.checkId);
    return _BgData(bg: bg, refs: refs, crims: crims);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _runRisk() async {
    setState(() => _busy = true);
    try {
      await ref.read(bgCheckRepoProvider).runRiskScore(widget.checkId);
      _refresh();
    } catch (e) {
      _snack('Risk score failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(bgCheckRepoProvider).generateReport(widget.checkId);
      final url = r['report_url'] as String?;
      if (url != null && mounted) await launchUrl(Uri.parse(url));
      _refresh();
    } catch (e) {
      _snack('Report failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _addReference() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(bgCheckRepoProvider).addReference({
          'background_check_id': widget.checkId,
          'referee_name': name.text,
          'referee_email': email.text,
          'referee_phone': phone.text,
        });
        _refresh();
      } catch (e) {
        _snack('Could not add: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background check')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<_BgData?>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data;
            if (data == null) {
              return const Center(child: Text('Check not found'));
            }
            return _build(data);
          },
        ),
      ),
    );
  }

  Widget _build(_BgData data) {
    final bg = data.bg;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Check #${bg.id.substring(0, 8)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18)),
                    const Spacer(),
                    StatusBadge.fromStatus(bg.status),
                  ],
                ),
                const SizedBox(height: 8),
                if (bg.checkTypes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: bg.checkTypes
                        .map((t) => Chip(label: Text(t.replaceAll('_', ' '))))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Risk: '),
                    StatusBadge.fromRisk(bg.riskLevel),
                    const SizedBox(width: 8),
                    if (bg.riskScore != null)
                      Text('${bg.riskScore}/100',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: _busy ? null : _runRisk,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Run risk score'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _busy ? null : _generateReport,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate report'))),
          ],
        ),
        const SizedBox(height: 16),
        if (bg.riskFactors.isNotEmpty) ...[
          const Text('Risk factors',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...bg.riskFactors.map<Widget>((f) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.warning.withOpacity(.15),
                      child: Text('${f['weight']}',
                          style: const TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w700))),
                  title: Text(
                      f['code']?.toString().replaceAll('_', ' ') ?? ''),
                  subtitle: Text(f['description'] ?? ''),
                ),
              )),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Text('References',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
                onPressed: _addReference,
                icon: const Icon(Icons.add),
                label: const Text('Add')),
          ],
        ),
        if (data.refs.isEmpty)
          const Card(child: ListTile(title: Text('No references yet'))),
        ...data.refs.map((r) => Card(
              child: ListTile(
                title: Text(r['referee_name'] ?? '—'),
                subtitle: Text(
                    '${r['referee_email'] ?? ''}\n${r['referee_phone'] ?? ''}'),
                isThreeLine: true,
                trailing: r['response_received'] == true
                    ? const StatusBadge(
                        label: 'replied', color: AppTheme.success)
                    : const StatusBadge(
                        label: 'pending', color: AppTheme.warning),
              ),
            )),
        const SizedBox(height: 16),
        const Text('Criminal record',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ...data.crims.map((c) => Card(
            child: ListTile(
              title: Text(c['jurisdiction'] ?? '—'),
              subtitle:
                  Text(c['has_records'] == true ? 'Records found' : 'No records'),
              trailing: StatusBadge.fromStatus(c['status']?.toString()),
            ))),
        if (data.crims.isEmpty)
          Card(
            child: ListTile(
              title: const Text('No criminal record check yet'),
              trailing: TextButton(
                onPressed: () async {
                  try {
                    await ref.read(bgCheckRepoProvider).addCriminal({
                      'background_check_id': widget.checkId,
                      'jurisdiction': 'Ethiopia',
                      'has_records': false,
                      'status': 'pending',
                    });
                    _refresh();
                  } catch (e) {
                    _snack('Could not request: $e');
                  }
                },
                child: const Text('Request'),
              ),
            ),
          ),
      ],
    );
  }
}

class _BgData {
  final BackgroundCheck bg;
  final List<Map<String, dynamic>> refs;
  final List<Map<String, dynamic>> crims;
  _BgData({required this.bg, required this.refs, required this.crims});
}
