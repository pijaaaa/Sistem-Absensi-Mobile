import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/section_title.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/stat_tile.dart';
import 'package:mobile/core/widgets/status_chip.dart';

class DesignShowcaseScreen extends ConsumerWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Design Showcase'),
            const SizedBox(height: 8),
            Text(
              'Mode: ${isDark ? "Dark" : "Light"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Colors Section
            _buildSection(context, title: 'Brand Colors', children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _ColorSwatch(name: 'primary', color: AppColors.primary),
                  _ColorSwatch(name: 'primaryDark', color: AppColors.primaryDark),
                  _ColorSwatch(name: 'primarySoft', color: AppColors.primarySoft),
                  _ColorSwatch(name: 'accent', color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: isDark
                    ? [
                        _ColorSwatch(name: 'bg', color: AppColors.darkBackground),
                        _ColorSwatch(name: 'surface', color: AppColors.darkSurface),
                        _ColorSwatch(name: 'surfaceHi', color: AppColors.darkSurfaceHigh),
                        _ColorSwatch(name: 'text', color: AppColors.darkTextPrimary),
                      ]
                    : [
                        _ColorSwatch(name: 'bg', color: AppColors.lightBackground),
                        _ColorSwatch(name: 'surface', color: AppColors.lightSurface),
                        _ColorSwatch(name: 'text', color: AppColors.lightTextPrimary),
                        _ColorSwatch(name: 'text2', color: AppColors.lightTextSecondary),
                      ],
              ),
            ]),

            // Status Colors
            _buildSection(context, title: 'Status Colors', children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: 'Hadir', type: StatusType.present, customColor: AppColors.success),
                  StatusChip(label: 'Toleransi', type: StatusType.tolerance, customColor: AppColors.tolerance),
                  StatusChip(label: 'Telat', type: StatusType.lateYellow, customColor: AppColors.warningYellow),
                  StatusChip(label: 'Telat', type: StatusType.lateRed, customColor: AppColors.error),
                  StatusChip(label: 'Cuti', type: StatusType.leave, customColor: AppColors.info),
                  StatusChip(label: 'Sakit', type: StatusType.sick, customColor: AppColors.purple),
                  StatusChip(label: 'Izin', type: StatusType.permission, customColor: AppColors.cyan),
                  StatusChip(label: 'Dinas', type: StatusType.dinas, customColor: AppColors.teal),
                  StatusChip(label: 'Libur', type: StatusType.holiday, customColor: AppColors.grey),
                  StatusChip(label: 'Alfa', type: StatusType.absent, customColor: AppColors.alpha),
                  StatusChip(label: 'Pending', type: StatusType.pending, customColor: AppColors.pending),
                ],
              ),
            ]),

            // Typography
            _buildSection(context, title: 'Typography', children: [
              Text('Display Large (28)', style: AppTheme.displayLarge),
              const SizedBox(height: 4),
              Text('Display Medium (24)', style: AppTheme.displayMedium),
              const SizedBox(height: 4),
              Text('Title Large (20)', style: AppTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Body Large (14)', style: AppTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('Body Medium (14)', style: AppTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Body Small (12)', style: AppTheme.bodySmall),
            ]),

            // Buttons
            _buildSection(context, title: 'Buttons', children: [
              AppButton(text: 'Primary Button', onPressed: () {}),
              const SizedBox(height: 12),
              AppButton(text: 'Outline Button', onPressed: () {}, outline: true),
              const SizedBox(height: 12),
              AppButton(text: 'Button with Icon', onPressed: () {}, icon: Icons.fingerprint),
            ]),

            // Text Fields
            _buildSection(context, title: 'Text Fields', children: [
              AppTextField(
                controller: TextEditingController(),
                labelText: 'NIP / Email',
                hintText: 'Masukkan NIP atau email',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: TextEditingController(),
                labelText: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                suffixIcon: Icons.visibility_off,
              ),
            ]),

            // Cards & Stat Tiles
            _buildSection(context, title: 'Cards & Stats', children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      title: 'Hadir',
                      value: '18',
                      icon: Icons.check_circle,
                      iconColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      title: 'Telat',
                      value: '2',
                      icon: Icons.warning,
                      iconColor: AppColors.warningYellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      title: 'Sisa Cuti',
                      value: '8',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sample Card Content',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'This is a reusable card component.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            // Skeleton Loader
            _buildSection(context, title: 'Loading States', children: [
              const SkeletonLoader(height: 16),
              const SizedBox(height: 8),
              const SkeletonLoader(height: 16, width: 200),
              const SizedBox(height: 8),
              const SkeletonLoader(height: 16, width: 150),
            ]),

            // Error State
            _buildSection(context, title: 'Error State', children: [
              ErrorState(
                message: 'Terjadi kesalahan saat memuat data.',
                onRetry: () {},
              ),
            ]),

            // Empty State
            _buildSection(context, title: 'Empty State', children: [
              EmptyState(
                message: 'Belum ada data untuk ditampilkan.',
                onAction: () {},
                actionLabel: 'Muat Ulang',
              ),
            ]),

            const SizedBox(height: 24),

            // Theme toggle
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Theme toggle akan tersedia di profile screen')),
                  );
                },
                icon: const Icon(Icons.palette),
                label: const Text('Theme Toggle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorSwatch({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
             border: color.computeLuminance() > 0.5
                ? Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3))
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
