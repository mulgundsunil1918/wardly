import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { signIn, signUp }

class _LoginScreenState extends State<LoginScreen> {
  _Mode _mode = _Mode.signIn;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberDevice = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_device') ?? true;
    final saved = prefs.getString('saved_email');
    if (!mounted) return;
    setState(() {
      _rememberDevice = remember;
      if (remember && saved != null && saved.isNotEmpty) {
        _emailController.text = saved;
      }
    });
  }

  Future<void> _persistRememberDevice(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberDevice) {
      await prefs.setBool('remember_device', true);
      await prefs.setString('saved_email', email);
    } else {
      await prefs.setBool('remember_device', false);
      await prefs.remove('saved_email');
    }
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool ok;
    if (_mode == _Mode.signIn) {
      ok = await authProvider.signIn(email, password);
    } else {
      final name = _nameController.text.trim();
      ok = await authProvider.register(
        name: name,
        email: email,
        password: password,
        role: 'doctor', // roles hidden — everyone is a ward member
      );
    }

    if (!mounted) return;
    if (ok && authProvider.currentUser != null) {
      await _persistRememberDevice(email);
      await _markOnboardingDone();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/doctor/home');
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authProvider.error!),
        ),
      );
    }
  }

  Future<void> _signInGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (ok && authProvider.currentUser != null) {
      await _markOnboardingDone();
      final user = authProvider.currentUser!;
      final needsName = user.name.trim().isEmpty ||
          user.name.trim() == user.email.split('@').first;
      if (!mounted) return;
      if (needsName) {
        await _promptForName(authProvider);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/doctor/home');
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authProvider.error!),
        ),
      );
    }
  }

  Future<void> _promptForName(AuthProvider auth) async {
    final controller = TextEditingController(text: auth.currentUser?.name ?? '');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('What should we call you?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please use your real name — it makes tracking who posted or acknowledged a note much easier for your ward team.',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your full name',
                hintText: 'e.g. Ravi Kumar',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await auth.updateProfile(name: name);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final ec = TextEditingController(text: _emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: ec,
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
            onPressed: () => Navigator.pop(context, ec.text.trim()),
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
                height: size.height * 0.34,
                width: double.infinity,
                color: AppColors.primary,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 86,
                          height: 86,
                          errorBuilder: (_, __, ___) => Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                'W',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'WARDLY',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ward, connected',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          letterSpacing: 1.2,
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
            top: size.height * 0.28,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _modeToggle(),
                      const SizedBox(height: 24),
                      if (_mode == _Mode.signUp) ...[
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'Use your real name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              _mode == _Mode.signUp &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Please enter your name'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                      ],
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
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberDevice,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setState(() {
                                _rememberDevice = v ?? false;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _rememberDevice = !_rememberDevice;
                            }),
                            child: Text(
                              'Remember this device',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_mode == _Mode.signIn)
                            TextButton(
                              onPressed: _forgotPassword,
                              child: const Text('Forgot?'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _mode == _Mode.signIn
                                ? 'Sign In'
                                : 'Create Account',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: authProvider.isLoading ? null : _signInGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _mode == _Mode.signIn
                                ? 'Continue with Google'
                                : 'Sign up with Google',
                          ),
                        ),
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

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleTab('Sign In', _Mode.signIn),
          _toggleTab('Sign Up', _Mode.signUp),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, _Mode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
