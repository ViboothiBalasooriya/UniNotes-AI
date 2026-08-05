import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/note.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ─── Saved Note IDs provider ───────────────────────────────────────────────────
final savedNoteIdsProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.read(firebaseServiceProvider).streamSavedNoteIds(userId);
});

class NotesListScreen extends ConsumerWidget {
  final String courseId;
  final String courseName;

  const NotesListScreen({super.key, required this.courseId, required this.courseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesStream = ref.watch(
      StreamProvider.family((ref, String id) =>
          ref.read(firebaseServiceProvider).streamApprovedNotes(id))(courseId),
    );
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(courseName, overflow: TextOverflow.ellipsis),
            Text(
              'Study Materials',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('upload_fab'),
        onPressed: () => context.push(
          '/notes/upload?courseId=$courseId&courseName=${Uri.encodeComponent(courseName)}',
        ),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: notesStream.when(
        loading: () => _NotesShimmer(),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (notes) {
          if (notes.isEmpty) {
            return const _EmptyNotes();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final note = notes[i];
              return _NoteCard(note: note, userId: user?.uid ?? '');
            },
          );
        },
      ),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────────────────────
class _NoteCard extends ConsumerWidget {
  final Note note;
  final String userId;

  const _NoteCard({required this.note, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedNoteIdsProvider(userId)).valueOrNull ?? [];
    final isSaved = savedIds.contains(note.id);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Increment view count
          ref.read(firebaseServiceProvider).incrementViewCount(note.id);
          // Navigate to PDF viewer
          context.push('/pdf-viewer', extra: note);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── PDF Icon ─────────────────────────────────────────────────
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 26),
              ),
              const SizedBox(width: 14),

              // ─── Note Info ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondaryDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.person_outline,
                          label: note.uploaderName,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.data_usage_rounded,
                          label: note.fileSizeFormatted,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.remove_red_eye_outlined,
                          label: '${note.viewCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Bookmark Button ──────────────────────────────────────────
              if (userId.isNotEmpty)
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isSaved ? AppColors.primary : AppColors.textSecondaryDark,
                  ),
                  onPressed: () async {
                    final service = ref.read(firebaseServiceProvider);
                    if (isSaved) {
                      await service.unsaveNote(userId, note.id);
                    } else {
                      await service.saveNote(userId, note.id);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondaryDark),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondaryDark),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _NotesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 110,
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
class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text('No notes yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to upload study materials\nfor this course!',
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
