import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/ward.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.wardsCollection)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Patients')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final wards = snap.data!.docs.map(Ward.fromFirestore).toList();
        if (wards.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(title: const Text('Patients')),
            body: Center(
              child: Text(
                'No wards yet. Create one in the Wards tab.',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        const initialIndex = 0;

        return DefaultTabController(
          length: wards.length,
          initialIndex: initialIndex,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              title: _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search patients',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
                    )
                  : const Text('Patients'),
              actions: [
                IconButton(
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    if (_searching) {
                      _searchController.clear();
                      _query = '';
                    }
                    _searching = !_searching;
                  }),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                tabs: wards.map((w) => Tab(text: w.name)).toList(),
              ),
            ),
            body: TabBarView(
              children: wards.map((w) => _wardPatients(w)).toList(),
            ),
            floatingActionButton: Builder(
              builder: (ctx) => FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Patient'),
                onPressed: () {
                  final tabIndex = DefaultTabController.of(ctx).index;
                  final activeWardId = wards[tabIndex].id;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AddPatientScreen(initialWardId: activeWardId),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wardPatients(Ward ward) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.patientsCollection)
          .where('wardId', isEqualTo: ward.id)
          .where('isActive', isEqualTo: true)
          .orderBy('admittedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load: ${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var patients = snap.data!.docs.map(Patient.fromFirestore).toList();
        if (_query.isNotEmpty) {
          patients = patients
              .where((p) =>
                  p.name.toLowerCase().contains(_query) ||
                  p.bedNumber.toLowerCase().contains(_query))
              .toList();
        }
        if (patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No patients in ${ward.name}',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _patientCard(patients[i]),
        );
      },
    );
  }

  Widget _patientCard(Patient p) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(patientId: p.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.doctorColor.withOpacity(0.1),
              child: Text(
                p.initials,
                style: const TextStyle(
                  color: AppColors.doctorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.bedNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            'Bed ${p.bedNumber}',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (p.diagnosis.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.diagnosis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat.yMMMd().format(p.admittedAt),
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(p.isActive),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              onSelected: (v) => _handleMenu(p, v),
              itemBuilder: (_) => [
                if (p.isActive)
                  const PopupMenuItem(
                    value: 'discharge',
                    child: Text('Discharge'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete permanently',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(Patient p, String action) async {
    final provider = context.read<PatientProvider>();
    if (action == 'discharge') {
      final ok = await provider.dischargePatient(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '${p.name} discharged' : 'Failed to discharge'),
        ),
      );
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Delete ${p.name}?'),
          content: const Text(
            'This permanently removes the patient. Notes linked will remain but be orphaned.',
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
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final ok = await provider.deletePatient(p.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '${p.name} deleted' : 'Failed to delete'),
          ),
        );
      }
    }
  }

  Widget _statusChip(bool active) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Active' : 'Discharged',
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
