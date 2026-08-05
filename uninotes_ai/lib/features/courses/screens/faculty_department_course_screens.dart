import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/academic_hierarchy.dart';

class FacultyScreen extends ConsumerWidget {
  final String universityId;
  final String universityName;

  const FacultyScreen({
    super.key,
    required this.universityId,
    required this.universityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultiesStream = ref.watch(
      StreamProvider((ref) =>
          ref.read(firebaseServiceProvider).streamFaculties(universityId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(universityName, overflow: TextOverflow.ellipsis),
            Text(
              'Select a Faculty',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
      body: facultiesStream.when(
        loading: () => _HierarchyShimmer(),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (faculties) {
          if (faculties.isEmpty) {
            return const _EmptyState(
              icon: Icons.account_balance_outlined,
              message: 'No faculties added yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: faculties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _HierarchyCard(
              icon: Icons.account_balance_outlined,
              title: faculties[i].name,
              subtitle: 'Code: ${faculties[i].code}',
              onTap: () => context.push(
                '/universities/$universityId/faculties/${faculties[i].id}/departments?facName=${Uri.encodeComponent(faculties[i].name)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class DepartmentScreen extends ConsumerWidget {
  final String universityId;
  final String facultyId;
  final String facultyName;

  const DepartmentScreen({
    super.key,
    required this.universityId,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsStream = ref.watch(
      StreamProvider((ref) => ref
          .read(firebaseServiceProvider)
          .streamDepartments(universityId, facultyId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facultyName, overflow: TextOverflow.ellipsis),
            Text(
              'Select a Department',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
      body: departmentsStream.when(
        loading: () => _HierarchyShimmer(),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (departments) {
          if (departments.isEmpty) {
            return const _EmptyState(
              icon: Icons.folder_outlined,
              message: 'No departments added yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _HierarchyCard(
              icon: Icons.folder_outlined,
              title: departments[i].name,
              subtitle: 'Code: ${departments[i].code}',
              onTap: () => context.push(
                '/universities/$universityId/faculties/$facultyId/departments/${departments[i].id}/courses?deptName=${Uri.encodeComponent(departments[i].name)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class CourseScreen extends ConsumerWidget {
  final String universityId;
  final String facultyId;
  final String departmentId;
  final String departmentName;

  const CourseScreen({
    super.key,
    required this.universityId,
    required this.facultyId,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesStream = ref.watch(
      StreamProvider((ref) => ref
          .read(firebaseServiceProvider)
          .streamCourses(universityId, facultyId, departmentId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(departmentName, overflow: TextOverflow.ellipsis),
            Text(
              'Select a Course',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
      body: coursesStream.when(
        loading: () => _HierarchyShimmer(),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (courses) {
          if (courses.isEmpty) {
            return const _EmptyState(
              icon: Icons.menu_book_outlined,
              message: 'No courses added yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final course = courses[i];
              return _HierarchyCard(
                icon: Icons.menu_book_outlined,
                title: '${course.code} – ${course.name}',
                subtitle: 'Semester ${course.semester} • ${course.year}',
                onTap: () => context.push(
                  '/courses/${course.id}/notes?courseName=${Uri.encodeComponent(course.code + ' – ' + course.name)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Shared Hierarchy Card ────────────────────────────────────────────────────
class _HierarchyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HierarchyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondaryDark)),
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

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _HierarchyShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 80,
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
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}
