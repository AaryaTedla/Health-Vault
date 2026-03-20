import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});
  @override State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  bool _isTakenToday(MedicineReminder med) {
    final takenAt = med.lastTakenAt;
    if (takenAt == null) return false;
    final now = DateTime.now();
    return takenAt.year == now.year &&
        takenAt.month == now.month &&
        takenAt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meds = appState.medicines;
    final active = meds.where((m) => m.isActive).toList();
    final takenToday = active.where(_isTakenToday).length;
    final adherence = active.isEmpty ? 0.0 : takenToday / active.length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32))),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medicine Reminders', style: TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${active.length} active medicines',
                          style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                      ])),
                    GestureDetector(
                      onTap: () => _showAddMedicine(context),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 26)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // Progress
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Today's Adherence", style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('$takenToday/${active.length}', style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: adherence,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.secondary,
                      minHeight: 10)),
                  const SizedBox(height: 8),
                  Text(
                    active.isEmpty
                      ? 'No active medicines yet'
                      : '$takenToday of ${active.length} medicines marked taken today',
                    style: const TextStyle(fontSize: 13,
                      color: AppTheme.textSecondary)),
                ]),
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: const Text('Your Medicines', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),

          active.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.medication_outlined,
                      size: 64, color: AppTheme.textHint),
                    const SizedBox(height: 16),
                    const Text('No medicines added yet',
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('Tap Add Medicine to get started',
                      style: TextStyle(fontSize: 14,
                        color: AppTheme.textHint)),
                  ]),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i >= active.length) return null;
                    final med = active[i];
                    return _MedicineCard(
                      medicine: med,
                      index: i,
                      isTakenToday: _isTakenToday(med),
                      onToggleTaken: () => context.read<AppState>().setMedicineTakenToday(
                            med.id,
                            !_isTakenToday(med),
                          ),
                      onDelete: () => context.read<AppState>()
                        .deleteMedicine(med.id),
                    );
                  },
                  childCount: active.length,
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicine(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddMedicine(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicineSheet(
        onAdd: (med) => context.read<AppState>().addMedicine(med),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final MedicineReminder medicine;
  final int index;
  final bool isTakenToday;
  final VoidCallback onToggleTaken;
  final VoidCallback onDelete;

  const _MedicineCard({required this.medicine, required this.index,
    required this.isTakenToday, required this.onToggleTaken,
    required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.medication_rounded,
                color: color, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.medicineName, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(medicine.dosage, style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
                Text('${medicine.frequency} · ${medicine.duration}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
              ])),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textHint),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete',
                  child: Text('Delete',
                    style: TextStyle(color: AppTheme.danger))),
              ],
              onSelected: (v) { if (v == 'delete') onDelete(); },
            ),
          ]),
          const SizedBox(height: 14),
          const Text('Reminder times:', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: medicine.times.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.alarm_rounded,
                  color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(t, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppTheme.primary)),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onToggleTaken,
              icon: Icon(
                isTakenToday ? Icons.undo_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isTakenToday ? 'Marked Taken Today (Undo)' : 'Mark as Taken Today',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTakenToday ? AppTheme.secondary : AppTheme.primary,
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
          if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${medicine.notes}', style: const TextStyle(
              fontSize: 12, color: AppTheme.textHint)),
          ],
        ]),
      ).animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index))
        .slideY(begin: 0.05),
    );
  }
}

class _AddMedicineSheet extends StatefulWidget {
  final void Function(MedicineReminder) onAdd;
  const _AddMedicineSheet({required this.onAdd});
  @override State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30 days');
  final _notesCtrl = TextEditingController();
  String _frequency = 'Once daily';
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  final List<String> _frequencies = [
    'Once daily', 'Twice daily', 'Three times daily',
    'Every 6 hours', 'Every 8 hours', 'Weekly', 'As needed'
  ];

  final List<String> _commonMedicines = [
    'Amlodipine', 'Atorvastatin', 'Metformin', 'Lisinopril',
    'Metoprolol', 'Omeprazole', 'Aspirin', 'Losartan',
    'Simvastatin', 'Ramipril', 'Glibenclamide', 'Pantoprazole',
    'Telmisartan', 'Rosuvastatin', 'Clopidogrel', 'Atenolol',
    'Furosemide', 'Spironolactone', 'Levothyroxine', 'Vitamin D3',
    'Calcium', 'Iron', 'Folic Acid', 'Paracetamol', 'Ibuprofen',
    'Cetirizine', 'Salbutamol', 'Digoxin', 'Warfarin', 'B12',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _dosageCtrl.dispose();
    _durationCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  void _updateTimesForFrequency(String freq) {
    setState(() {
      if (freq == 'Once daily') {
        _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
      } else if (freq == 'Twice daily') {
        _selectedTimes = [const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)];
      } else if (freq == 'Three times daily') {
        _selectedTimes = [const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)];
      } else if (freq == 'Every 6 hours') {
        _selectedTimes = [const TimeOfDay(hour: 6, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 18, minute: 0),
          const TimeOfDay(hour: 0, minute: 0)];
      } else {
        _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!),
    );
    if (picked != null) setState(() => _selectedTimes[index] = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Medicine', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Set up your medicine reminder', style: TextStyle(
              fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),

            // Medicine name
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Medicine name *',
                hintText: 'e.g. Metformin',
                prefixIcon: const Icon(Icons.medication_rounded,
                  color: AppTheme.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary, width: 2))),
              onChanged: (v) {
                if (v.length >= 2) {
                  setState(() {
                    _suggestions = _commonMedicines
                      .where((m) => m.toLowerCase()
                        .startsWith(v.toLowerCase()))
                      .take(5).toList();
                    _showSuggestions = _suggestions.isNotEmpty;
                  });
                } else {
                  setState(() => _showSuggestions = false);
                }
              },
            ),

            if (_showSuggestions)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(
                  children: _suggestions.map((s) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.medication_rounded,
                      color: AppTheme.primary, size: 20),
                    title: Text(s, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
                    onTap: () {
                      _nameCtrl.text = s;
                      setState(() => _showSuggestions = false);
                    },
                  )).toList(),
                ),
              ),

            const SizedBox(height: 14),

            // Dosage
            TextField(
              controller: _dosageCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 500mg, 1 tablet',
                prefixIcon: const Icon(Icons.scale_rounded,
                  color: AppTheme.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary, width: 2))),
            ),

            const SizedBox(height: 14),

            // Frequency
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: 'Frequency',
                prefixIcon: const Icon(Icons.repeat_rounded,
                  color: AppTheme.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider))),
              items: _frequencies.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f, style: const TextStyle(fontSize: 15)))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _frequency = v);
                  _updateTimesForFrequency(v);
                }
              },
            ),

            const SizedBox(height: 14),

            // Duration
            TextField(
              controller: _durationCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Duration',
                hintText: 'e.g. 30 days, Ongoing',
                prefixIcon: const Icon(Icons.calendar_month_rounded,
                  color: AppTheme.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary, width: 2))),
            ),

            const SizedBox(height: 14),

            // Notes
            TextField(
              controller: _notesCtrl,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Take after food',
                prefixIcon: const Icon(Icons.notes_rounded,
                  color: AppTheme.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary, width: 2))),
            ),

            const SizedBox(height: 20),

            const Text('Reminder Times', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Tap any time to change it', style: TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10, runSpacing: 10,
              children: List.generate(_selectedTimes.length, (i) =>
                GestureDetector(
                  onTap: () => _pickTime(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.alarm_rounded,
                        color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(_formatTime(_selectedTimes[i]), style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded,
                        color: AppTheme.primary, size: 14),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter medicine name'),
                        backgroundColor: AppTheme.warning));
                    return;
                  }
                  final times = _selectedTimes.map(_formatTime).toList();
                  final uid = context.read<AppState>().currentUser?.uid
                    ?? 'demo_001';
                  final med = MedicineReminder(
                    id: const Uuid().v4(),
                    patientId: uid,
                    medicineName: _nameCtrl.text.trim(),
                    dosage: _dosageCtrl.text.trim().isEmpty
                      ? 'As prescribed' : _dosageCtrl.text.trim(),
                    frequency: _frequency,
                    times: times,
                    duration: _durationCtrl.text.isEmpty
                      ? '30 days' : _durationCtrl.text,
                    startDate: DateTime.now(),
                    isActive: true,
                    notes: _notesCtrl.text.trim().isEmpty
                      ? null : _notesCtrl.text.trim(),
                  );
                  widget.onAdd(med);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ ${_nameCtrl.text} added!'),
                    backgroundColor: AppTheme.secondary));
                },
                icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
                label: const Text('Save Medicine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}