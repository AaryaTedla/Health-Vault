import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MedicineTemplate {
  final String name;
  final String defaultDosage;
  final String defaultFrequency;
  final String defaultDuration;
  final String? defaultNotes;
  final List<TimeOfDay> defaultTimes;
  final List<String> aliases;

  const MedicineTemplate({
    required this.name,
    required this.defaultDosage,
    required this.defaultFrequency,
    required this.defaultDuration,
    required this.defaultTimes,
    this.defaultNotes,
    this.aliases = const [],
  });
}

class MedicineAutofillService {
  static List<MedicineTemplate> _catalog = const [];
  static List<_SearchEntry> _searchEntries = const [];
  static final Map<String, List<int>> _prefix2Index = {};
  static bool _isInitialized = false;
  static String _datasetVersion = 'hardcoded-fallback';

  static bool get isInitialized => _isInitialized;
  static int get catalogSize => _catalog.length;
  static String get datasetVersion => _datasetVersion;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final raw = await rootBundle.loadString('assets/data/medicines_v2.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['medicines'] as List<dynamic>? ?? const []);
      final loaded = <MedicineTemplate>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final timesRaw = (item['times'] as List<dynamic>? ?? const []);
        final parsedTimes = timesRaw
            .map((t) => _parseTimeOfDay((t ?? '').toString()))
            .whereType<TimeOfDay>()
            .toList(growable: false);

        loaded.add(
          MedicineTemplate(
            name: name,
            defaultDosage: (item['defaultDosage'] ?? 'As prescribed').toString(),
            defaultFrequency: (item['defaultFrequency'] ?? 'Once daily').toString(),
            defaultDuration: (item['defaultDuration'] ?? '30 days').toString(),
            defaultNotes: (item['defaultNotes'] ?? '').toString().trim().isEmpty
                ? null
                : (item['defaultNotes'] as String),
            defaultTimes: parsedTimes.isEmpty
                ? const [TimeOfDay(hour: 8, minute: 0)]
                : parsedTimes,
            aliases: (item['aliases'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList(growable: false),
          ),
        );
      }

      if (loaded.isNotEmpty) {
        _catalog = loaded;
        _datasetVersion = (decoded['version'] ?? 'v1').toString();
      }
    } catch (_) {
      // If dataset cannot be loaded, keep minimal fallback below.
    }

    if (_catalog.isEmpty) {
      _catalog = const [
        MedicineTemplate(
          name: 'Paracetamol',
          defaultDosage: '500 mg',
          defaultFrequency: 'Every 8 hours',
          defaultDuration: '3 days',
          defaultTimes: [
            TimeOfDay(hour: 6, minute: 0),
            TimeOfDay(hour: 14, minute: 0),
            TimeOfDay(hour: 22, minute: 0),
          ],
          aliases: ['dolo 650', 'calpol'],
        ),
        MedicineTemplate(
          name: 'Metformin',
          defaultDosage: '500 mg',
          defaultFrequency: 'Twice daily',
          defaultDuration: '30 days',
          defaultTimes: [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 20, minute: 0),
          ],
          aliases: ['glycomet'],
        ),
      ];
    }

    _buildSearchIndex();

    _isInitialized = true;
  }

  static List<MedicineTemplate> suggestTemplates(String query) {
    if (!_isInitialized || _catalog.isEmpty) {
      // Non-blocking fallback if init was not awaited for any reason.
      unawaitedSafeInit();
    }

    final q = _normalize(query);
    if (q.length < 2) return const [];

    final prefix = q.substring(0, 2);
    final candidateIndexes = _prefix2Index[prefix] ?? const <int>[];
    if (candidateIndexes.isEmpty) return const [];

    final bestScores = <MedicineTemplate, int>{};
    for (final idx in candidateIndexes) {
      final entry = _searchEntries[idx];
      final score = _scoreSearchEntry(entry, q, allowFuzzy: false);
      if (score > 0) {
        final existing = bestScores[entry.template] ?? 0;
        if (score > existing) {
          bestScores[entry.template] = score;
        }
      }
    }

    // Typo rescue pass: keep this capped so large buckets stay responsive.
    if (q.length >= 5 && bestScores.length < 8) {
      var fuzzyChecks = 0;
      const maxFuzzyChecks = 1800;
      for (final idx in candidateIndexes) {
        if (fuzzyChecks >= maxFuzzyChecks) break;

        final entry = _searchEntries[idx];
        if (!_looksLikeTypoCandidate(entry, q)) continue;
        fuzzyChecks++;

        final score = _scoreSearchEntry(entry, q, allowFuzzy: true);
        if (score <= 0) continue;

        final boosted = score + 10;
        final existing = bestScores[entry.template] ?? 0;
        if (boosted > existing) {
          bestScores[entry.template] = boosted;
        }
      }
    }

    final ranked = bestScores.entries
        .map((e) => MapEntry(e.key, e.value))
        .toList(growable: false);

    ranked.sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      return a.key.name.compareTo(b.key.name);
    });

    return ranked.map((e) => e.key).take(8).toList(growable: false);
  }

  static bool _looksLikeTypoCandidate(_SearchEntry entry, String query) {
    final queryLen = query.length;

    for (final term in entry.terms) {
      if (term.isEmpty) continue;
      if (term.codeUnitAt(0) != query.codeUnitAt(0)) continue;
      if ((term.length - queryLen).abs() > 2) continue;
      if (_commonPrefixLength(term, query) >= 3) {
        return true;
      }
    }

    return false;
  }

  static void _buildSearchIndex() {
    _prefix2Index.clear();
    final entries = <_SearchEntry>[];

    for (final template in _catalog) {
      final terms = _buildSearchTerms(template);
      if (terms.isEmpty) continue;
      entries.add(_SearchEntry(template: template, terms: terms));
    }

    for (var i = 0; i < entries.length; i++) {
      final terms = entries[i].terms;
      final seenPrefixes = <String>{};
      for (final term in terms) {
        if (term.length < 2) continue;
        final prefix = term.substring(0, 2);
        if (!seenPrefixes.add(prefix)) continue;
        final bucket = _prefix2Index.putIfAbsent(prefix, () => <int>[]);
        bucket.add(i);
      }
    }

    _searchEntries = entries;
  }

  static void unawaitedSafeInit() {
    init();
  }

  static TimeOfDay? _parseTimeOfDay(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    final parts = v.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static int _scoreSearchEntry(_SearchEntry entry, String query, {required bool allowFuzzy}) {
    final name = _normalize(entry.template.name);
    final terms = entry.terms;

    var score = 0;
    for (final term in terms) {
      if (term.isEmpty) continue;

      if (term == query) {
        score = score < 120 ? 120 : score;
        continue;
      }
      if (term.startsWith(query)) {
        score = score < 100 ? 100 : score;
        continue;
      }
      if (term.contains(query)) {
        score = score < 75 ? 75 : score;
      }

      if (allowFuzzy && query.length >= 5) {
        if ((term.length - query.length).abs() > 2) continue;
        final d = _levenshtein(term, query);
        final maxDistance = query.length >= 9 ? 3 : 2;
        if (d <= maxDistance) {
          final typoScore = 68 - (d * 10);
          if (typoScore > score) score = typoScore;
        }
      }
    }

    if (score > 0 && name.startsWith(query)) {
      score += 5;
    }
    return score;
  }

  static List<String> _buildSearchTerms(MedicineTemplate template) {
    final rawTexts = [template.name, ...template.aliases];
    final terms = <String>{};

    for (final raw in rawTexts) {
      final full = _normalize(raw);
      if (full.isNotEmpty) {
        terms.add(full);
      }

      final words = raw
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .map((w) => w.trim())
          .where((w) => w.length >= 3)
          .map(_normalize)
          .where((w) => w.isNotEmpty);
      terms.addAll(words);
    }

    return terms.take(24).toList(growable: false);
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        var best = deletion;
        if (insertion < best) best = insertion;
        if (substitution < best) best = substitution;
        curr[j] = best;
      }

      for (var j = 0; j < curr.length; j++) {
        prev[j] = curr[j];
      }
    }

    return prev[b.length];
  }

  static int _commonPrefixLength(String a, String b) {
    final end = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < end) {
      if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
        break;
      }
      i++;
    }
    return i;
  }
}

class _SearchEntry {
  final MedicineTemplate template;
  final List<String> terms;

  const _SearchEntry({
    required this.template,
    required this.terms,
  });
}
