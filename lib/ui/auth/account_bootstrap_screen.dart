import 'package:flutter/material.dart';

import 'widgets/animated_auth_background.dart';

class AccountBootstrapScreen extends StatelessWidget {
  const AccountBootstrapScreen({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.willReplaceLocalData = false,
  });

  final String title;
  final String message;
  final String? details;
  final bool willReplaceLocalData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedAuthBackground(),
          Container(color: Colors.black.withValues(alpha: 0.28)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08131C).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF9F1C).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: Color(0xFFFFC15D),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.96),
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (details != null && details!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            details!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            minHeight: 8,
                            backgroundColor: Color(0x332EC4B6),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2EC4B6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _InfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Cuenta validada y lista para sincronizar.',
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.library_music_outlined,
                          label: willReplaceLocalData
                              ? 'El respaldo remoto reemplazara tu biblioteca local.'
                              : 'Si encontramos un respaldo, lo cargaremos antes de entrar.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.82),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}
