import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/models/note.dart';
import '../../../shared/models/user_role.dart';

// ─── AI Chat State ────────────────────────────────────────────────────────────
final aiChatProvider = StateNotifierProvider.autoDispose<AiChatNotifier, List<AiMessage>>((ref) {
  return AiChatNotifier(ref.read(aiServiceProvider));
});

class AiChatNotifier extends StateNotifier<List<AiMessage>> {
  final AiService _aiService;
  AiChatNotifier(this._aiService) : super([]);

  Future<void> ask({required String question, String? pdfText}) async {
    final userMsg = AiMessage(
      id: const Uuid().v4(),
      content: question,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final loadingMsg = AiMessage(
      id: const Uuid().v4(),
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, userMsg, loadingMsg];

    try {
      final answer = await _aiService.explain(question: question, pdfText: pdfText);
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        loadingMsg.copyWith(content: answer, isLoading: false),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        loadingMsg.copyWith(
          content: '⚠️ Error: ${e.toString()}',
          isLoading: false,
        ),
      ];
    }
  }

  Future<void> summarize({required String pdfText, required String title}) async {
    final loadingMsg = AiMessage(
      id: const Uuid().v4(),
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [
      AiMessage(
        id: const Uuid().v4(),
        content: '📄 Summarize this document',
        isUser: true,
        timestamp: DateTime.now(),
      ),
      loadingMsg,
    ];

    try {
      final summary = await _aiService.summarize(text: pdfText, title: title);
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        loadingMsg.copyWith(content: summary, isLoading: false),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        loadingMsg.copyWith(content: '⚠️ Error: ${e.toString()}', isLoading: false),
      ];
    }
  }

  void clear() => state = [];
}

// ─── PDF Viewer Screen ────────────────────────────────────────────────────────
class PdfViewerScreen extends ConsumerStatefulWidget {
  final Note note;
  const PdfViewerScreen({super.key, required this.note});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isAiSheetOpen = false;
  String _extractedText = '';

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Summarize with AI',
            onPressed: _summarize,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── PDF Viewer ─────────────────────────────────────────────────────
          SfPdfViewer.network(
            widget.note.fileUrl,
            controller: _pdfController,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                _extractedText = details.selectedText!;
              }
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              // Extract text from all pages for AI context
              _extractTextFromPdf(details);
            },
          ),

          // ─── AI Bottom Sheet ────────────────────────────────────────────────
          if (_isAiSheetOpen)
            _AiBottomSheet(
              pdfText: _extractedText,
              noteTitle: widget.note.title,
              onClose: () => setState(() => _isAiSheetOpen = false),
            ),
        ],
      ),

      // ─── Ask AI FAB ─────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('ask_ai_fab'),
        onPressed: () => setState(() => _isAiSheetOpen = !_isAiSheetOpen),
        backgroundColor: _isAiSheetOpen ? AppColors.accent : AppColors.primary,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(_isAiSheetOpen ? 'Close AI' : 'Ask AI ✨'),
      ),
    );
  }

  Future<void> _extractTextFromPdf(PdfDocumentLoadedDetails details) async {
    try {
      final extractor = PdfTextExtractor(details.document);
      final extracted = extractor.extractText();
      setState(() => _extractedText = extracted);
    } catch (e) {
      // Ignore if text extraction fails on scanned/image-only PDFs
    }
  }

  Future<void> _summarize() async {
    setState(() => _isAiSheetOpen = true);
    if (_extractedText.isNotEmpty) {
      await ref.read(aiChatProvider.notifier).summarize(
            pdfText: _extractedText,
            title: widget.note.title,
          );
    }
  }
}

// ─── AI Bottom Sheet ──────────────────────────────────────────────────────────
class _AiBottomSheet extends ConsumerStatefulWidget {
  final String pdfText;
  final String noteTitle;
  final VoidCallback onClose;

  const _AiBottomSheet({
    required this.pdfText,
    required this.noteTitle,
    required this.onClose,
  });

  @override
  ConsumerState<_AiBottomSheet> createState() => _AiBottomSheetState();
}

class _AiBottomSheetState extends ConsumerState<_AiBottomSheet> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    _questionController.clear();
    setState(() => _isSending = true);

    await ref.read(aiChatProvider.notifier).ask(
          question: question,
          pdfText: widget.pdfText.isNotEmpty ? widget.pdfText : null,
        );

    setState(() => _isSending = false);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // ─── Sheet Handle ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // ─── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'UniNotes AI Assistant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryLight,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.read(aiChatProvider.notifier).clear(),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ─── Messages ─────────────────────────────────────────────────
              Expanded(
                child: messages.isEmpty
                    ? _EmptyAiState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) => _AiMessageBubble(message: messages[i]),
                      ),
              ),

              // ─── Input Bar ────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(top: BorderSide(color: AppColors.borderDark)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about this document...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton.filled(
                        onPressed: _isSending ? null : _send,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AI Message Bubble ────────────────────────────────────────────────────────
class _AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  const _AiMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Text(
            message.content,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          border: Border.all(color: AppColors.borderDark),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: message.isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  ),
                ],
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
                  code: TextStyle(
                    backgroundColor: AppColors.backgroundDark,
                    color: AppColors.primaryLight,
                    fontSize: 13,
                  ),
                  strong: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Empty AI State ───────────────────────────────────────────────────────────
class _EmptyAiState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
              'Ask me anything!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'I have context from this document.\nYou can ask me to explain concepts,\nsummarize sections, or answer questions.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
