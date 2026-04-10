import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';

// 简单语言检测函数
String detectLanguage(String text) {
  if (text.contains(RegExp(r'[\u0F00-\u0FFF]'))) return 'bo';
  if (text.contains(RegExp(r'[\uA000-\uA48F]'))) return 'ii';
  return 'zh';
}

class ApiService {
  // 后端接口基础地址
  // 优先级：--dart-define=API_BASE_URL=xxx > 平台自动检测默认值
  //
  // 各场景说明：
  //   Web浏览器           → http://127.0.0.1:8000
  //   Android模拟器       → http://10.0.2.2:8000  （模拟器内10.0.2.2指向宿主机）
  //   iOS模拟器           → http://127.0.0.1:8000
  //   真机（同一局域网）   → flutter run --dart-define=API_BASE_URL=http://172.27.68.202:8000
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // 离线存储键名
  static const String storageKey = 'yumai_offline_stories';

  // 1. 获取故事列表
  // GET /stories
  static Future<List<Story>> getStories() async {
    try {
      // print('📡 请求故事列表: $baseUrl/stories');
      final response = await http
          .get(
            Uri.parse('$baseUrl/stories'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5)); // 5秒超时

      // print('📡 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.map((item) => Story.fromListJson(item)).toList();
        }
      }

      // 后端无数据或请求失败，使用模拟数据
      // print('⚠️ 使用模拟数据');
      return _getMockStories();
    } catch (e) {
      // print('❌ 网络请求错误: $e');
      // 网络错误时也返回模拟数据
      return _getMockStories();
    }
  }

  /// 模拟故事数据（用于演示）
  static List<Story> _getMockStories() {
    return [
      Story(
        id: 1,
        title: '格萨尔王传',
        titleBo: 'གེ་སར་རྒྱལ་པོའི་སྒྲུང་།',
        titleIi: 'ꀉꂿꄯꒉ ꉬꇁꌠ',
        ethnic: '藏族',
        ethnicBo: 'བོད་རིགས།',
        ethnicIi: 'ꆈꌠ',
        intro: '藏族英雄史诗，讲述格萨尔王降妖除魔、造福百姓的传奇故事。',
        introBo:
            'བོད་ཀྱི་དཔའ་བོའི་སྒྲུང་གཏམ། གེ་སར་རྒྱལ་པོས་བདུད་འདུལ་ཞིང་མི་དམངས་ལ་བདེ་སྐྱིད་སྤྲད་པའི་སྒྲུང་།',
        chineseText: '''格萨尔王传

在很久很久以前，藏地诞生了一位伟大的英雄——格萨尔王。他降妖除魔，平定四方，为百姓带来了和平与繁荣。

格萨尔王自幼就显露出非凡的神通和智慧。他力大无穷，能降服猛兽；他智勇双全，能识破妖魔的诡计。

长大后，格萨尔王开始了他的英雄征程。他骑着神马，手持宝刀，走遍藏地各地。他战胜了北方魔王鲁赞，最终统一了西藏。

每一次战斗，格萨尔王都是为了保护弱小百姓，为了正义而战。他不仅是一位勇猛的战士，更是一位仁爱之师。

格萨尔王的故事，是藏族人民世代传颂的英雄史诗，也是世界非物质文化遗产的瑰宝。''',
        yiText: '', // 藏族故事没有彝语，留空
        tibetanText: '''༄༅། །གེ་སར་རྒྱལ་པོའི་སྒྲུང་།

དུས་རབས་རིང་པོ་ཞིག་གི་གོང་དུ། བོད་ཀྱི་ཡུལ་དུ་གེ་སར་རྒྱལ་པོ་ཞེས་པའི་དཔའ་བོ་ཆེན་པོ་ཞིག་སྐྱེས་ཏེ། ཁྲག་འཐུང་སྡེ་དགོང་རྣམས་བཏུལ་ནས་མི་དམངས་ལ་བདེ་སྐྱིད་ཀྱི་འཚོ་བ་སྤྲད་པ་ཡིན།

གེ་སར་རྒྱལ་པོ་ནི་སྟོབས་ཆེན་ལྡན་པ་དང་། སྒྱུ་རྩལ་མཁས་པ། མི་དམངས་ཀྱི་དོན་དུ་རང་གི་ཚེ་སྲོག་ཡང་བཞག་འདོད་པའི་དཔའ་བོ་ཞིག་རེད།

དེའི་སྒྲུང་ནི་བོད་ཀྱི་སྒྲུང་གཏམ་ཆེན་པོའི་ནང་གལ་ཆེན་པོ་ཞིག་ཡིན་པ་མ་ཟད། འཛམ་གླིང་གི་སྒྲུང་གཏམ་གྱི་གཞི་རྩའི་ནང་ཀྱང་གྲགས་ཅིག་ཡིན།''',
        coverImage: null,
      ),
      Story(
        id: 2,
        title: '阿诗玛',
        titleBo: 'ཨ་ཧྲི་མ།', // 藏语暂译，可后续修正
        titleIi: 'ꀋꏂꃀ',
        ethnic: '彝族',
        ethnicBo: 'ཡི་རིགས།',
        ethnicIi: 'ꆈꌠ',
        intro: '彝族民间叙事长诗，阿诗玛的传奇故事，展现了彝族人民对美好生活的向往。',
        introIi: 'ꆈꌠꉙ ꀉꂿꄯꒉ...',
        chineseText: '''阿诗玛

在美丽的石林湖畔，有一个名叫阿诗玛的撒尼姑娘。她像山茶花一样美丽，像清泉一样纯洁。

阿诗玛与勇敢的青年阿黑相爱。他们一起放羊，一起唱歌，过着幸福的生活。

可是，财主热布巴拉看中了阿诗玛，想把她抢去做媳妇。阿黑为了救阿诗玛，与热布巴拉家展开了激烈的斗争。

最后，阿诗玛为了坚守爱情，化作了石林中的一座石峰。她永远守望着这片土地，守望着她深爱的阿黑哥。

阿诗玛的故事，是彝族人民世代传颂的爱情史诗，也是中华民族文化宝库中的瑰宝。''',
        yiText: '''ꀋꏂꃀ ꀉꂿꄯꒉ

ꉡꆹ ꀋꏂꃀ，ꆺꑳꀋꁧ ꑳꉎꀋꄮ ꃄꌠꃄꅉꇬ ꄊꆪꐙꄉ，ꉢꊈꀋꁧ ꇬꄉ ꉢꊈꄈꇈ，ꀋꏂꃀ ꑠꑵ ꉌꊭꀕꑴꌦ。

ꀋꏂꃀ ꆏ ꉌꂵꆏ ꊷꆣꀕ，ꋌꊂꆏ ꀋꁧꄈꌠ，ꀋꏂꃀ ꌺꇖꅀꀋꅐ，ꃅꃄꇖꈓ ꋋꇅꆹ ꉡꆹ ꉌꐡꀋꐥ。

ꀋꏂꃀ ꉌꂵ ꑌ ꐛꀕ，ꉢꊈꀋꁧ ꇬꄉ ꉢꊈꄈꇈ，ꀋꏂꃀ ꑠꑵ ꉌꊭꀕꑴꌦ。''',
        tibetanText: '', // 彝族故事没有藏语，留空
        coverImage: null,
      ),
    ];
  }

  // 1.1 搜索故事
  // GET /stories/search?query=
  static Future<List<Story>> searchStories(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(trimmed);
      final uri = Uri.parse('$baseUrl/stories/search?query=$encodedQuery');
      // print('📡 请求故事搜索: $uri');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      // print('📡 搜索响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // print('✅ 搜索结果数量: ${data.length}');
          return data.map((item) => Story.fromListJson(item)).toList();
        }
      }

      // 使用模拟搜索
      // print('⚠️ 使用模拟搜索');
      final mockStories = _getMockStories();
      return mockStories
          .where(
            (story) =>
                story.title.contains(trimmed) || story.intro.contains(trimmed),
          )
          .toList();
    } catch (e) {
      // print('❌ 搜索错误: $e');
      // 网络错误时也返回模拟搜索结果
      final mockStories = _getMockStories();
      return mockStories
          .where(
            (story) =>
                story.title.contains(trimmed) || story.intro.contains(trimmed),
          )
          .toList();
    }
  }

  // 2. 获取故事详情
  // GET /story/{story_id}
  static Future<Story?> getStoryDetail(int storyId) async {
    try {
      // print('📡 请求故事详情: $baseUrl/story/$storyId');
      final response = await http
          .get(
            Uri.parse('$baseUrl/story/$storyId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5)); // 5秒超时

      // print('📡 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('error')) {
          // print('❌ 获取故事详情失败: ${data['error']}');
          // 返回模拟数据
          return _getMockStoryDetail(storyId);
        }

        return Story.fromJson(data);
      } else {
        // print('❌ 获取故事详情失败，状态码: ${response.statusCode}');
        // 返回模拟数据
        return _getMockStoryDetail(storyId);
      }
    } catch (e) {
      // print('❌ 网络请求错误 (getStoryDetail): $e');
      // 网络错误时返回模拟数据
      return _getMockStoryDetail(storyId);
    }
  }

  /// 获取模拟故事详情（用于演示）
  static Story? _getMockStoryDetail(int storyId) {
    // 获取所有模拟故事列表
    final mockStories = _getMockStories();

    // 根据 ID 查找对应的故事
    final story = mockStories.firstWhere(
      (s) => s.id == storyId,
      orElse: () {
        // print('⚠️ 未找到 ID 为 $storyId 的故事，返回第一个');
        return mockStories.first;
      },
    );

    // print('📖 使用模拟详情数据: ${story.title}');
    return story;
  }

  // 3. 故事问答
  // POST /ask
  // useRag: 是否启用全局知识库检索（默认 false，仅用当前故事）
  // history: 对话历史，格式为 [{"role": "user"/"assistant", "content": "..."}]
  // lang: 回答语言（zh/bo/ii）
  // 返回 Map 包含 answer, source, rag_sources 或 error
  static Future<Map<String, dynamic>> askQuestion({
    int? storyId,
    required String question,
    bool useRag = false,
    List<Map<String, String>>? history,
    String lang = 'zh',
  }) async {
    try {
      // print('📡 提问: story_id=$storyId, question=$question, use_rag=$useRag');
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'story_id': storyId,
          'question': question,
          'use_rag': useRag,
          'history': ?history,
          'lang': lang,
        }),
      );

      // print('📡 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 422) {
        return {'error': '参数错误'};
      } else {
        return {'error': '请求失败'};
      }
    } catch (e) {
      // print('❌ 网络请求错误 (askQuestion): $e');
      return {'error': '网络错误'};
    }
  }

  // 4. 测试后端是否连通
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      // print('❌ 后端连接测试失败: $e');
      return false;
    }
  }

  // 5. 语音转文字
  // POST /stt
  static Future<String> speechToText(Uint8List audioBytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/stt'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'voice.wav',
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        try {
          final dynamic decoded = json.decode(responseBody);
          if (decoded is Map<String, dynamic>) {
            final text = (decoded['text'] ?? decoded['result'] ?? '')
                .toString();
            if (text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        } catch (_) {
          // 非 JSON 时直接尝试按纯文本返回
        }
        return responseBody.trim();
      }

      throw Exception('STT 请求失败: ${streamedResponse.statusCode} $responseBody');
    } catch (e) {
      throw Exception('语音识别失败: $e');
    }
  }

  // 6. 文本转语音音频
  // GET /tts/{story_id}
  static Future<Uint8List?> getTtsAudio(int storyId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tts/$storyId'));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      // print('❌ 获取 TTS 音频失败，状态码: ${response.statusCode}');
      return null;
    } catch (e) {
      // print('❌ 网络请求错误 (getTtsAudio): $e');
      return null;
    }
  }

  // ---------- 离线存储功能 ----------
  static Future<Map<String, dynamic>> getOfflineStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(storageKey);
      return stored != null ? json.decode(stored) : {};
    } catch (e) {
      // print('❌ 读取离线存储失败: $e');
      return {};
    }
  }

  static Future<void> saveOfflineStory(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stories = await getOfflineStories();
      stories[story.id.toString()] = story.toJson();
      await prefs.setString(storageKey, json.encode(stories));
      // print('✅ 故事已保存到离线: ${story.title}');
    } catch (e) {
      // print('❌ 保存离线故事失败: $e');
    }
  }

  static Future<bool> isStoryOffline(int storyId) async {
    final stories = await getOfflineStories();
    return stories.containsKey(storyId.toString());
  }

  static Future<Story?> getOfflineStory(int storyId) async {
    try {
      final stories = await getOfflineStories();
      final jsonData = stories[storyId.toString()];
      return jsonData != null ? Story.fromJson(jsonData) : null;
    } catch (e) {
      // print('❌ 获取离线故事失败: $e');
      return null;
    }
  }

  static Future<void> clearAllOfflineStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, json.encode({}));
      // print('✅ 已清除所有离线故事');
    } catch (e) {
      // print('❌ 清除离线存储失败: $e');
    }
  }

  static Future<int> getOfflineStoriesCount() async {
    final stories = await getOfflineStories();
    return stories.length;
  }
}
