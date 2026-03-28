import '../models/models.dart';

class RiskFlagService {
  static List<String> medicineRiskFlags({
    required List<MedicineReminder> medicines,
    required int missedDoseCount,
  }) {
    final flags = <String>[];

    final names = medicines
        .where((m) => m.isActive)
        .map((m) => m.medicineName.toLowerCase())
        .toList(growable: false);

    bool has(String keyword) => names.any((n) => n.contains(keyword));

    if (missedDoseCount >= 2) {
      flags.add('Multiple doses overdue today. Consider immediate follow-up.');
    }

    if (has('aspirin') && has('warfarin')) {
      flags.add('Potential bleeding-risk combo detected: Aspirin + Warfarin.');
    }

    if (has('metformin') && has('insulin')) {
      flags.add('Monitor sugar closely: Metformin with Insulin in use.');
    }

    if (has('telmisartan') && has('amlodipine')) {
      flags.add('BP medicines combined. Watch for low BP symptoms or dizziness.');
    }

    if (has('atorvastatin') && has('clarithromycin')) {
      flags.add('Possible statin interaction risk: Atorvastatin + Clarithromycin.');
    }

    return flags;
  }
}
