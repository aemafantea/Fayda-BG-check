import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.fromStatus(String? status) {
    switch (status) {
      case 'verified':
      case 'completed':
        return StatusBadge(label: status!, color: AppTheme.success);
      case 'in_review':
      case 'submitted':
      case 'pending':
        return StatusBadge(label: status!, color: AppTheme.warning);
      case 'rejected':
      case 'failed':
      case 'expired':
        return StatusBadge(label: status!, color: AppTheme.danger);
      default:
        return StatusBadge(label: status ?? '—', color: AppTheme.textSecondary);
    }
  }

  factory StatusBadge.fromRisk(String? risk) {
    switch (risk) {
      case 'low':      return const StatusBadge(label: 'LOW', color: AppTheme.success);
      case 'medium':   return const StatusBadge(label: 'MEDIUM', color: AppTheme.warning);
      case 'high':     return const StatusBadge(label: 'HIGH', color: AppTheme.danger);
      case 'critical': return const StatusBadge(label: 'CRITICAL', color: Colors.black87);
      default:         return const StatusBadge(label: '—', color: AppTheme.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: .5),
      ),
    );
  }
}
