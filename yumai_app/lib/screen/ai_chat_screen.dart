import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import '../services/api_services.dart';
import '../services/language_provider.dart';
import '../models/story.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AIChatScreen extends StatefulWidget {
  final String? storyId;
  final String initialLang;

  const AIChatScreen({super.key, this.storyId, required this.initialLang});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  Story? _currentStory;
  bool _isStoryLoading = false;
  Future<void>? _storyLoadFuture;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  BytesBuilder _audioBuffer = BytesBuilder(copy: false);

  final FocusNode _focusNode = FocusNode();
  bool _isInputFocused = false;
  bool _isVoiceMode = false;

  // 局部语言状态（仅故事模式）
  String _uiLang = 'zh';
  bool _showLangSwitch = false;
  String _ethnicLang = '';

  final Map<String, Map<String, String>> _translations = {
    'zh': {
      'title': '问答',
      'placeholder': '请输入您的问题...',
      'ask': '提问',
      'empty': '输入您的问题，开始问答...',
      'thinking': '正在思考中...',
      'storyInfo': '当前故事',
      'voiceHint': '正在聆听... 请说话',
      'voiceError': '语音识别失败，请重试',
      'voiceNotSupported': '您的浏览器不支持语音输入',
      'networkError': '网络错误，请稍后重试',
      'tryVoice': '试试语音输入或打字提问',
    },
    'bo': {
      'title': 'དྲི་བ།',
      'placeholder': 'དྲི་བ་འདྲེན།...',
      'ask': 'དྲི་བ།',
      'empty': 'དྲི་བ་འདྲེན།...',
      'thinking': 'བསམ་བློ་གཏོང་བཞིན་པ།...',
      'storyInfo': 'གཏམ་རྒྱུད།',
      'voiceHint': 'ཉན་བཞིན་པ།...',
      'voiceError': 'འདྲེན་མ་ཚང་།',
      'voiceNotSupported': 'ཁྱེད་ཀྱི་ཡིག་ཆ་རྒྱབ་སྐྱོར་མི་བྱེད།',
      'networkError': 'དྲ་རྒྱའི་ནོར་འཁྲུལ།',
      'tryVoice': 'སྒྲ་ཐོན་པའམ་ཡི་གེ་བྲིས་ཏེ་དྲི་བ།',
    },
    'ii': {
      'title': 'ꉉꇉ',
      'placeholder': 'ꉉꇉꀉꂿ...',
      'ask': 'ꉉꇉ',
      'empty': 'ꉉꇉꀉꂿ...',
      'thinking': 'ꉉꇀꌠ...',
      'storyInfo': 'ꀉꂿꄯꒉ',
      'voiceHint': 'ꉉꇀꌠ...',
      'voiceError': 'ꐘ ꀋꁨ',
      'voiceNotSupported': 'ꌠꅇꂘ ꀋꁨ',
      'networkError': 'ꃅꇢꇬꄉ ꐘ ',
      'tryVoice': 'ꉉꇉꀉꂿꌠ ꐘꀨ',
    },
  };

  String _t(String key) {
    String lang;
    if (_ethnicLang.isEmpty) {
      // 全局模式：使用 LanguageProvider
      try {
        lang = context.watch<LanguageProvider>().currentLang;
      } catch (_) {
        lang = 'zh';
      }
    } else {
      // 故事模式：使用局部语言
      lang = _uiLang;
    }
    final safeLang = ['zh', 'bo', 'ii'].contains(lang) ? lang : 'zh';
    return _translations[safeLang]?[key] ?? _translations['zh']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _uiLang = 'zh';
    _storyLoadFuture = _loadCurrentStory();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isInputFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  Future<void> _loadCurrentStory() async {
    if (widget.storyId == null) {
      setState(() {
        _showLangSwitch = true;
        _ethnicLang = '';
        _isStoryLoading = false;
      });
      return;
    }

    final storyId = int.tryParse(widget.storyId!);
    if (storyId == null) return;

    setState(() => _isStoryLoading = true);

    try {
      final story = await ApiService.getStoryDetail(storyId);
      if (mounted) {
        setState(() {
          _currentStory = story;
          final ethnic = story?.ethnic ?? '';
          if (ethnic.contains('藏')) {
            _showLangSwitch = true;
            _ethnicLang = 'bo';
          } else if (ethnic.contains('彝')) {
            _showLangSwitch = true;
            _ethnicLang = 'ii';
          } else {
            _showLangSwitch = false;
          }
          _uiLang = 'zh';
          _isStoryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentStory = null;
          _showLangSwitch = false;
          _isStoryLoading = false;
        });
      }
    }
  }

  Future<String?> _getCurrentStoryName() async {
    if (widget.storyId == null) return null;
    if (_currentStory != null) return _currentStory!.title;
    await _storyLoadFuture;
    return _currentStory?.title;
  }

  void _toggleLanguage() {
    if (!_showLangSwitch || _ethnicLang.isEmpty) return;
    final newLang = _uiLang == 'zh' ? _ethnicLang : 'zh';
    setState(() {
      _uiLang = newLang;
    });
  }

  Future<void> _sendQuestion() async {
    if (_isVoiceMode) return;

    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final detectedLang = detectLanguage(question);

    setState(() {
      _messages.add({'role': 'user', 'content': question});
      _questionController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      String answer;
      final storyId = widget.storyId != null
          ? int.tryParse(widget.storyId!)
          : null;

      final history = _messages
          .where((m) => m['role'] != 'user' || m['content'] != question)
          .map(
            (m) => {
              'role': m['role'] == 'user' ? 'user' : 'assistant',
              'content': m['content'] as String,
            },
          )
          .toList();

      final result = await ApiService.askQuestion(
        storyId: storyId,
        question: question,
        useRag: true,
        history: history.isNotEmpty ? history : null,
        lang: detectedLang,
      );

      if (result.containsKey('answer')) {
        answer = result['answer'] ?? '';
      } else if (result.containsKey('error')) {
        answer = '错误: ${result['error']}';
      } else {
        answer = '无法获取回答';
      }

      final apiSuggestions =
          (result['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': answer,
          'suggestions': apiSuggestions,
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '${_t('networkError')}: $e',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isLoading) return;

    String currentLang;
    if (_ethnicLang.isEmpty) {
      currentLang = context.read<LanguageProvider>().currentLang;
    } else {
      currentLang = _uiLang;
    }

    if (currentLang != 'zh') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前仅支持汉语语音输入，请切换至汉语'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (_isVoiceMode) {
        _questionController.clear();
        _focusNode.unfocus();
      }
    });
  }

  Future<void> _startRecording() async {
    if (!_isVoiceMode || _isListening || _isLoading) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('voiceNotSupported')),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }

      _audioBuffer = BytesBuilder(copy: false);
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _recordSub = stream.listen((chunk) {
        _audioBuffer.add(chunk);
      });

      if (!mounted) return;
      setState(() {
        _isListening = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('voiceError')}: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isListening) return;

    try {
      await _recordSub?.cancel();
      _recordSub = null;
      await _audioRecorder.stop();

      if (!mounted) return;
      setState(() {
        _isListening = false;
      });

      final audioBytes = _audioBuffer.toBytes();
      if (audioBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('voiceError')),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }

      final text = await ApiService.speechToText(
        Uint8List.fromList(audioBytes),
      );
      if (!mounted) return;

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('voiceError')),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }

      setState(() {
        _messages.add({'role': 'user', 'content': text});
        _isLoading = true;
      });

      _scrollToBottom();

      try {
        String answer;
        final storyId = widget.storyId != null
            ? int.tryParse(widget.storyId!)
            : null;

        final history = _messages
            .where((m) => m['role'] != 'user' || m['content'] != text)
            .map(
              (m) => {
                'role': m['role'] == 'user' ? 'user' : 'assistant',
                'content': m['content'] as String,
              },
            )
            .toList();

        final result = await ApiService.askQuestion(
          storyId: storyId,
          question: text,
          useRag: true,
          history: history.isNotEmpty ? history : null,
          lang: _ethnicLang.isEmpty
              ? context.read<LanguageProvider>().currentLang
              : _uiLang,
        );

        if (result.containsKey('answer')) {
          answer = result['answer'] ?? '';
        } else if (result.containsKey('error')) {
          answer = '错误: ${result['error']}';
        } else {
          answer = '无法获取回答';
        }

        final apiSuggestions =
            (result['suggestions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': answer,
            'suggestions': apiSuggestions,
          });
          _isLoading = false;
        });

        _scrollToBottom();
      } catch (e) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '${_t('networkError')}: $e',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('voiceError')}: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final surface = SemanticColors.surface(theme.brightness);
    final border = SemanticColors.border(theme.brightness);
    final textPrimary = SemanticColors.textPrimary(context);
    final textSecondary = SemanticColors.textSecondary(context);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, secondary],
                        ).createShader(bounds),
                        child: Text(
                          _t('title'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      if (_showLangSwitch)
                        _isStoryLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primary,
                                ),
                              )
                            : (_ethnicLang.isEmpty
                                  ? buildLanguageSwitcher(
                                      fontSize: 14,
                                      iconSize: 16,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                    )
                                  : _buildStoryLangToggle(primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      subtitlePill(
                        text: 'དྲི་བ།',
                        fontFamily: 'Noto Serif Tibetan',
                        primary: primary,
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withAlpha(100),
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 7),
                      ),
                      subtitlePill(
                        text: 'ꉉꇉ',
                        fontFamily: 'Noto Sans Yi',
                        primary: primary,
                      ),
                    ],
                  ),
                  if (widget.storyId != null) ...[
                    const SizedBox(height: 10),
                    FutureBuilder<String?>(
                      future: _getCurrentStoryName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 22);
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [primary, secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  snapshot.data!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    border.withAlpha(80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: textSecondary.withAlpha(128),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _t('empty'),
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _t('tryVoice'),
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser)
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: primary.withAlpha(25),
                                      child: Icon(
                                        Icons.smart_toy,
                                        size: 16,
                                        color: primary,
                                      ),
                                    ),
                                  if (!isUser) const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isUser ? primary : surface,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: isUser
                                              ? const Radius.circular(20)
                                              : const Radius.circular(5),
                                          bottomRight: isUser
                                              ? const Radius.circular(5)
                                              : const Radius.circular(20),
                                        ),
                                        border: isUser
                                            ? null
                                            : Border.all(color: border),
                                      ),
                                      child: Text(
                                        message['content'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isUser
                                              ? Colors.white
                                              : textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isUser) const SizedBox(width: 8),
                                  if (isUser)
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: primary,
                                      child: const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              if (!isUser &&
                                  (message['suggestions'] as List<String>?) !=
                                      null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 36,
                                    top: 6,
                                    bottom: 4,
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children:
                                        (message['suggestions'] as List<String>)
                                            .map((q) {
                                          return GestureDetector(
                                            onTap: () {
                                              _questionController.text = q;
                                              _sendQuestion();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: surface,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: border.withAlpha(128),
                                                ),
                                              ),
                                              child: Text(
                                                q,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(
                      _t('voiceHint'),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('thinking'),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border, width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleVoiceInput,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isVoiceMode
                            ? primary
                            : (_ethnicLang.isEmpty
                                  ? (context
                                                .watch<LanguageProvider>()
                                                .currentLang ==
                                            'zh'
                                        ? primary.withAlpha(25)
                                        : Colors.grey.withAlpha(77))
                                  : (_uiLang == 'zh'
                                        ? primary.withAlpha(25)
                                        : Colors.grey.withAlpha(77))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isVoiceMode
                              ? Colors.transparent
                              : (_ethnicLang.isEmpty
                                    ? (context
                                                  .watch<LanguageProvider>()
                                                  .currentLang ==
                                              'zh'
                                          ? border
                                          : Colors.grey)
                                    : (_uiLang == 'zh' ? border : Colors.grey)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isVoiceMode ? Icons.keyboard : Icons.mic,
                        size: 20,
                        color: _isVoiceMode
                            ? Colors.white
                            : (_ethnicLang.isEmpty
                                  ? (context
                                                .watch<LanguageProvider>()
                                                .currentLang ==
                                            'zh'
                                        ? primary
                                        : Colors.grey)
                                  : (_uiLang == 'zh' ? primary : Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isVoiceMode
                        ? _buildVoiceInputArea(
                            surface,
                            primary,
                            border,
                            textSecondary,
                          )
                        : _buildTextInputArea(
                            surface,
                            primary,
                            secondary,
                            border,
                            textPrimary,
                            textSecondary,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryLangToggle(Color primary) {
    final isChinese = _uiLang == 'zh';
    final label = isChinese ? (_ethnicLang == 'bo' ? '藏语原文' : '彝语原文') : '汉语';
    return GestureDetector(
      onTap: _toggleLanguage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withAlpha(25), primary.withAlpha(40)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 14, color: primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputArea(
    Color surface,
    Color primary,
    Color border,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isListening && !_isLoading) {
          _startRecording();
        }
      },
      onTapUp: (_) {
        if (_isListening) {
          _stopRecordingAndSend();
        }
      },
      onTapCancel: () {
        if (_isListening) {
          _stopRecordingAndSend();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: _isListening ? AppColors.danger.withAlpha(30) : surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isListening ? AppColors.danger : border,
            width: _isListening ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isListening)
              Icon(
                Icons.fiber_manual_record,
                size: 14,
                color: AppColors.danger,
              ),
            if (_isListening) const SizedBox(width: 6),
            Text(
              _isListening ? '松开发送' : '按住说话',
              style: TextStyle(
                fontSize: 15,
                color: _isListening ? AppColors.danger : textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea(
    Color surface,
    Color primary,
    Color secondary,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: _isInputFocused ? primary : border,
          width: _isInputFocused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _questionController,
              decoration: InputDecoration(
                hintText: _t('placeholder'),
                hintStyle: TextStyle(color: textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: textPrimary),
              onSubmitted: (_) => _sendQuestion(),
            ),
          ),
          ListenableBuilder(
            listenable: _questionController,
            builder: (context, _) {
              final hasText = _questionController.text.trim().isNotEmpty;
              return AnimatedOpacity(
                opacity: hasText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: hasText ? 44 : 0,
                  height: 44,
                  child: hasText
                      ? GestureDetector(
                          onTap: _sendQuestion,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, secondary],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget subtitlePill({
    required String text,
    required String fontFamily,
    required Color primary,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: primary.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: primary,
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  @override
  void dispose() {
    _recordSub?.cancel();
    _audioRecorder.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
