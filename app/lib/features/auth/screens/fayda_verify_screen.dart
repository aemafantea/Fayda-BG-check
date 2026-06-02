import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

String _last4(String? s) {
  if (s == null || s.isEmpty) return '----';
  return s.length <= 4 ? s : s.substring(s.length - 4);
}

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
    setState(() {
      _loading = true;
      _status = 'Exchanging code…';
    });
    try {
      final sb = ref.read(supabaseProvider);
      final res = await sb.functions.invoke('fayda-oidc-callback',
          body: {'code': code, 'state': state});
      final data = (res.data as Map?) ?? {};
      if (data['ok'] == true) {
        if (!mounted) return;
        setState(() => _status = 'Verified ✓ (FCN •••${data['fcn_last4']})');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/home');
      } else {
        setState(() =>
            _err = data['error']?.toString() ?? 'Verification failed');
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startVerification() async {
    setState(() {
      _loading = true;
      _err = null;
      _status = 'Opening Fayda…';
    });
    try {
      final sb = ref.read(supabaseProvider);
      final res = await sb.functions.invoke('fayda-oidc-init', body: {});
      final url = (res.data as Map?)?['url'] as String?;
      if (url == null) {
        throw Exception(
            'Fayda OIDC is not configured yet (Edge Function did not return a URL). '
            'See docs/DEPLOY.md to set FAYDA_CLIENT_ID / FAYDA_CLIENT_SECRET.');
      }
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
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield, color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    Text('Verify your identity',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
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
                          leading: const Icon(Icons.verified,
                              color: AppTheme.success),
                          title: const Text('Identity verified'),
                          subtitle: Text('FCN •••${_last4(p!.faydaFcn)}'),
                        ),
                      )
                    : const SizedBox(),
              ),
              const Spacer(),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _status!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _err!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ),
              FilledButton.icon(
                onPressed: _loading ? null : _startVerification,
                icon: const Icon(Icons.shield_outlined),
                label: Text(_loading ? 'Please wait…' : 'Verify with Fayda'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
