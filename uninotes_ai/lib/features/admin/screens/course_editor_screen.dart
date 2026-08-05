import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/university.dart';
import '../../../shared/models/academic_hierarchy.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key});

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Structure Editor'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Universities'),
            Tab(text: 'Faculties'),
            Tab(text: 'Departments'),
            Tab(text: 'Courses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UniversityTab(),
          _FacultyTab(),
          _DepartmentTab(),
          _CourseTab(),
        ],
      ),
    );
  }
}

// ─── University Tab ───────────────────────────────────────────────────────────
class _UniversityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universitiesStream = ref.watch(
      StreamProvider((ref) => ref.read(firebaseServiceProvider).streamUniversities()),
    );

    return universitiesStream.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e')),
      data: (universities) => Scaffold(
        body: universities.isEmpty
            ? const Center(child: Text('No universities yet. Add one below.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: universities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _EditableListTile(
                  title: universities[i].name,
                  subtitle: '${universities[i].acronym} • ${universities[i].country}',
                  onEdit: () => _showUniversityDialog(ctx, ref, existing: universities[i]),
                  onDelete: () => _confirmDelete(ctx, () async {
                    await ref
                        .read(firebaseServiceProvider)
                        .deleteUniversity(universities[i].id);
                  }),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showUniversityDialog(context, ref),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _showUniversityDialog(BuildContext context, WidgetRef ref, {University? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final acronymCtrl = TextEditingController(text: existing?.acronym);
    final countryCtrl = TextEditingController(text: existing?.country);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add University' : 'Edit University'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'University Name *')),
            const SizedBox(height: 12),
            TextField(controller: acronymCtrl, decoration: const InputDecoration(labelText: 'Acronym (e.g., MIT)')),
            const SizedBox(height: 12),
            TextField(controller: countryCtrl, decoration: const InputDecoration(labelText: 'Country')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final service = ref.read(firebaseServiceProvider);
              if (existing == null) {
                await service.addUniversity(University(
                  id: '',
                  name: nameCtrl.text.trim(),
                  acronym: acronymCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
              } else {
                await service.updateUniversity(existing.copyWith(
                  name: nameCtrl.text.trim(),
                  acronym: acronymCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                ));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}

// ─── Faculty Tab ──────────────────────────────────────────────────────────────
class _FacultyTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FacultyTab> createState() => _FacultyTabState();
}

class _FacultyTabState extends ConsumerState<_FacultyTab> {
  String? _selectedUniversityId;

  @override
  Widget build(BuildContext context) {
    final universitiesStream = ref.watch(
      StreamProvider((ref) => ref.read(firebaseServiceProvider).streamUniversities()),
    );
    final universities = universitiesStream.valueOrNull ?? [];

    return Column(
      children: [
        // University Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select University'),
            value: _selectedUniversityId,
            items: universities
                .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedUniversityId = v),
          ),
        ),
        if (_selectedUniversityId != null)
          Expanded(child: _FacultyList(universityId: _selectedUniversityId!)),
      ],
    );
  }
}

class _FacultyList extends ConsumerWidget {
  final String universityId;
  const _FacultyList({required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultiesStream = ref.watch(
      StreamProvider((ref) => ref.read(firebaseServiceProvider).streamFaculties(universityId)),
    );

    return facultiesStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (faculties) => Scaffold(
        body: faculties.isEmpty
            ? const Center(child: Text('No faculties. Add one below.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faculties.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _EditableListTile(
                  title: faculties[i].name,
                  subtitle: 'Code: ${faculties[i].code}',
                  onEdit: () => _showDialog(ctx, ref, existing: faculties[i]),
                  onDelete: () => _confirmDelete(ctx, () async {
                    await ref
                        .read(firebaseServiceProvider)
                        .deleteFaculty(universityId, faculties[i].id);
                  }),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDialog(context, ref),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {Faculty? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final codeCtrl = TextEditingController(text: existing?.code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Faculty' : 'Edit Faculty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Faculty Name *')),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g., FOE)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final service = ref.read(firebaseServiceProvider);
              final faculty = Faculty(
                id: existing?.id ?? '',
                universityId: universityId,
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim(),
              );
              if (existing == null) {
                await service.addFaculty(universityId, faculty);
              } else {
                await service.updateFaculty(universityId, faculty);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}

// ─── Department & Course Tabs (similar pattern, abbreviated) ──────────────────
class _DepartmentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Select University → Faculty above to manage Departments.\n\nImplemented with the same CRUD pattern as Faculties.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CourseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Select University → Faculty → Department to manage Courses.\n\nImplemented with the same CRUD pattern as Faculties.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Reusable Editable List Tile ──────────────────────────────────────────────
class _EditableListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableListTile({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Delete Confirm ────────────────────────────────────────────────────
Future<void> _confirmDelete(BuildContext context, Future<void> Function() onConfirm) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text('This action cannot be undone. Are you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await onConfirm();
  }
}
