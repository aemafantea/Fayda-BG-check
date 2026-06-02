import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

class FaydaVerifyScreen extends ConsumerStatefulWidget {
  const FaydaVerifyScreen({super.key});
  @override
  ConsumerState<FaydaVerifyScreen> createState() => _FaydaVerifyScreenState();
}

class _FaydaVerifyScreenState extends ConsumerState<FaydaVerifyScreen> {
  final _appLinks = AppLinks();
  bool _loading = false;
  String? _err;
  String? _status;

  @override
  void initState() {
    super.initState();
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    if (code == null || state == null) return;
    setState(() { _loading = true; _status = 'Exchanging code…'; });
    try {
      final sb = ref.read(supabaseProvider);
      final res = await sb.functions.invoke('fayda-oidc-callback',
          body: {'code': code, 'state': state});
      if ((res.data as Map?)?['ok'] == true) {
        setState(() => _status = 'Verified ✓ (FCN •••${(res.data as Map)['fcn_last4']})');
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          context.go('/home');
        }
      } else {
        setState(() => _err = (res.data as Map)['error']?.toString() ?? 'Verification failed');
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startVerification() async {
    setState(() { _loading = true; _err = null; _status = 'Opening Fayda…'; });
    try {
      final sb = ref.read(supabaseProvider);
      final res = await sb.functions.invoke('fayda-oidc-init', body: {});
      final url = (res.data as Map?)?['url'] as String?;
      if (url == null) throw Exception('No URL returned: ${res.data}');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      setState(() => _status = 'Waiting for Fayda to redirect back…');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify with Fayda')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield, color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    Text('Verify your identity',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text(
                      'Use your Fayda National ID to instantly verify your identity. '
                      'This unlocks background check eligibility and protects against fraud.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              profile.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (p) => p?.isFaydaVerified == true
                    ? Card(
                        child: ListTile(
                          leading: const Icon(Icons.verified, color: AppTheme.success),
                          title: const Text('Identity verified'),
                          subtitle: Text('FCN •••${p!.faydaFcn?.substring((p.faydaFcn!.length-4).clamp(0, p.faydaFcn!.length))}'),
                        ),
                      )
                    : const SizedBox(),
              ),
              const Spacer(),
              if (_status != null)
                Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_status!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary))),
              if (_err != null)
                Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_err!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.danger))),
              FilledButton.icon(
                onPressed: _loading ? null : _startVerification,
                icon: const Icon(Icons.shield_outlined),
                label: Text(_loading ? 'Please wait…' : 'Verify with Fayda'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/home'), child: const Text('Skip for now')),
            ],
          ),
        ),
      ),
    );
  }
}
