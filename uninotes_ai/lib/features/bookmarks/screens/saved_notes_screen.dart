import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/note.dart';

class SavedNotesScreen extends ConsumerStatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  ConsumerState<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends ConsumerState<SavedNotesScreen> {
  late Future<List<Note>> _savedNotesFuture;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  void _loadSaved() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      _savedNotesFuture = ref.read(firebaseServiceProvider).getSavedNotes(user.uid);
    } else {
      _savedNotesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _loadSaved()),
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: _savedNotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error)));
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_outline_rounded,
                      size: 64, color: AppColors.textSecondaryDark),
                  const SizedBox(height: 16),
                  Text('No saved notes yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark notes while browsing\nto save them here.',
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final note = notes[i];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.error, size: 22),
                  ),
                  title: Text(note.title, overflow: TextOverflow.ellipsis),
                  subtitle: Text(note.fileSizeFormatted,
                      style: const TextStyle(color: AppColors.textSecondaryDark)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
                        onPressed: () async {
                          await ref
                              .read(firebaseServiceProvider)
                              .unsaveNote(user.uid, note.id);
                          setState(() => _loadSaved());
                        },
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondaryDark),
                    ],
                  ),
                  onTap: () => context.push('/pdf-viewer', extra: note),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
