import 'package:flutter/material.dart';

/// 语脉 App 统一主题配置
/// 古典典雅 × 年轻活力 平衡色调
class AppColors {
  AppColors._();

  // ============ Light 模式 ============
  static const Color lightBg       = Color(0xFFFAF7F4); // 暖白纸质感
  static const Color lightSurface  = Color(0xFFFFFFFF); // 卡片
  static const Color lightBorder   = Color(0xFFE8E0D8); // 微暖边框
  static const Color lightDivider  = Color(0xFFE8E0D8); // 分割线

  // 文字
  static const Color lightText     = Color(0xFF3D2E1F); // 深棕墨色
  static const Color lightTextSec  = Color(0xFF8C7B6B); // 暖灰次要

  // 强调色（亮暗共用同一色相，透明度区分）
  static const Color accentCoral   = Color(0xFFE07A5F); // 珊瑚橘（活力）
  static const Color accentGold     = Color(0xFFC9A96E); // 暖金色（典雅）

  // 语义色
  static const Color success       = Color(0xFF7CB342);
  static const Color danger        = Color(0xFFEF5350);
  static const Color info          = Color(0xFF64B5F6);

  // 民族特色（点缀用）
  static const Color tibetanRed    = Color(0xFFB85C4A);
  static const Color yiGreen       = Color(0xFF5C8A6A);
  static const Color hanGold       = Color(0xFFD4A574);

  // ============ Dark 模式 ============
  static const Color darkBg        = Color(0xFF1C1816); // 温暖深炭
  static const Color darkSurface   = Color(0xFF2A2421); // 卡片
  static const Color darkBorder   = Color(0xFF3D3532); // 微暖边框
  static const Color darkDivider  = Color(0xFF3D3532); // 分割线

  // 文字
  static const Color darkText      = Color(0xFFF5EDE6); // 暖白
  static const Color darkTextSec   = Color(0xFF9B8B80); // 暖灰
}

/// 语义颜色 — 根据 brightness 返回对应色值
class SemanticColors {
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? AppColors.lightBg : AppColors.darkBg;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? AppColors.lightSurface : AppColors.darkSurface;

  static Color border(Brightness brightness) =>
      brightness == Brightness.light ? AppColors.lightBorder : AppColors.darkBorder;

  static Color primary(BuildContext context) => AppColors.accentCoral;
  static Color secondary(BuildContext context) => AppColors.accentGold;

  static Color textPrimary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? AppColors.lightText : AppColors.darkText;
  }

  static Color textSecondary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? AppColors.lightTextSec : AppColors.darkTextSec;
  }
}

/// Light 主题
ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentCoral,
      secondary: AppColors.accentGold,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightText,
      outline: AppColors.lightBorder,
    ),
    fontFamily: 'Noto Sans TC',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentCoral,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentCoral,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.accentCoral, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.lightTextSec, fontSize: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.accentCoral,
      unselectedItemColor: AppColors.lightTextSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: AppColors.darkText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Dark 主题
ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentCoral,
      secondary: AppColors.accentGold,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkText,
      outline: AppColors.darkBorder,
    ),
    fontFamily: 'Noto Sans TC',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentCoral,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentCoral,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.accentCoral, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.darkTextSec, fontSize: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.accentCoral,
      unselectedItemColor: AppColors.darkTextSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightSurface,
      contentTextStyle: const TextStyle(color: AppColors.lightText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
