import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/story.dart';
import '../services/language_provider.dart';

/// 沉浸式阅读器页面
class ReaderScreen extends StatefulWidget {
  final Story story;
  final String initialLang;
  final int initialPageIndex;

  const ReaderScreen({
    super.key,
    required this.story,
    required this.initialLang,
    this.initialPageIndex = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  List<String> _pages = [];
  bool _showControls = true;
  double _fontSize = 18;
  final String _historyKey = 'yumai_history';
  final String _readerSettingsKey = 'yumai_reader_settings';

  String get _currentLang {
    try {
      return context.watch<LanguageProvider>().currentLang;
    } catch (_) {
      return widget.initialLang;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: _currentPageIndex);
    _splitContent();
    _loadReaderSettings();
    // 延迟分页，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splitContent();
      setState(() {});
      _pageController = PageController(initialPage: _currentPageIndex);
    });
    // 隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ⭐ 在这里添加 didChangeDependencies 方法
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当语言改变时重新分页
    _splitContent();
    setState(() {});
  }

  @override
  void dispose() {
    _saveReadingPosition();
    _pageController.dispose();
    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _loadReaderSettings() {
    SharedPreferences.getInstance().then((prefs) {
      final String? settingsStr = prefs.getString(_readerSettingsKey);
      if (settingsStr != null) {
        final settings = json.decode(settingsStr);
        if (mounted && settings['fontSize'] != null) {
          setState(() => _fontSize = settings['fontSize'].toDouble());
        }
      }
    });
  }

  void _saveReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _readerSettingsKey,
      json.encode({'fontSize': _fontSize}),
    );
  }

  String _getContent() {
    return widget.story.getContentByLanguage(_currentLang);
  }

  void _splitContent() {
    final content = _getContent();
    _pages = _splitIntoPages(content);

    debugPrint('内容长度: ${content.length}, 分页数量: ${_pages.length}');

    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = _pages.length - 1;
    }
    if (_currentPageIndex < 0) {
      _currentPageIndex = 0;
    }
  }

  /// 根据屏幕大小动态计算每页可容纳的字数
  int _calculateCharsPerPage() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 减去顶部栏(80) + 底部栏(100) + padding(48) ≈ 228
    final usableHeight = screenHeight - 228;

    // 每行大约能放多少字（中文字符宽度 ≈ 字体大小）
    final charsPerLine = (screenWidth / _fontSize).floor();

    // 能放多少行
    final lines = (usableHeight / (_fontSize * 1.8)).floor();

    // 每页总字数
    return (charsPerLine * lines).clamp(100, 1000);
  }

  /// 将长文本分页（每页约 500 字）
  /// 将长文本分页（根据屏幕大小动态分页）
  List<String> _splitIntoPages(String text) {
    // 如果还没有 context（首次加载），先用默认值
    int charsPerPage;
    try {
      charsPerPage = _calculateCharsPerPage();
    } catch (e) {
      charsPerPage = 300; // 默认值
    }

    if (text.length <= charsPerPage) return [text];

    List<String> pages = [];

    // 按字符数分割（保持段落完整性）
    List<String> paragraphs = text.split(RegExp(r'\n\n+'));
    StringBuffer currentPage = StringBuffer();
    int currentLength = 0;

    for (final para in paragraphs) {
      // 如果单个段落超过一页，强制分割
      if (para.length > charsPerPage) {
        if (currentPage.isNotEmpty) {
          pages.add(currentPage.toString().trim());
          currentPage.clear();
          currentLength = 0;
        }
        for (int i = 0; i < para.length; i += charsPerPage) {
          int end = (i + charsPerPage < para.length)
              ? i + charsPerPage
              : para.length;
          pages.add(para.substring(i, end));
        }
        continue;
      }

      // 正常段落累积
      if (currentLength + para.length > charsPerPage &&
          currentPage.isNotEmpty) {
        pages.add(currentPage.toString().trim());
        currentPage.clear();
        currentLength = 0;
      }
      currentPage.write(para);
      currentPage.write('\n\n');
      currentLength += para.length + 2;
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage.toString().trim());
    }

    return pages.isEmpty ? [text] : pages;
  }

  Future<void> _saveReadingPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_historyKey);
      if (stored == null) return;

      List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
        json.decode(stored),
      );

      // 找到对应故事并更新阅读位置
      for (int i = 0; i < history.length; i++) {
        if (history[i]['storyId'].toString() == widget.story.id.toString()) {
          history[i]['readingPageIndex'] = _currentPageIndex;
          history[i]['totalPages'] = _pages.length;
          history[i]['lastReadAt'] = DateTime.now().toIso8601String();
          break;
        }
      }

      await prefs.setString(_historyKey, json.encode(history));
    } catch (e) {
      debugPrint('保存阅读位置失败: $e');
    }
  }

  void _showFontSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        double tempSize = _fontSize;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('字体大小'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tempSize.toStringAsFixed(0)),
                  Slider(
                    min: 14,
                    max: 30,
                    value: tempSize,
                    onChanged: (value) =>
                        setDialogState(() => tempSize = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fontSize = tempSize;
                      _splitContent(); // ⭐ 重新分页
                      _pageController = PageController(
                        initialPage: 0,
                      ); // 重置到第一页
                    });
                    _saveReaderSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F0E8);
    final pageTextColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // 页面内容 - PageView
            // 页面内容 - PageView（左右翻页，不可上下滑动）
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPageIndex = index);
                _saveReadingPosition();
              },
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    80,
                    24,
                    MediaQuery.of(context).padding.bottom + 120,
                  ),
                  child: Text(
                    _pages[index],
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: pageTextColor,
                      fontFamily: _currentLang == 'bo'
                          ? 'Noto Serif Tibetan'
                          : _currentLang == 'ii'
                          ? 'Noto Sans Yi'
                          : null,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                );
              },
            ),

            // 顶部控制栏
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgColor, bgColor.withAlpha(0)],
                  ),
                ),
                child: Row(
                  children: [
                    // 返回按钮
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 标题
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.story.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: pageTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.story.ethnic.isNotEmpty)
                            Text(
                              widget.story.ethnic,
                              style: TextStyle(
                                fontSize: 12,
                                color: pageTextColor.withAlpha(153),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 字体设置
                    GestureDetector(
                      onTap: _showFontSettingsDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部进度栏
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 24,
                  right: 24,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [bgColor, bgColor.withAlpha(0)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 页面指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length > 10 ? 10 : _pages.length,
                        (index) {
                          final actualIndex = _pages.length > 10
                              ? (index * (_pages.length / 10)).round()
                              : index;
                          final isActive = _currentPageIndex == actualIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                actualIndex,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 12 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? primary
                                    : primary.withAlpha(77),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 页码
                    Text(
                      '${_currentPageIndex + 1} / ${_pages.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: pageTextColor.withAlpha(153),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
