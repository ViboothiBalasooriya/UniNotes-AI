import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/university.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class UniversityListScreen extends ConsumerWidget {
  const UniversityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universitiesStream = ref.watch(
      StreamProvider((ref) => ref.read(firebaseServiceProvider).streamUniversities()),
    );
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UniNotes AI'),
            if (user?.displayName != null)
              Text(
                'Hello, ${user!.displayName!.split(' ').first} 👋',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ),
          ],
        ),
        actions: [
          // Bookmarks
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Saved Notes',
            onPressed: () => context.push('/bookmarks'),
          ),
          // Admin dashboard (shown for admin users)
          _AdminIconButton(),
          // Theme toggle
          _ThemeToggleButton(),
          // Profile / Sign out
          _ProfileMenu(),
        ],
      ),
      body: universitiesStream.when(
        loading: () => _UniversityShimmer(),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (universities) {
          if (universities.isEmpty) {
            return const _EmptyUniversities();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(StreamProvider(
                  (ref) => ref.read(firebaseServiceProvider).streamUniversities()));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: universities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _UniversityCard(university: universities[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── University Card ──────────────────────────────────────────────────────────
class _UniversityCard extends StatelessWidget {
  final University university;
  const _UniversityCard({required this.university});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/universities/${university.id}/faculties?uniName=${Uri.encodeComponent(university.name)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    university.acronym.isNotEmpty
                        ? university.acronym.substring(0, university.acronym.length.clamp(0, 3))
                        : '🎓',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(university.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      university.country,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Loading ──────────────────────────────────────────────────────────
class _UniversityShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyUniversities extends StatelessWidget {
  const _EmptyUniversities();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text('No universities yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Ask an administrator to add your university.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Header Action Widgets ────────────────────────────────────────────────────
class _AdminIconButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final roleAsync = ref.watch(userRoleProvider(user.uid));
    return roleAsync.when(
      data: (role) {
        if (role?.isAdmin != true) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          tooltip: 'Admin Panel',
          onPressed: () => context.push('/admin'),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
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

class _ProfileMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary,
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null
            ? Text(
                (user?.displayName?.isNotEmpty == true)
                    ? user!.displayName![0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'signout',
          child: const Row(
            children: [
              Icon(Icons.logout_rounded),
              SizedBox(width: 12),
              Text('Sign Out'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'signout') {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      },
    );
  }
}
