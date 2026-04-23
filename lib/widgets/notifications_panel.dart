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

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NoteProvider>();
    final unack = np.notes.where((n) => !n.isAcknowledged).toList();
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
                          padding: const EdgeInsets.all(0),
                          children: [
                            if (urgent.isNotEmpty) ...[
                              _sectionHeader('Urgent', AppColors.danger),
                              for (final n in urgent) _tile(context, n),
                            ],
                            if (other.isNotEmpty) ...[
                              _sectionHeader('Other', AppColors.primary),
                              for (final n in other) _tile(context, n),
                            ],
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
