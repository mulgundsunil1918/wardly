import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/note.dart';
import '../models/note_comment.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../services/note_service.dart';
import '../utils/app_theme.dart';

Future<void> showNoteCommentsSheet(BuildContext context, Note note) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NoteCommentsSheet(note: note),
  );
}

class NoteCommentsSheet extends StatefulWidget {
  final Note note;

  const NoteCommentsSheet({super.key, required this.note});

  @override
  State<NoteCommentsSheet> createState() => _NoteCommentsSheetState();
}

class _NoteCommentsSheetState extends State<NoteCommentsSheet> {
  final _textController = TextEditingController();
  final _noteService = NoteService();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send({bool acknowledge = false}) async {
    final text = _textController.text.trim();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    if (text.isEmpty && !acknowledge) return;

    setState(() => _sending = true);
    try {
      if (text.isNotEmpty) {
        await _noteService.addComment(
          widget.note.id,
          NoteComment(
            id: '',
            text: text,
            authorId: user.uid,
            authorName: user.name,
            authorRole: user.roleLabel,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (acknowledge && !widget.note.isAcknowledged) {
        await context
            .read<NoteProvider>()
            .acknowledgeNote(widget.note.id, user.name);
      }
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return AppColors.doctorColor;
      case 'nurse':
        return AppColors.nurseColor;
      case 'admin':
        return AppColors.adminColor;
      default:
        return AppColors.primary;
    }
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final p = t.split(RegExp(r'\s+'));
    final a = p.first[0];
    final b = p.length > 1 && p[1].isNotEmpty ? p[1][0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Scaffold(
            backgroundColor: AppColors.card,
            body: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Thread',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (n.isAcknowledged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ack',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      _originalNoteBubble(n),
                      const SizedBox(height: 16),
                      _commentsList(),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Write a reply…',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!n.isAcknowledged)
                          IconButton(
                            tooltip: 'Ack with reply',
                            icon: const Icon(Icons.check_circle_outline,
                                color: AppColors.accent),
                            onPressed: _sending
                                ? null
                                : () => _send(acknowledge: true),
                          ),
                        IconButton(
                          tooltip: 'Send',
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send,
                                  color: AppColors.primary),
                          onPressed: _sending ? null : () => _send(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _originalNoteBubble(Note n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _roleColor(n.authorRole).withOpacity(0.15),
                child: Text(
                  _initials(n.authorName),
                  style: TextStyle(
                    color: _roleColor(n.authorRole),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                n.authorName,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: n.priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  n.priority,
                  style: GoogleFonts.dmSans(
                    color: n.priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            n.content,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeago.format(n.createdAt),
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsList() {
    return StreamBuilder<List<NoteComment>>(
      stream: _noteService.commentsStream(widget.note.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final comments = snap.data!;
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No replies yet. Be the first.',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final c in comments) _commentBubble(c),
          ],
        );
      },
    );
  }

  Widget _commentBubble(NoteComment c) {
    final rc = _roleColor(c.authorRole);
    final mine = c.authorId ==
        (context.read<AuthProvider>().currentUser?.uid ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: rc.withOpacity(0.15),
            child: Text(
              _initials(c.authorName),
              style: TextStyle(
                color: rc,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mine
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.authorName,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.authorRole,
                          style: GoogleFonts.dmSans(
                            color: rc,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(c.createdAt, locale: 'en_short'),
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.text,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
