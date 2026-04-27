import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../models/ward.dart';
import '../../providers/auth_provider.dart';
import '../../services/metrics_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class WardsScreen extends StatelessWidget {
  const WardsScreen({super.key});


  Future<void> _shareWard(BuildContext context, Ward w) async {
    final me = context.read<AuthProvider>().currentUser;
    final byLine = me == null
        ? ''
        : (me.specialty != null && me.specialty!.isNotEmpty
            ? '\nShared by Dr. ${me.name} · ${me.specialty}'
            : '\nShared by ${me.name}');
    final text =
        'Join my ward on Wardly!$byLine\n\n${w.name}\nWard ID: ${w.id}\n\n'
        'Open the Wardly app → Wards → tap "Join Ward" → paste this ID.';
    await Share.share(text, subject: 'Join ward ${w.name}');
  }

  Widget _wardActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: disabled ? AppColors.textSecondary.withOpacity(0.5) : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: disabled ? AppColors.textSecondary.withOpacity(0.5) : color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(
          color: disabled
              ? AppColors.divider
              : color,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMembers(BuildContext context, Ward w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, controller) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
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
                      Text(
                        '${w.name} · Members',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .where('wardIds', arrayContains: w.id)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final users = snap.data!.docs;
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No other members yet.\nShare this ward ID to invite others.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final doc = users[i];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final name = data['name'] as String? ?? 'User';
                          final email = data['email'] as String? ?? '';
                          final role =
                              data['role'] as String? ?? 'doctor';
                          final isOwner = doc.id == w.creatorId;
                          final roleColor = role == 'nurse'
                              ? AppColors.nurseColor
                              : role == 'admin'
                                  ? AppColors.adminColor
                                  : AppColors.doctorColor;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.15),
                              child: Text(
                                name.isEmpty
                                    ? '?'
                                    : name[0].toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(child: Text(name)),
                                if (isOwner) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'OWNER',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(email),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role[0].toUpperCase() + role.substring(1),
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOnlyCreatorCanDelete(BuildContext context, Ward w) {
    final owner = w.headDoctorName.isNotEmpty
        ? w.headDoctorName
        : 'the ward creator';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Only the owner can delete this ward'),
        content: Text(
          'This ward was created by $owner. Only $owner can delete it. Ask them to do it from their account if it really needs to go.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWard(BuildContext context, Ward w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ward "${w.name}"?'),
        content: const Text(
          'This will permanently delete the ward and every patient, note and reply inside it — fully erased from our database. Members will lose access immediately. There is no backup and no way to recover this data once you tap Delete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final fs = FirebaseFirestore.instance;

      // 1. Delete every note in this ward (and its comment subcollection).
      final notes = await fs
          .collection(AppConstants.notesCollection)
          .where('wardId', isEqualTo: w.id)
          .get();
      for (final n in notes.docs) {
        final comments = await n.reference.collection('comments').get();
        for (final c in comments.docs) {
          await c.reference.delete();
        }
        await n.reference.delete();
      }

      // 2. Delete every patient in this ward.
      final patients = await fs
          .collection(AppConstants.patientsCollection)
          .where('wardId', isEqualTo: w.id)
          .get();
      final batch = fs.batch();
      for (final p in patients.docs) {
        batch.delete(p.reference);
      }
      if (patients.docs.isNotEmpty) await batch.commit();

      // 3. Remove this ward from every member's wardIds array.
      final members = await fs
          .collection(AppConstants.usersCollection)
          .where('wardIds', arrayContains: w.id)
          .get();
      for (final u in members.docs) {
        await u.reference.update({
          'wardIds': FieldValue.arrayRemove([w.id]),
        });
      }

      // 4. Finally delete the ward doc.
      await fs.collection(AppConstants.wardsCollection).doc(w.id).delete();

      // Refresh local user so the ward vanishes from the UI immediately.
      if (context.mounted) {
        await context.read<AuthProvider>().loadCurrentUser();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ward "${w.name}" deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to delete: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Wards'),
        actions: [
          TextButton.icon(
            onPressed: () => _showJoinDialog(context),
            icon: const Icon(Icons.login),
            label: const Text('Join Ward'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(builder: (context) {
        final myWardIds =
            context.watch<AuthProvider>().currentUser?.wardIds ?? const [];
        if (myWardIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.corporate_fare,
                  size: 56,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'You are not in any ward yet',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the + button to create one,\nor use Join Ward if you have an ID.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.wardsCollection)
            .where(FieldPath.documentId, whereIn: myWardIds)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load wards:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wards = snap.data!.docs.map(Ward.fromFirestore).toList();
          if (wards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.corporate_fare,
                    size: 56,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No wards yet',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the + button to create one',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _wardCard(
              context,
              wards[i],
              FirebaseAuth.instance.currentUser?.uid ??
                  context.read<AuthProvider>().currentUser?.uid ??
                  '',
            ),
          );
        },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Ward'),
        onPressed: () => _showCreateDialog(context),
      ),
    );
  }

  Widget _wardCard(BuildContext context, Ward w, String currentUid) {
    final isCreator =
        w.creatorId.isNotEmpty && w.creatorId == currentUid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ward name row ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_box_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            w.name,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OWNED BY YOU',
                              style: GoogleFonts.dmSans(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (w.floor.isNotEmpty)
                      Text(
                        w.floor,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    if (!isCreator && w.headDoctorName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Owner · ${w.headDoctorName}',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ward code row ──
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: w.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ward ID "${w.id}" copied')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      w.id,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Action buttons ──
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: _wardActionButton(
                    label: 'Members',
                    icon: Icons.group_outlined,
                    color: AppColors.primary,
                    onTap: () => _showMembers(context, w),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _wardActionButton(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    color: AppColors.primary,
                    onTap: () => _shareWard(context, w),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _wardActionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    onTap: isCreator
                        ? () => _deleteWard(context, w)
                        : () => _showOnlyCreatorCanDelete(context, w),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Ward'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Ward ID',
            hintText: 'Paste the ward ID here',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim().toUpperCase();
              if (id.isEmpty) return;
              Navigator.pop(context);
              try {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                // Check ward exists.
                final wardDoc = await FirebaseFirestore.instance
                    .collection(AppConstants.wardsCollection)
                    .doc(id)
                    .get();
                if (!wardDoc.exists) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.danger,
                        content: Text('No ward with ID $id'),
                      ),
                    );
                  }
                  return;
                }
                await FirebaseFirestore.instance
                    .collection(AppConstants.usersCollection)
                    .doc(uid)
                    .set({
                  'wardIds': FieldValue.arrayUnion([id]),
                }, SetOptions(merge: true));
                await context.read<AuthProvider>().loadCurrentUser();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joined $id')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Failed: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final floorController = TextEditingController();
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Ward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ward name',
                hintText: 'e.g. ICU Ward A',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: floorController,
              decoration: const InputDecoration(
                labelText: 'Floor (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              try {
                final id =
                    const Uuid().v4().substring(0, 8).toUpperCase();
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                await FirebaseFirestore.instance
                    .collection(AppConstants.wardsCollection)
                    .doc(id)
                    .set({
                  'name': name,
                  'floor': floorController.text.trim(),
                  'capacity': 0,
                  'headDoctorName': auth.currentUser?.name ?? '',
                  'creatorId': uid,
                  'createdAt': Timestamp.fromDate(DateTime.now()),
                });
                MetricsService.bump('ward',
                    summary: 'New ward "$name"');
                if (uid.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection(AppConstants.usersCollection)
                      .doc(uid)
                      .set({
                    'wardIds': FieldValue.arrayUnion([id]),
                  }, SetOptions(merge: true));
                  await auth.loadCurrentUser();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ward "$name" created · ID: $id'),
                      duration: const Duration(seconds: 6),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Failed: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Create & Join'),
          ),
        ],
      ),
    );
  }
}
