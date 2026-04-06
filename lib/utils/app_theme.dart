import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B6CA8);
  static const Color primaryLight = Color(0xFF4A9DD4);
  static const Color primaryDark = Color(0xFF0D4E7A);
  static const Color secondary = Color(0xFF2ECC71);
  static const Color accent = Color(0xFFE67E22);
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF5A6A7A);
  static const Color textHint = Color(0xFF9AAABB);
  static const Color divider = Color(0xFFE8EDF2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      // Elderly-friendly text theme with larger sizes
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(
            fontSize: 26, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            height: 1.8),
        bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            height: 1.8),
        bodySmall: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w400, color: textHint),
        labelLarge:
            GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      // Large, easy-to-tap buttons for elderly users
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 72), // Increased from 58
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          minimumSize: const Size(double.infinity, 58),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: GoogleFonts.poppins(fontSize: 15, color: textHint),
        labelStyle: GoogleFonts.poppins(fontSize: 15, color: textSecondary),
        floatingLabelStyle: GoogleFonts.poppins(fontSize: 13, color: primary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary, size: 26),
      ),
      scaffoldBackgroundColor: surface,
    );
  }
}

class AppConstants {
  static const String appName = 'HealthVault';
  static String get geminiApiKey {
    final envKey = dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '';
    if (envKey.isNotEmpty) return envKey;
    return const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  }

  static String get tunnelBaseUrl {
    final envUrl = dotenv.env['HEALTHVAULT_TUNNEL_URL']?.trim() ?? '';
    if (envUrl.isNotEmpty) return envUrl;
    return const String.fromEnvironment('HEALTHVAULT_TUNNEL_URL',
        defaultValue: '');
  }

  static String get tunnelAuthToken {
    final envToken = dotenv.env['HEALTHVAULT_TUNNEL_TOKEN']?.trim() ?? '';
    if (envToken.isNotEmpty) return envToken;
    return const String.fromEnvironment('HEALTHVAULT_TUNNEL_TOKEN',
        defaultValue: '');
  }

  static String get tunnelModel {
    final envModel = dotenv.env['HEALTHVAULT_TUNNEL_MODEL']?.trim() ?? '';
    if (envModel.isNotEmpty) return envModel;
    return const String.fromEnvironment(
      'HEALTHVAULT_TUNNEL_MODEL',
      defaultValue: 'local-health-model',
    );
  }

  static int get cloudFallbackDailyCap {
    final envCapRaw =
        dotenv.env['HEALTHVAULT_CLOUD_FALLBACK_DAILY_CAP']?.trim() ?? '';
    final envCap = int.tryParse(envCapRaw);
    if (envCap != null && envCap > 0) return envCap;
    const buildCapRaw = String.fromEnvironment(
      'HEALTHVAULT_CLOUD_FALLBACK_DAILY_CAP',
      defaultValue: '20',
    );
    final buildCap = int.tryParse(buildCapRaw);
    if (buildCap != null && buildCap > 0) return buildCap;
    return 20;
  }

  static const List<String> languages = [
    'English',
    'Hindi',
    'Telugu',
    'Kannada',
    'Tamil'
  ];

  static const List<String> documentTypes = [
    'Prescription',
    'Lab Report',
    'Scan / X-Ray',
    'Discharge Summary',
    'Medical Bill',
    'Other'
  ];

  static const List<String> frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 6 hours',
    'Every 8 hours',
    'Weekly',
    'As needed'
  ];

  static const List<String> commonMedicines = [
    'Amlodipine',
    'Atorvastatin',
    'Metformin',
    'Lisinopril',
    'Metoprolol',
    'Omeprazole',
    'Aspirin',
    'Losartan',
    'Simvastatin',
    'Ramipril',
    'Glibenclamide',
    'Pantoprazole',
    'Telmisartan',
    'Rosuvastatin',
    'Clopidogrel',
    'Atenolol',
    'Furosemide',
    'Spironolactone',
    'Levothyroxine',
    'Vitamin D3',
    'Calcium',
    'Iron',
    'Folic Acid',
    'Paracetamol',
    'Ibuprofen',
    'Cetirizine',
    'Salbutamol',
    'Digoxin',
    'Warfarin',
    'B12',
  ];

  static const String medicalDisclaimer =
      '⚕️ This AI summary is NOT a medical diagnosis. Please consult a qualified doctor before making any medical decisions.';

  static const String chatDisclaimer =
      '⚕️ This is not a medical diagnosis. Please consult a doctor for proper evaluation.';
}
