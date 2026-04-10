import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/language_provider.dart';
import '../services/translations.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final String initialLang;
  final VoidCallback? onEnterApp;

  const HomeScreen({super.key, required this.initialLang, this.onEnterApp});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '汉语', 'native': '汉语'},
    {'code': 'bo', 'name': '藏语', 'native': 'བོད་སྐད'},
    {'code': 'ii', 'name': '彝语', 'native': 'ꆈꌠꉙ'},
  ];

  @override
  void initState() {
    super.initState();
  }

  String get _currentLang {
    try {
      return context.watch<LanguageProvider>().currentLang;
    } catch (_) {
      return widget.initialLang;
    }
  }

  void _changeLanguage(String lang) {
    context.read<LanguageProvider>().setLanguage(lang);
  }

  String _getSubtitle() {
    final t = AppTranslations.home[_currentLang]!;
    return t['subtitle1']!;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSec
        : AppColors.lightTextSec;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: Container(
        // 根据深浅模式使用不同的背景
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isDark
                ? AssetImage('assets/images/home_bg_dark.png') // 夜晚模式用暗色背景
                : AssetImage('assets/images/home_bg.jpg'), // 白天模式用亮色背景
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // 顶栏
                _TopBar(
                  currentLang: _currentLang,
                  languages: _languages,
                  onLanguageChange: _changeLanguage,
                  textSecondary: textSecondary,
                  primary: primary,
                  surface: surface,
                  borderColor: borderColor,
                  isDark: isDark,
                ),

                // 中心内容
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      _HeroContent(
                        primary: primary,
                        secondary: secondary,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        subtitle: _getSubtitle(),
                        isDark: isDark,
                        currentLang: _currentLang,
                      ),
                    ],
                  ),
                ),

                // 底部 CTA
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _EnterButton(
                    primary: primary,
                    onTap: widget.onEnterApp,
                    ctaText: AppTranslations.home[_currentLang]!['cta']!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ 顶栏 ============
class _TopBar extends StatelessWidget {
  final String currentLang;
  final List<Map<String, String>> languages;
  final ValueChanged<String> onLanguageChange;
  final Color textSecondary;
  final Color primary;
  final Color surface;
  final Color borderColor;
  final bool isDark;

  const _TopBar({
    required this.currentLang,
    required this.languages,
    required this.onLanguageChange,
    required this.textSecondary,
    required this.primary,
    required this.surface,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: primary.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '语脉',
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),

          const Spacer(),

          // 语言切换
          buildLanguageSwitcher(
            fontSize: 14,
            iconSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          ),

          const SizedBox(width: 8),

          // 主题切换
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 中心 Hero 内容（删除了语脉大标题） ============
class _HeroContent extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final String subtitle;
  final bool isDark;
  final String currentLang;

  const _HeroContent({
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.subtitle,
    required this.isDark,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚠️ 这里删除了原来的大标题 "语脉"（因为图片里已经有了）
        // 只保留副标题（藏语/彝语）
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 18,
            color: secondary,
            fontFamily: 'Noto Serif Tibetan',
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 32),

        // 三语徽章
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primary.withAlpha(15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangDot(label: '汉语', color: AppColors.hanGold, isDark: isDark),
              _dotSeparator(textSecondary),
              _LangDot(
                label: '藏语',
                color: AppColors.tibetanRed,
                isDark: isDark,
              ),
              _dotSeparator(textSecondary),
              _LangDot(label: '彝语', color: AppColors.yiGreen, isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 标语
        Text(
          AppTranslations.home[currentLang]!['subtitle2']!,
          style: TextStyle(
            color: textSecondary,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 8),

        // 副标语
        Text(
          AppTranslations.home[currentLang]!['subtitle3']!,
          style: TextStyle(
            color: textSecondary.withAlpha(150),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
}

class _LangDot extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _LangDot({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ],
    );
  }
}

Widget _dotSeparator(Color textSecondary) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10),
  child: Text(
    '·',
    style: TextStyle(color: textSecondary.withAlpha(100), fontSize: 16),
  ),
);

// ============ 进入按钮 ============
class _EnterButton extends StatelessWidget {
  final Color primary;
  final VoidCallback? onTap;
  final String ctaText;

  const _EnterButton({
    required this.primary,
    this.onTap,
    required this.ctaText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withAlpha(200)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: primary.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ctaText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
