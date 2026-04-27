import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/note_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/note_card.dart';
import '../admin/admin_home_screen.dart';
import '../admin/admin_staff_screen.dart';
import '../doctor/add_note_screen.dart';
import '../doctor/doctor_home_screen.dart';
import '../doctor/patients_list_screen.dart';
import '../nurse/nurse_home_screen.dart';
import '../nurse/nurse_patients_screen.dart';
import '../../widgets/support_sheet.dart';
import 'profile_screen.dart';
import 'tutorial_screen.dart';
import 'wards_screen.dart';

class MainScaffold extends StatefulWidget {
  final UserRole role;

  const MainScaffold({super.key, required this.role});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!await TutorialScreen.isDone()) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TutorialScreen(),
            fullscreenDialog: true,
          ),
        );
      }
      if (mounted) SupportPrompt.maybeShowDaily(context);
    });
  }

  List<Widget> get _screensForRole {
    switch (widget.role) {
      case UserRole.doctor:
        return const [
          DoctorHomeScreen(),
          PatientsListScreen(),
          _DoctorNotesList(),
          WardsScreen(),
          ProfileScreen(),
        ];
      case UserRole.nurse:
        return const [
          NurseHomeScreen(),
          NursePatientsScreen(),
          WardsScreen(),
          ProfileScreen(),
        ];
      case UserRole.admin:
        return const [
          AdminHomeScreen(),
          WardsScreen(),
          AdminStaffScreen(),
          ProfileScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> get _itemsForRole {
    switch (widget.role) {
      case UserRole.doctor:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NoteProvider>(
              builder: (context, np, _) => _notesIcon(np.unacknowledgedCount),
            ),
            activeIcon: Consumer<NoteProvider>(
              builder: (context, np, _) =>
                  _notesIcon(np.unacknowledgedCount, active: true),
            ),
            label: 'Notes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.corporate_fare_outlined),
            activeIcon: Icon(Icons.corporate_fare),
            label: 'Wards',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.nurse:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.corporate_fare_outlined),
            activeIcon: Icon(Icons.corporate_fare),
            label: 'Wards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.admin:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.corporate_fare),
            label: 'Wards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
    }
  }

  Widget _notesIcon(int count, {bool active = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? Icons.notes : Icons.notes_outlined),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screensForRole,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.appBarBg,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.appBarBg,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
          currentIndex: _index,
          items: _itemsForRole,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _DoctorNotesList extends StatelessWidget {
  const _DoctorNotesList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Ward Notes')),
      body: Consumer<NoteProvider>(
        builder: (context, np, _) {
          if (np.notes.isEmpty) {
            return Center(
              child: Text(
                'No notes yet',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: np.notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final note = np.notes[i];
              return NoteCard(
                note: note,
                onAcknowledge: note.isAcknowledged
                    ? null
                    : () {
                        final name = context
                                .read<AuthProvider>()
                                .currentUser
                                ?.name ??
                            'Staff';
                        context
                            .read<NoteProvider>()
                            .acknowledgeNote(note.id, name);
                      },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete note?'),
                      content: const Text(
                        'This will permanently delete the note and every reply on it — fully erased from our database. There is no backup and no way to recover it once you tap Delete.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context
                        .read<NoteProvider>()
                        .deleteNote(note.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        onPressed: () => showAddNoteBottomSheet(context),
      ),
    );
  }
}

