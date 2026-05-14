import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../utils/app_theme.dart';

Future<void> showNotificationsPanel(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NotificationsPanel(),
  );
}

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  static const int _maxNotifications = 30;

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NoteProvider>();

    // Cap at last 30, sorted newest first.
    final allUnack = np.notes
        .where((n) => !n.isAcknowledged)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unack = allUnack.take(_maxNotifications).toList();

    final urgent = unack.where((n) => n.priority == 'Urgent').toList();
    final other = unack.where((n) => n.priority != 'Urgent').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
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
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (unack.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${unack.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Clear all button — only shown when there are notifications.
                      if (unack.isNotEmpty)
                        _ClearAllButton(notes: unack),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: unack.isEmpty
                      ? _emptyState()
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            if (urgent.isNotEmpty) ...[
                              _sectionHeader('Urgent', AppColors.danger),
                              for (final n in urgent) _tile(context, n),
                            ],
                            if (other.isNotEmpty) ...[
                              _sectionHeader('Other', AppColors.primary),
                              for (final n in other) _tile(context, n),
                            ],
                            // Hint when there are more than 30 total.
                            if (allUnack.length > _maxNotifications)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Showing latest 30 of ${allUnack.length}',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.accent.withOpacity(0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'All caught up',
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No unacknowledged notes right now.',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Note n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: n.priorityColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(n.categoryIcon, size: 18, color: n.priorityColor),
        ),
        title: Text(
          n.patientName,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          n.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timeago.format(n.createdAt, locale: 'en_short'),
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final by = context.read<AuthProvider>().currentUser?.name ??
                    'staff';
                await context
                    .read<NoteProvider>()
                    .acknowledgeNote(n.id, by);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ack ✓',
                  style: GoogleFonts.dmSans(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful clear-all button with a confirmation dialog.
class _ClearAllButton extends StatefulWidget {
  final List<Note> notes;
  const _ClearAllButton({required this.notes});

  @override
  State<_ClearAllButton> createState() => _ClearAllButtonState();
}

class _ClearAllButtonState extends State<_ClearAllButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Clear all notifications?',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will acknowledge all ${widget.notes.length} notifications.',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear all',
                style: GoogleFonts.dmSans(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final by =
        context.read<AuthProvider>().currentUser?.name ?? 'staff';
    await context
        .read<NoteProvider>()
        .acknowledgeAllNotes(widget.notes.map((n) => n.id).toList(), by);
    if (mounted) {
      setState(() => _loading = false);
      Navigator.of(context).pop(); // close panel — it's now empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : TextButton.icon(
            onPressed: _confirm,
            icon: Icon(Icons.done_all, size: 16, color: AppColors.danger),
            label: Text(
              'Clear all',
              style: GoogleFonts.dmSans(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
  }
}
