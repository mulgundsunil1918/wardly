import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _signInGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (ok && authProvider.currentUser != null) {
      Navigator.of(context).pushReplacementNamed(
        _routeForRole(authProvider.currentUser!.role),
      );
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authProvider.error!),
        ),
      );
    }
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final emailController =
        TextEditingController(text: _emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, emailController.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final ok = await context.read<AuthProvider>().sendPasswordReset(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? null : AppColors.danger,
        content: Text(
          ok
              ? 'Password reset link sent to $result'
              : context.read<AuthProvider>().error ?? 'Failed',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
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
          content: Text(authProvider.error ?? 'Sign in failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: size.height * 0.42,
                width: double.infinity,
                color: AppColors.primary,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_box,
                          color: AppColors.danger,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wardly',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ward, connected',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: Container(color: AppColors.surface)),
            ],
          ),
          Positioned.fill(
            top: size.height * 0.36,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to your ward',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 14),
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
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _forgotPassword(context),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _submit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Sign In'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _signInGoogle(context),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Continue with Google'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to Wardly?',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/register'),
                            child: const Text('Create account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
}
