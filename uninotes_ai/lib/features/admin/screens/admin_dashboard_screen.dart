import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          _ThemeToggle(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Welcome Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome, ${user?.displayName?.split(' ').first ?? 'Admin'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage the UniNotes AI platform.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Platform Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // ─── Admin Action Cards ──────────────────────────────────────────
            _AdminActionCard(
              icon: Icons.account_tree_outlined,
              title: 'Course Structure Editor',
              subtitle:
                  'Create, update, or delete Universities, Faculties, Departments, and Courses.',
              color: AppColors.primary,
              onTap: () => context.push('/admin/course-editor'),
            ),
            const SizedBox(height: 12),
            _AdminActionCard(
              icon: Icons.shield_outlined,
              title: 'Content Moderation',
              subtitle:
                  'Review pending PDF uploads. Approve, flag, or delete submitted notes.',
              color: AppColors.warning,
              onTap: () => context.push('/admin/moderation'),
            ),
            const SizedBox(height: 12),
            _AdminActionCard(
              icon: Icons.manage_accounts_outlined,
              title: 'Role Management',
              subtitle:
                  'Grant or revoke administrator privileges for designated users.',
              color: AppColors.accent,
              onTap: () => context.push('/admin/roles'),
            ),
            const SizedBox(height: 32),

            // ─── Back to Student View ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/universities'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Student View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Action Card ────────────────────────────────────────────────────────
class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return IconButton(
      icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
