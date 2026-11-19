import 'package:material_ui/material_ui.dart';

/// Colour tokens: black, grey and white (like the MINUM'S logo), with green / red / amber only
/// for status. Change a colour here and the whole app follows.
class Brand {
  static const primary = Color(0xFF151515); // black: buttons, selected states
  static const primaryDark = Color(0xFF000000);
  static const primarySoft = Color(0xFFECECEC); // light grey: selected chips, soft badges

  static const ink = Color(0xFF1A1A1A);
  static const grey = Color(0xFF6E6E6E);
  static const line = Color(0xFFE2E2E2);
  static const soft = Color(0xFFF2F2F2);
  static const cream = Color(0xFFF7F7F7); // page background
  static const white = Color(0xFFFFFFFF);

  /// Dark gradient for banners and hero areas.
  static const gradient = LinearGradient(
    colors: [Color(0xFF3A3A3A), Color(0xFF0B0B0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light grey gradient (like the app icon) for soft panels.
  static const gradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = Color(0xFF2E9E5B); // green: checked in, ready, paid
  static const successSoft = Color(0xFFE3F5EA);
  static const danger = Color(0xFFE03131); // red: log out, cancelled, check out
  static const dangerSoft = Color(0xFFFDE8E8);
  static const star = Color(0xFFFFB400);
  static const warn = Color(0xFFF08C00); // amber: low stock
  static const warnSoft = Color(0xFFFFF1D6);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: Brand.primary,
    onPrimary: Brand.white,
    secondary: Brand.primary,
    onSecondary: Brand.white,
    secondaryContainer: Brand.primarySoft,
    onSecondaryContainer: Brand.primaryDark,
    surface: Brand.white,
    onSurface: Brand.ink,
    error: Brand.danger,
    outline: Brand.line,
  );
  const radius = BorderRadius.all(Radius.circular(14));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.cream,
    dividerColor: Brand.line,
    dividerTheme: const DividerThemeData(color: Brand.line, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.cream,
      foregroundColor: Brand.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: Brand.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.primary,
        foregroundColor: Brand.white,
        disabledBackgroundColor: const Color(0xFFCFCFCF),
        disabledForegroundColor: Brand.white,
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.primary,
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: Brand.primary, width: 1.4),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Brand.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brand.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: Brand.line)),
      enabledBorder: const OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: Brand.line)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: Brand.primary, width: 1.6)),
      labelStyle: const TextStyle(color: Brand.grey),
      floatingLabelStyle:
          const TextStyle(color: Brand.primary, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Brand.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Brand.primarySoft,
      elevation: 0,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Brand.primary : Brand.grey)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? Brand.primary : Brand.grey)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Brand.ink,
      contentTextStyle: TextStyle(color: Brand.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brand.white : Brand.grey),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brand.primary : Brand.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Brand.primary, foregroundColor: Brand.white, shape: StadiumBorder()),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Brand.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
  );
}
