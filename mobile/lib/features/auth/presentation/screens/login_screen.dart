import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_button.dart';
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
  void initState() {
    super.initState();
    ref.read(authLoadingProvider.notifier).state = false;
  }

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
    const gradientHeight = 324.0;
    const headerPlaceholderHeight = 198.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: gradientHeight,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient(theme.brightness),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusXL),
                  bottomRight: Radius.circular(AppTheme.radiusXL),
                ),
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: Transform.scale(
                              scale: 1.2,
                              child: Image.asset(
                                'assets/images/bsplogo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.business,
                                    size: 48,
                                    color: AppColors.primary,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sistem Absensi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PT Bumi Siak Pusako',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
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
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: headerPlaceholderHeight),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                26,
                                22,
                                26,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXL,
                                ),
                                boxShadow: AppTheme.softShadow(
                                  theme.brightness,
                                ),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Selamat Datang',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Masuk dengan akun kepegawaian Anda',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 22),
                                    TextFormField(
                                      controller: _identifierController,
                                      decoration: const InputDecoration(
                                        labelText: 'NIP / Email',
                                        hintText: 'Masukkan NIP atau email',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'NIP/email harus diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Masukkan password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Tampilkan password'
                                              : 'Sembunyikan password',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
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
                                    AppButton(
                                      text: 'Masuk',
                                      icon: Icons.login_rounded,
                                      isLoading: isLoading,
                                      onPressed: _handleLogin,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'v1.0.0',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      await authRepo
          .login(
            login: _identifierController.text,
            password: _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'Login timeout',
                const Duration(seconds: 15),
              );
            },
          );

      // Android 13+: minta POST_NOTIFICATIONS sebelum berpindah halaman.
      if (mounted && context.mounted) {
        await PushNotificationService.instance.requestPermission(context);
      }

      final token = prefs.getString(StorageKeys.accessToken) ?? '';
      await ref.read(appStateProvider.notifier).loginSuccess(token);

      // Menu & permission akan dimuat di HomeScreen via homeInitProvider
    } on TimeoutException catch (e) {
      debugPrint('[LOGIN] Login timed out: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login gagal. Server tidak merespon dalam 15 detik. Pastikan backend berjalan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('[LOGIN] Login failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
