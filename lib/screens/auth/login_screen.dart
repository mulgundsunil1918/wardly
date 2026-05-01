import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/push_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/friendly_error.dart';
import 'background_setup_screen.dart';
import 'onboarding_screen.dart';

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
    await prefs.setBool(kOnboardingDoneKey, true);
    await prefs.remove('onboarding_complete'); // legacy
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
      // Pre-check: if this email is a Google-only account, redirect them.
      try {
        final methods =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty &&
            methods.contains('google.com') &&
            !methods.contains('password')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 6),
              content: const Text(
                'This email is linked to Google. Tap "Continue with Google" to sign in.',
              ),
            ),
          );
          return;
        }
      } catch (_) {}
      ok = await authProvider.signIn(email, password);
    } else {
      // Sign-up pre-check: email already registered with Google?
      try {
        final methods =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.contains('google.com') && !methods.contains('password')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 6),
              content: const Text(
                'This email already has a Google account. Tap "Sign up with Google" instead.',
              ),
            ),
          );
          return;
        }
        if (methods.contains('password')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.warning,
              content: const Text(
                'This email is already registered. Switch to Sign In.',
              ),
            ),
          );
          return;
        }
      } catch (_) {}
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
      PushService.register();
      if (!mounted) return;
      await _routePostAuth();
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(friendlyError(authProvider.error!)),
        ),
      );
    }
  }

  Future<void> _routePostAuth() async {
    if (BackgroundSetupScreen.shouldSkip()) {
      Navigator.of(context).pushReplacementNamed('/doctor/home');
      return;
    }
    final done = await BackgroundSetupScreen.isDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      done ? '/doctor/home' : '/background-setup',
    );
  }

  Future<void> _signInGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (ok && authProvider.currentUser != null) {
      await _markOnboardingDone();
      PushService.register();
      final user = authProvider.currentUser!;
      final needsName = user.name.trim().isEmpty ||
          user.name.trim() == user.email.split('@').first;
      if (!mounted) return;
      if (needsName) {
        await _promptForName(authProvider);
      }
      if (!mounted) return;
      await _routePostAuth();
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(friendlyError(authProvider.error!)),
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
    final email = result.trim();

    // Pre-check what sign-in methods Firebase has for this email so we
    // don't pretend a reset link is on the way when it physically can't
    // arrive (no account at all) or won't help (Google-only account).
    List<String> methods = const [];
    try {
      methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    } catch (_) {
      // Network blip or Email Enumeration Protection enabled on the
      // project — fall through and try the reset anyway.
    }
    if (!mounted) return;

    // Case A: nobody has registered with this email.
    if (methods.isEmpty) {
      // We can't tell apart "no account" vs "enumeration protection"
      // perfectly, but the message below covers both: if there IS an
      // account, the email arrives; if there isn't, the user knows.
      await _showResetInfoDialog(
        context,
        title: 'No account found for that email?',
        body:
            "We couldn't find an existing Wardly account for $email.\n\n"
            "• Double-check the spelling of the email address.\n"
            "• If you signed up with Google, go back and tap 'Continue "
            "with Google' — there's no password to reset.\n"
            "• If you've never signed up before, switch to 'Sign Up' "
            "and create one.",
      );
      return;
    }

    // Case B: account exists but uses Google sign-in only — no password.
    if (methods.contains('google.com') && !methods.contains('password')) {
      await _showResetInfoDialog(
        context,
        title: 'Use Google to sign in',
        body:
            "$email is linked to a Google account, so there's no Wardly "
            "password to reset.\n\n"
            "Go back to the Sign In screen and tap 'Continue with Google'.",
      );
      return;
    }

    // Case C: account has a password — actually send the reset email.
    final ok = await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    if (ok) {
      await _showResetInfoDialog(
        context,
        title: 'Check your inbox',
        body:
            "We sent a password-reset link to $email.\n\n"
            "It usually arrives within a minute. If you don't see it:\n\n"
            "1. Check your Spam / Junk folder.\n"
            "2. The link is valid for 1 hour. Tap 'Send link' again to "
            "get a fresh one if it's expired.\n"
            "3. Open it on the same device or any browser — the page "
            "lets you set a new password.",
      );
    } else {
      final err = context.read<AuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
          content: Text(
            err == null
                ? "Couldn't send the reset email. Try again in a moment."
                : "Reset failed — ${friendlyError(err)}",
          ),
        ),
      );
    }
  }

  Future<void> _showResetInfoDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
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
                        'Ward, connected',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w500,
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
