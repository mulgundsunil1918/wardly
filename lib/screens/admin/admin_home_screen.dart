import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/ward.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ward_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/theme_toggle_button.dart';
import '../../widgets/wardly_brand.dart';
import '../shared/profile_screen.dart';
import 'add_ward_screen.dart';
import 'ward_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _staffCount = 0;
  int _activePatientCount = 0;
  int _notesToday = 0;
  List<_RecentActivityItem> _recent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardProvider>().subscribeToWards();
      _loadCounts();
    });
  }

  Future<void> _loadCounts() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection(AppConstants.usersCollection).get(),
      db
          .collection(AppConstants.patientsCollection)
          .where('isActive', isEqualTo: true)
          .get(),
      db
          .collection(AppConstants.notesCollection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get(),
    ]);
    final today = DateTime.now();
    final notesDocs = results[2].docs;
    final todays = notesDocs.where((d) {
      final t = (d.data()['createdAt'] as Timestamp?)?.toDate();
      return t != null &&
          t.year == today.year &&
          t.month == today.month &&
          t.day == today.day;
    }).length;

    final recent = notesDocs.take(5).map((d) {
      final data = d.data();
      return _RecentActivityItem(
        authorName: data['authorName'] as String? ?? '',
        patientName: data['patientName'] as String? ?? '',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _staffCount = results[0].size;
      _activePatientCount = results[1].size;
      _notesToday = todays;
      _recent = recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(user?.name ?? 'Admin'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCounts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statsGrid(),
                      const SizedBox(height: 24),
                      _wardsOverview(),
                      const SizedBox(height: 24),
                      _staffActivity(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddWardScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _header(String name) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.appBarBg,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const WardlyBrand(size: 36),
          const Spacer(),
          IconButton(
            tooltip: 'Share Wardly',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
              'Try Wardly — real-time clinical notes for ward teams.\n\n'
              'Web: https://mulgundsunil1918.github.io/wardly/\n'
              'GitHub: https://github.com/mulgundsunil1918/wardly',
              subject: 'Check out Wardly',
            ),
          ),
          const ThemeToggleButton(),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return Consumer<WardProvider>(
      builder: (context, wp, _) {
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard(
              'Total Wards',
              '${wp.wards.length}',
              Icons.business_outlined,
              AppColors.adminColor,
            ),
            _statCard(
              'Total Staff',
              '$_staffCount',
              Icons.people_outline,
              AppColors.doctorColor,
            ),
            _statCard(
              'Active Patients',
              '$_activePatientCount',
              Icons.favorite_outline,
              AppColors.accent,
            ),
            _statCard(
              'Notes Today',
              '$_notesToday',
              Icons.notes_outlined,
              AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wardsOverview() {
    return Consumer<WardProvider>(
      builder: (context, wp, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Wards Overview',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddWardScreen(),
                      ),
                    );
                  },
                  child: const Text('Add Ward'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (wp.wards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'No wards yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                ),
              )
            else
              for (final w in wp.wards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _wardCard(w),
                ),
          ],
        );
      },
    );
  }

  Widget _wardCard(Ward w) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  w.name,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  w.floor,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                w.headDoctorName,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Capacity: ${w.capacity}',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WardDetailScreen(wardId: w.id),
                    ),
                  );
                },
                child: const Text('Manage'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staffActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Staff Activity',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              if (_recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No recent activity',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                for (int i = 0; i < _recent.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getAvatarColor(_recent[i].authorName)
                          .withOpacity(0.15),
                      child: Text(
                        getInitials(_recent[i].authorName),
                        style: TextStyle(
                          color: getAvatarColor(_recent[i].authorName),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      _recent[i].authorName,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'added a note to ${_recent[i].patientName}',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      timeago.format(_recent[i].createdAt, locale: 'en_short'),
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (i < _recent.length - 1) const Divider(height: 1),
                ],
              TextButton(
                onPressed: () {},
                child: const Text('View All Activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivityItem {
  final String authorName;
  final String patientName;
  final DateTime createdAt;

  _RecentActivityItem({
    required this.authorName,
    required this.patientName,
    required this.createdAt,
  });
}
