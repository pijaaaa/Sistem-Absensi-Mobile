import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:mobile/features/leave/presentation/screens/leave_history_tab.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(leaveBalanceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengajuan'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Ajukan'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Riwayat'),
                    balanceAsync.when(
                      data: (balance) => balance.remaining > 0
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${balance.remaining}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FormTab(),
            HistoryTab(),
          ],
        ),
      ),
    );
  }
}

// Form tab sebagai ConsumerStatefulWidget
class _FormTab extends ConsumerStatefulWidget {
  const _FormTab();

  @override
  ConsumerState<_FormTab> createState() => _FormTabState();
}

class _FormTabState extends ConsumerState<_FormTab> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedType = 'cuti';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _attachmentPath;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(leaveBalanceProvider);
    final submissionState = ref.watch(leaveSubmissionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Leave balance info
            balanceAsync.when(
              data: (balance) => AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa Cuti ${balance.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balance.remaining} hari',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Terpakai: ${balance.used}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Kuota: ${balance.quota}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            Text(
              'Jenis Pengajuan',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('cuti', 'Cuti'),
                _buildTypeChip('sakit', 'Sakit'),
                _buildTypeChip('izin', 'Izin'),
                _buildTypeChip('dinas', 'Dinas'),
              ],
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _startDateController,
              labelText: 'Tanggal Mulai',
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectStartDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal mulai harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _endDateController,
              labelText: 'Tanggal Akhir',
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectEndDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal akhir harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan',
                hintText: 'Masukkan alasan pengajuan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alasan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            if (_selectedType == 'sakit')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lampiran (Opsional)',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_attachmentPath == null
                        ? 'Pilih File'
                        : 'File dipilih'),
                  ),
                  if (_attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _attachmentPath!.split('/').last,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            if (_selectedType == 'sakit') const SizedBox(height: 20),

            if (_startDate != null && _endDate != null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Jenis', _getTypeLabel()),
                    _buildInfoRow(
                      context,
                      'Periode',
                      '${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate!)}',
                    ),
                    _buildInfoRow(
                      context,
                      'Durasi',
                      '${_endDate!.difference(_startDate!).inDays + 1} hari',
                    ),
                  ],
                ),
              ),
            if (_startDate != null && _endDate != null) const SizedBox(height: 20),

            submissionState.when(
              data: (_) => AppButton(
                text: 'Kirim Pengajuan',
                onPressed: _submit,
              ),
              loading: () => AppButton(
                text: 'Mengirim...',
                onPressed: null,
                isLoading: true,
              ),
              error: (error, _) => Column(
                children: [
                  Text(
                    error.toString().replaceAll('Exception: ', ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Kirim Pengajuan',
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (_selectedType) {
      case 'cuti':
        return 'Cuti Tahunan';
      case 'sakit':
        return 'Izin Sakit';
      case 'izin':
        return 'Izin Pribadi';
      case 'dinas':
        return 'Dinas';
      default:
        return 'Cuti Tahunan';
    }
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('dd MMM yyyy', 'id_ID').format(picked);
        if (_endDate == null || _endDate!.isBefore(picked)) {
          _endDate = picked;
          _endDateController.text = DateFormat('dd MMM yyyy', 'id_ID').format(picked);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('dd MMM yyyy', 'id_ID').format(picked);
      });
    }
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        _attachmentPath = result.path;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_startDate == null || _endDate == null) return;

    await ref.read(leaveSubmissionProvider.notifier).submitRequest(
          type: _selectedType,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text.trim(),
          attachmentPath: _attachmentPath,
        );

    final state = ref.read(leaveSubmissionProvider);
    if (mounted && state.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim')),
      );

      // Reset form
      _formKey.currentState?.reset();
      setState(() {
        _startDate = null;
        _endDate = null;
        _attachmentPath = null;
        _selectedType = 'cuti';
      });
      _reasonController.clear();
      _startDateController.clear();
      _endDateController.clear();
    }
  }
}
