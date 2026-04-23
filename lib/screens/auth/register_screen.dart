import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _wardIdController = TextEditingController();

  UserRole _selectedRole = UserRole.nurse;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _wardIdController.dispose();
    super.dispose();
  }

  String _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return '/doctor/home';
      case UserRole.nurse:
        return '/nurse/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole.name,
      wardId: _wardIdController.text.trim().isEmpty
          ? null
          : _wardIdController.text.trim(),
    );
    if (!mounted) return;
    if (ok && authProvider.currentUser != null) {
      Navigator.of(context).pushReplacementNamed(
        _routeForRole(authProvider.currentUser!.role),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authProvider.error ?? 'Registration failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('Personal Info'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Enter your email';
                      final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!re.hasMatch(v)) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Min 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        }),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _sectionHeader('Role & Ward'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _roleCard(
                        role: UserRole.doctor,
                        label: 'Doctor',
                        icon: Icons.medical_services_outlined,
                      ),
                      const SizedBox(width: 8),
                      _roleCard(
                        role: UserRole.nurse,
                        label: 'Nurse',
                        icon: Icons.local_hospital_outlined,
                      ),
                      const SizedBox(width: 8),
                      _roleCard(
                        role: UserRole.admin,
                        label: 'Admin',
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _wardIdController,
                    decoration: const InputDecoration(
                      labelText: 'Ward ID (optional)',
                      hintText: 'Paste an invite ID, or skip and join later',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (authProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _roleCard({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
