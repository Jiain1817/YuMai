import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局语言状态管理
/// 解决的问题：
/// 1. 各屏幕独立读取 SharedPreferences，无法感知其他屏幕的语言变化
/// 2. 语言变化后通过 notifyListeners() 广播，所有 Consumer 自动重建
/// 3. 提供统一的翻译入口 AppTranslations.t()
class LanguageProvider extends ChangeNotifier {
  static const String _langKey = 'yumai_language'; // 'zh' | 'bo' | 'ii'

  String _currentLang = 'zh';
  String get currentLang => _currentLang;

  /// 初始化：从 SharedPreferences 读取保存的语言
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_langKey) ?? 'zh';
    if (['zh', 'bo', 'ii'].contains(saved)) {
      _currentLang = saved;
    }
    // 不在这里 notifyListeners()，避免首次 build 时过度重建
  }

  /// 切换语言：保存 + 广播
  Future<void> setLanguage(String lang) async {
    if (!['zh', 'bo', 'ii'].contains(lang)) return;
    if (_currentLang == lang) return;

    _currentLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
    notifyListeners(); // 通知所有 Consumer 重建
  }
}
