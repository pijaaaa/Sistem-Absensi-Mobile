import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // Logo
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: Image.asset(
                        'assets/images/bsplogo.png',
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.business, size: 80);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Sistem Absensi',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PT Bumi Siak Pusako',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // NIP / Email field
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: 'NIP / Email',
                      hintText: 'Masukkan NIP atau email',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'NIP atau email harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password harus diisi';
                      }
                      if (value.length < 3) {
                        return 'Password minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    ref.read(authLoadingProvider.notifier).state = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final isManager =
          _identifierController.text.contains('manager') ||
          _identifierController.text.contains('001');
      final name = isManager ? 'Andi Wijaya' : 'Fikri Ramadhan';

      ref.read(authStateProvider.notifier).setAuthenticated(
            token: 'dummy_token',
            user: UserModel(
              id: 1,
              name: name,
              email: _identifierController.text,
              role: isManager ? 'manager_department' : 'karyawan',
              employee: EmployeeModel(
                id: 1,
                nip: 'EMP001',
                name: name,
                departmentId: 1,
                workLocationId: 1,
              ),
            ),
            menus: isManager
                ? [
                    {
                      'feature_key': 'home',
                      'label': 'Beranda',
                      'icon': 'home'
                    },
                    {
                      'feature_key': 'attendance',
                      'label': 'Absen',
                      'icon': 'fingerprint'
                    },
                    {
                      'feature_key': 'history',
                      'label': 'Riwayat',
                      'icon': 'calendar'
                    },
                    {
                      'feature_key': 'leave',
                      'label': 'Pengajuan',
                      'icon': 'document'
                    },
                    {
                      'feature_key': 'approval',
                      'label': 'Approval',
                      'icon': 'check_circle'
                    },
                    {
                      'feature_key': 'team_stats',
                      'label': 'Statistik Tim',
                      'icon': 'bar_chart'
                    },
                    {
                      'feature_key': 'notification',
                      'label': 'Notifikasi',
                      'icon': 'bell'
                    },
                    {
                      'feature_key': 'profile',
                      'label': 'Profil',
                      'icon': 'person'
                    },
                  ]
                : [
                    {
                      'feature_key': 'home',
                      'label': 'Beranda',
                      'icon': 'home'
                    },
                    {
                      'feature_key': 'attendance',
                      'label': 'Absen',
                      'icon': 'fingerprint'
                    },
                    {
                      'feature_key': 'history',
                      'label': 'Riwayat',
                      'icon': 'calendar'
                    },
                    {
                      'feature_key': 'leave',
                      'label': 'Pengajuan',
                      'icon': 'document'
                    },
                    {
                      'feature_key': 'notification',
                      'label': 'Notifikasi',
                      'icon': 'bell'
                    },
                    {
                      'feature_key': 'profile',
                      'label': 'Profil',
                      'icon': 'person'
                    },
                  ],
            permissions: {
              'attendance.view',
              'attendance.create',
              'leave.view',
              'leave.create',
              'notification.view',
              if (isManager) ...{
                'approval.view',
                'approval.approve',
                'team_stats.view',
              },
            },
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
