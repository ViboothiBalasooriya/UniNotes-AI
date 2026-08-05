import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/note.dart';

class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  late Future<List<Note>> _pendingNotesFuture;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  void _loadPending() {
    _pendingNotesFuture = ref.read(aiServiceProvider).getPendingNotes();
  }

  Future<void> _updateStatus(String noteId, String status) async {
    try {
      await ref.read(aiServiceProvider).updateNoteStatus(noteId, status);
      if (mounted) {
        final statusLabel = status == 'approved' ? '✅ Approved' : status == 'flagged' ? '🚩 Flagged' : '🗑 Deleted';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note $statusLabel'),
            backgroundColor: status == 'approved'
                ? AppColors.success
                : status == 'flagged'
                    ? AppColors.warning
                    : AppColors.error,
          ),
        );
        setState(() => _loadPending());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _loadPending()),
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: _pendingNotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _loadPending()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text('All clear!', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'No pending notes to review.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondaryDark),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note.title,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (note.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 4),
                          Text(note.uploaderName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondaryDark)),
                          const SizedBox(width: 12),
                          const Icon(Icons.data_usage_rounded,
                              size: 14, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 4),
                          Text(note.fileSizeFormatted,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textSecondaryDark)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // ─── Action Buttons ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _updateStatus(note.id, 'approved'),
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Approve'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.success,
                                side: const BorderSide(color: AppColors.success),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _updateStatus(note.id, 'flagged'),
                              icon: const Icon(Icons.flag_outlined, size: 16),
                              label: const Text('Flag'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Note'),
                                  content: const Text('This will permanently delete the note. Are you sure?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) _updateStatus(note.id, 'deleted');
                            },
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
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
