import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final canEdit = !state.isGuardian;
    final appointments = state.appointments;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: appointments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_note_rounded,
                        size: 58, color: AppTheme.textHint),
                    const SizedBox(height: 14),
                    Text(
                      canEdit
                          ? 'No appointments scheduled yet.'
                          : 'No patient appointments shared yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (_, i) {
                final appt = appointments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                appt.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (canEdit)
                              IconButton(
                                onPressed: () => context
                                    .read<AppState>()
                                    .deleteAppointment(appt.id),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppTheme.danger),
                              ),
                          ],
                        ),
                        Text(
                          appt.hospital,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(appt.dateTime),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        if ((appt.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            appt.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        if (canEdit)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => context
                                  .read<AppState>()
                                  .toggleAppointmentCompleted(appt.id),
                              icon: Icon(
                                appt.completed
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                              ),
                              label: Text(
                                appt.completed ? 'Completed' : 'Mark Completed',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAppointmentSheet(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Appointment',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  static String _formatDateTime(DateTime dt) {
    final date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date at $hour:$minute $period';
  }

  void _showAddAppointmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAppointmentSheet(),
    );
  }
}

class _AddAppointmentSheet extends StatefulWidget {
  const _AddAppointmentSheet();

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _titleCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Appointment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Purpose *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hospitalCtrl,
              decoration: const InputDecoration(labelText: 'Hospital / Clinic *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        initialDate: _date,
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) {
                        setState(() => _time = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty ||
                      _hospitalCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill required fields')),
                    );
                    return;
                  }

                  final user = context.read<AppState>().currentUser;
                  final dt = DateTime(
                    _date.year,
                    _date.month,
                    _date.day,
                    _time.hour,
                    _time.minute,
                  );

                  context.read<AppState>().addAppointment(
                        Appointment(
                          id: const Uuid().v4(),
                          patientId: user?.uid ?? 'demo_001',
                          title: _titleCtrl.text.trim(),
                          hospital: _hospitalCtrl.text.trim(),
                          dateTime: dt,
                          notes: _notesCtrl.text.trim().isEmpty
                              ? null
                              : _notesCtrl.text.trim(),
                        ),
                      );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'Save Appointment',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
