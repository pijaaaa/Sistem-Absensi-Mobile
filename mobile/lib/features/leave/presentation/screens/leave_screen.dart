import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/core/widgets/status_chip.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedType = 'cuti';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengajuan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ajukan'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FormTabPlaceholder(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _startDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        if (_endDate.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _endDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan berhasil dikirim')),
    );
    _formKey.currentState?.reset();
    _reasonController.clear();
    _startDateController.clear();
    _endDateController.clear();
  }
}

// Form tab sebagai StatefulWidget terpisah
class _FormTabPlaceholder extends StatefulWidget {
  const _FormTabPlaceholder();

  @override
  State<_FormTabPlaceholder> createState() => _FormTabPlaceholderState();
}

class _FormTabPlaceholderState extends State<_FormTabPlaceholder> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedType = 'cuti';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _endDateController,
              labelText: 'Tanggal Akhir',
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectEndDate,
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
                if (value == null || value.isEmpty) return 'Alsan harus diisi';
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
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Pilih File'),
                  ),
                ],
              ),
            if (_selectedType == 'sakit') const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Jenis', _getTypeLabel()),
                  _buildInfoRow(context, 'Periode', '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}'),
                  _buildInfoRow(context, 'Durasi', '${_endDate.difference(_startDate).inDays + 1} hari'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Kirim Pengajuan',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (_selectedType) {
      case 'cuti': return 'Cuti Tahunan';
      case 'sakit': return 'Izin Sakit';
      case 'izin': return 'Izin Pribadi';
      case 'dinas': return 'Dinas';
      default: return 'Cuti Tahunan';
    }
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _startDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        if (_endDate.isBefore(picked)) _endDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _endDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan berhasil dikirim')),
    );
    _formKey.currentState?.reset();
    _reasonController.clear();
    _startDateController.clear();
    _endDateController.clear();
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {'label': 'Cuti Tahunan', 'date': '10-15 Okt 2026', 'status': 'Disetujui', 'statusType': StatusType.approved},
      {'label': 'Izin Sakit', 'date': '08 Okt 2026', 'status': 'Ditolak', 'statusType': StatusType.rejected},
      {'label': 'Izin Pribadi', 'date': '05 Okt 2026', 'status': 'Pending', 'statusType': StatusType.pending},
    ];

    if (items.isEmpty) {
      return const Center(child: Text('Belum ada riwayat pengajuan'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.document_scanner, color: AppColors.primary),
            ),
            title: Text(item['label'] as String? ?? ''),
            subtitle: Text(item['date'] as String? ?? ''),
            trailing: StatusChip(
              label: item['status'] as String? ?? '',
              type: item['statusType'] as StatusType,
              outline: true,
            ),
          ),
        );
      },
    );
  }
}
