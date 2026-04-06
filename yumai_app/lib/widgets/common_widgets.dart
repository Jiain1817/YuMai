import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';

/// 通用加载遮罩组件
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(77),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// 通用错误弹窗（支持多语言）
void showErrorDialog(BuildContext context, String message, {String? title, String? confirmText}) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
  final textSecondary = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: surfaceColor,
      title: Text(
        title ?? '提示',
        style: TextStyle(color: textPrimary),
      ),
      content: Text(
        message,
        style: TextStyle(color: textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            confirmText ?? '确定',
            style: TextStyle(color: textSecondary),
          ),
        ),
      ],
    ),
  );
}

/// 通用空状态组件
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String actionText;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionText = '去浏览',
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textSecondary.withAlpha(128)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 全局语言切换按钮（统一样式）
/// [fontSize] 按钮文字大小，默认 12
/// [iconSize] 图标大小，默认 14
/// [padding] 按钮内边距，默认 EdgeInsets.symmetric(horizontal: 12, vertical: 5)
Widget buildLanguageSwitcher({
  double? fontSize,
  double? iconSize,
  EdgeInsetsGeometry? padding,
}) {
  return Consumer<LanguageProvider>(
    builder: (context, provider, _) {
      final currentLang = provider.currentLang;
      final langs = [
        {'code': 'zh', 'native': '汉语'},
        {'code': 'bo', 'native': 'བོད་སྐད'},
        {'code': 'ii', 'native': 'ꆈꌠꉙ'},
      ];
      final currentLangData = langs.firstWhere((l) => l['code'] == currentLang);
      final surfaceColor = SemanticColors.surface(Theme.of(context).brightness);
      final borderColor = SemanticColors.border(Theme.of(context).brightness);
      final textSecondary = SemanticColors.textSecondary(context);
      final primary = Theme.of(context).colorScheme.primary;

      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: PopupMenuButton<String>(
          onSelected: (String code) {
            provider.setLanguage(code);
          },
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: surfaceColor,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: iconSize ?? 14, color: textSecondary),
                const SizedBox(width: 5),
                Text(
                  currentLangData['native']!,
                  style: TextStyle(color: textSecondary, fontSize: fontSize ?? 12),
                ),
                Icon(Icons.arrow_drop_down, color: textSecondary, size: (iconSize ?? 14) + 4),
              ],
            ),
          ),
          itemBuilder: (ctx) => langs.map((lang) {
            final isSelected = lang['code'] == currentLang;
            return PopupMenuItem<String>(
              value: lang['code'],
              child: Row(
                children: [
                  Text(
                    lang['native']!,
                    style: TextStyle(
                      color: isSelected ? primary : textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: fontSize ?? 12,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(Icons.check, color: primary, size: (iconSize ?? 14) + 1),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}
