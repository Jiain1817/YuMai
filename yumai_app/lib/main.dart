import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'services/language_provider.dart';
import 'services/translations.dart';
import 'screen/home_screen.dart';
import 'screen/story_list_screen.dart';
import 'screen/ai_chat_screen.dart';
import 'screen/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('yumai_language') ?? 'zh';

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final langProvider = LanguageProvider();
  await langProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: langProvider),
      ],
      child: MyApp(initialLang: savedLang),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialLang;
  const MyApp({super.key, required this.initialLang});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: '语脉 · 三语智读',
          debugShowCheckedModeBanner: false,
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeMode: themeProvider.themeMode,
          home: AppShell(initialLang: initialLang),
        );
      },
    );
  }
}

/// AppShell — 底部 Tab 导航 + 首页入口
/// 4个 Tab: 首页 / 故事 / 问答 / 我的
class AppShell extends StatefulWidget {
  final String initialLang;
  const AppShell({super.key, required this.initialLang});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String _currentLang = 'zh';

  @override
  void initState() {
    super.initState();
    _currentLang = widget.initialLang;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          // Tab 0: 首页
          HomeScreen(
            initialLang: _currentLang,
            onEnterApp: () => _switchTab(1),
          ),
          // Tab 1: 故事列表
          StoryListScreen(initialLang: _currentLang),
          // Tab 2: AI 问答
          AIChatScreen(initialLang: _currentLang),
          // Tab 3: 个人中心
          ProfileScreen(initialLang: _currentLang),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }
}

/// 底部导航栏
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 LanguageProvider 的当前语言
    final currentLang = context.watch<LanguageProvider>().currentLang;
    final langMap = AppTranslations.bottomNav[currentLang] ?? AppTranslations.bottomNav['zh']!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

    final items = [
      (langMap['home'] ?? '首页', Icons.home_outlined, Icons.home),
      (langMap['stories'] ?? '故事', Icons.menu_book_outlined, Icons.menu_book),
      (langMap['qa'] ?? '问答', Icons.chat_bubble_outline, Icons.chat_bubble),
      (langMap['profile'] ?? '我的', Icons.person_outline, Icons.person),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final (label, icon, activeIcon) = items[i];
              final isActive = currentIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? activeIcon : icon,
                        color: isActive ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          color: isActive ? activeColor : inactiveColor,
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
