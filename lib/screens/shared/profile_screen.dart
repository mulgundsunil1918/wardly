import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider, EmailAuthProvider;
import 'package:firebase_auth/firebase_auth.dart' as fba show EmailAuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/role_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(user),
                  const SizedBox(height: 20),
                  _sectionLabel('Account'),
                  const SizedBox(height: 8),
                  _accountCard(context, auth),
                  const SizedBox(height: 20),
                  _sectionLabel('Preferences'),
                  const SizedBox(height: 8),
                  _preferencesCard(context),
                  const SizedBox(height: 20),
                  _sectionLabel('Danger zone'),
                  const SizedBox(height: 8),
                  _dangerCard(context, auth),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _headerCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: user.roleColor.withOpacity(0.15),
            child: Text(
              getInitials(user.name),
              style: TextStyle(
                color: user.roleColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          RoleBadge(role: user.role),
        ],
      ),
    );
  }

  Widget _cardWrapper({required List<Widget> children}) {
    final tiles = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      tiles.add(children[i]);
      if (i < children.length - 1) tiles.add(const Divider(height: 1));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: tiles),
    );
  }

  Widget _accountCard(BuildContext context, AuthProvider auth) {
    return _cardWrapper(
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit profile'),
          subtitle: const Text('Update your name'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showEditProfile(context, auth),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangePassword(context),
        ),
      ],
    );
  }

  Widget _preferencesCard(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return _cardWrapper(
      children: [
        SwitchListTile(
          secondary: Icon(
            tp.isDark ? Icons.dark_mode : Icons.light_mode,
          ),
          title: const Text('Dark mode'),
          subtitle: Text(tp.isDark ? 'On' : 'Off'),
          value: tp.isDark,
          onChanged: (_) => tp.toggle(),
        ),
      ],
    );
  }

  Widget _dangerCard(BuildContext context, AuthProvider auth) {
    return _cardWrapper(
      children: [
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: const Text(
            'Sign out',
            style: TextStyle(color: AppColors.danger),
          ),
          onTap: () => _confirmSignOut(context, auth),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
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
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
        );
      }
    }
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameController = TextEditingController(text: auth.currentUser?.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit profile',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await auth.updateProfile(name: nameController.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new'),
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
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || user.email == null) return;
              try {
                final cred = fba.EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentController.text,
                );
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text(e.toString()),
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
