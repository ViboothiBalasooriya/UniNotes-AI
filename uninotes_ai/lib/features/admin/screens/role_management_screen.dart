import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = ref.read(aiServiceProvider).getAllUserRoles();
  }

  Future<void> _setRole(String uid, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'student' : 'admin';
    final action = newRole == 'admin' ? 'Grant admin privileges' : 'Revoke admin privileges';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text(
            '$action to this user?\n\n${newRole == "admin" ? "They will have full access to manage course structures and moderate content." : "They will lose all admin access."}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'admin' ? AppColors.primary : AppColors.error,
            ),
            child: Text(newRole == 'admin' ? 'Grant Admin' : 'Revoke Admin'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(aiServiceProvider).setUserRole(uid, newRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newRole == 'admin'
                  ? '✅ Admin privileges granted.'
                  : '✅ Admin privileges revoked.'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() => _loadUsers());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _loadUsers()),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error)),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final user = users[i];
              final uid = user['uid'] as String? ?? '';
              final role = user['role'] as String? ?? 'student';
              final isAdmin = role == 'admin';
              final isSelf = uid == currentUser?.uid;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isAdmin ? AppColors.primary : AppColors.borderDark,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    uid.length > 16 ? '${uid.substring(0, 16)}...' : uid,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.borderDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAdmin ? 'ADMIN' : 'STUDENT',
                          style: TextStyle(
                            color: isAdmin ? AppColors.primary : AppColors.textSecondaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        const Text('(You)',
                            style: TextStyle(
                                color: AppColors.textSecondaryDark, fontSize: 11)),
                      ],
                    ],
                  ),
                  trailing: isSelf
                      ? null
                      : TextButton(
                          onPressed: () => _setRole(uid, role),
                          style: TextButton.styleFrom(
                            foregroundColor: isAdmin ? AppColors.error : AppColors.primary,
                          ),
                          child: Text(isAdmin ? 'Revoke' : 'Make Admin'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
