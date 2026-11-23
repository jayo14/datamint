import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DataMint Design System Color Tokens (extracted from app.css)
class AppColors {
  // Primary Brand Tokens
  static const Color mint = Color(0xFF74E3B6); // --m: Primary glowing mint
  static const Color mintDeep = Color(0xFF0B9E6B); // --md: Deep emerald mint
  static const Color ink = Color(0xFF0D1F18); // --ink: Deep forest dark ink
  static const Color forest = Color(0xFF0F2A21); // --dk: Deep forest dark base
  static const Color mist = Color(0xFFEAFBF3); // --bg: Light mint background
  static const Color text = Color(0xFF3F5F52); // --tx: Secondary muted text
  static const Color line = Color(0xFFD5EDE2); // --line: Border & separator line
  
  // Modality & Accent Tokens
  static const Color butter = Color(0xFFFFF1B8); // --butter: Image task accent
  static const Color peach = Color(0xFFFFC9B0); // --peach: Review task accent
  static const Color sky = Color(0xFFD9F3FF); // --sky: Text task accent
  static const Color alert = Color(0xFFE5483A); // --alert: Alert / pending
  static const Color danger = Color(0xFFB3261E); // --danger: Error / rejected

  // Aliases for compatibility
  static const Color mintBg = mist;
  static const Color mintDark = forest;
  static const Color textMuted = text;
  static const Color mintBorder = line;
  static const Color mintActive = mintDeep;
  static const Color yellowAccent = butter;
  static const Color blueAccent = sky;
  static const Color white = Colors.white;

  static const Color mintPrimary = mint;
  static const Color mintLight = line;
  static const Color mintAccent = mintDeep;
  static const Color celoGold = Color(0xFFF59E0B);
  static const Color celoGoldLight = butter;
  static const Color darkBackground = Color(0xFF0A1C16);
  static const Color cardBgLight = Colors.white;
  static const Color borderLight = line;

  static const Color darkBg = Color(0xFF0A1C16);
  static const Color darkSurface = forest;
  static const Color darkCard = Color(0xFF14382C);
  static const Color darkBorder = Color(0xFF225241);
  static const Color darkTextPrimary = Color(0xFFF2FBF7);
  static const Color darkTextSecondary = Color(0xFF9EC5B6);
  static const Color darkTextMuted = Color(0xFF5D8877);

  static const Color lightBg = mist;
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightBorder = line;
  static const Color lightTextPrimary = ink;
  static const Color lightTextSecondary = text;
  static const Color lightTextMuted = Color(0xFF6B8B7E);

  static const Color success = mintDeep;
  static const Color warning = alert;
  static const Color error = danger;
  static const Color info = Color(0xFF2563EB);
}

/// ThemeExtension implementation for DataMint
class DataMintTheme extends ThemeExtension<DataMintTheme> {
  final Color mint;
  final Color mintDeep;
  final Color ink;
  final Color forest;
  final Color mist;
  final Color text;
  final Color line;
  final Color butter;
  final Color peach;
  final Color sky;
  final Color alert;
  final Color danger;

  final TextStyle display;
  final TextStyle heading;
  final TextStyle section;
  final TextStyle body;
  final TextStyle caption;

  const DataMintTheme({
    required this.mint,
    required this.mintDeep,
    required this.ink,
    required this.forest,
    required this.mist,
    required this.text,
    required this.line,
    required this.butter,
    required this.peach,
    required this.sky,
    required this.alert,
    required this.danger,
    required this.display,
    required this.heading,
    required this.section,
    required this.body,
    required this.caption,
  });

  factory DataMintTheme.light() {
    return DataMintTheme(
      mint: AppColors.mint,
      mintDeep: AppColors.mintDeep,
      ink: AppColors.ink,
      forest: AppColors.forest,
      mist: AppColors.mist,
      text: AppColors.text,
      line: AppColors.line,
      butter: AppColors.butter,
      peach: AppColors.peach,
      sky: AppColors.sky,
      alert: AppColors.alert,
      danger: AppColors.danger,
      display: GoogleFonts.bricolageGrotesque(
        fontSize: 46,
        fontWeight: FontWeight.w500,
        height: 1.03,
        letterSpacing: -1.84,
        color: AppColors.ink,
      ),
      heading: GoogleFonts.bricolageGrotesque(
        fontSize: 31,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: -0.93,
        color: AppColors.ink,
      ),
      section: GoogleFonts.bricolageGrotesque(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.38,
        color: AppColors.ink,
      ),
      body: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.text,
      ),
      caption: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.text,
      ),
    );
  }

  factory DataMintTheme.dark() {
    final light = DataMintTheme.light();
    return DataMintTheme(
      mint: AppColors.mint,
      mintDeep: AppColors.mintDeep,
      ink: Colors.white,
      forest: AppColors.forest,
      mist: AppColors.darkBg,
      text: AppColors.darkTextSecondary,
      line: AppColors.darkBorder,
      butter: AppColors.butter,
      peach: AppColors.peach,
      sky: AppColors.sky,
      alert: AppColors.alert,
      danger: AppColors.danger,
      display: light.display.copyWith(color: Colors.white),
      heading: light.heading.copyWith(color: Colors.white),
      section: light.section.copyWith(color: Colors.white),
      body: light.body.copyWith(color: AppColors.darkTextSecondary),
      caption: light.caption.copyWith(color: AppColors.darkTextMuted),
    );
  }

  @override
  ThemeExtension<DataMintTheme> copyWith({
    Color? mint,
    Color? mintDeep,
    Color? ink,
    Color? forest,
    Color? mist,
    Color? text,
    Color? line,
    Color? butter,
    Color? peach,
    Color? sky,
    Color? alert,
    Color? danger,
    TextStyle? display,
    TextStyle? heading,
    TextStyle? section,
    TextStyle? body,
    TextStyle? caption,
  }) {
    return DataMintTheme(
      mint: mint ?? this.mint,
      mintDeep: mintDeep ?? this.mintDeep,
      ink: ink ?? this.ink,
      forest: forest ?? this.forest,
      mist: mist ?? this.mist,
      text: text ?? this.text,
      line: line ?? this.line,
      butter: butter ?? this.butter,
      peach: peach ?? this.peach,
      sky: sky ?? this.sky,
      alert: alert ?? this.alert,
      danger: danger ?? this.danger,
      display: display ?? this.display,
      heading: heading ?? this.heading,
      section: section ?? this.section,
      body: body ?? this.body,
      caption: caption ?? this.caption,
    );
  }

  @override
  ThemeExtension<DataMintTheme> lerp(
    covariant ThemeExtension<DataMintTheme>? other,
    double t,
  ) {
    if (other is! DataMintTheme) return this;
    return DataMintTheme(
      mint: Color.lerp(mint, other.mint, t) ?? mint,
      mintDeep: Color.lerp(mintDeep, other.mintDeep, t) ?? mintDeep,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      forest: Color.lerp(forest, other.forest, t) ?? forest,
      mist: Color.lerp(mist, other.mist, t) ?? mist,
      text: Color.lerp(text, other.text, t) ?? text,
      line: Color.lerp(line, other.line, t) ?? line,
      butter: Color.lerp(butter, other.butter, t) ?? butter,
      peach: Color.lerp(peach, other.peach, t) ?? peach,
      sky: Color.lerp(sky, other.sky, t) ?? sky,
      alert: Color.lerp(alert, other.alert, t) ?? alert,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      display: TextStyle.lerp(display, other.display, t) ?? display,
      heading: TextStyle.lerp(heading, other.heading, t) ?? heading,
      section: TextStyle.lerp(section, other.section, t) ?? section,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
    );
  }
}

extension DataMintThemeX on BuildContext {
  DataMintTheme get dataMintTheme =>
      Theme.of(this).extension<DataMintTheme>() ?? DataMintTheme.light();
}

class AppTheme {
  static ThemeData get lightTheme {
    final dm = DataMintTheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.mist,
      extensions: [dm],
      colorScheme: const ColorScheme.light(
        primary: AppColors.mint,
        onPrimary: AppColors.ink,
        secondary: AppColors.mintDeep,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.line, width: 1.2),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.ink, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.text, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.ink,
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final dm = DataMintTheme.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.forest,
      extensions: [dm],
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mint,
        onPrimary: AppColors.ink,
        secondary: AppColors.mintDeep,
        onSecondary: Colors.white,
        surface: AppColors.forest,
        onSurface: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
