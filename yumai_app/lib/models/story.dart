class Story {
  final int id;
  final String title;
  final String? titleBo;
  final String? titleIi;
  final String ethnic;
  final String? ethnicBo;
  final String? ethnicIi;
  final String intro;
  final String? introBo;
  final String? introIi;
  final String chineseText;
  final String yiText;
  final String tibetanText;
  final String? coverImage;

  Story({
    required this.id,
    required this.title,
    this.titleBo,
    this.titleIi,
    required this.ethnic,
    this.ethnicBo,
    this.ethnicIi,
    required this.intro,
    this.introBo,
    this.introIi,
    required this.chineseText,
    required this.yiText,
    required this.tibetanText,
    this.coverImage,
  });

  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static Map<String, String> _parseContentFromValue(dynamic content) {
    String chinese = '';
    String yi = '';
    String tibetan = '';

    if (content is Map) {
      chinese = _safeString(
        content['zh'] ??
            content['chinese'] ??
            content['original'] ??
            content['cn'] ??
            content['zh_cn'],
      );
      yi = _safeString(content['ii'] ?? content['yi']);
      tibetan = _safeString(
        content['bo'] ?? content['zang'] ?? content['tibetan'],
      );

      // 有些不规范后端可能把拼音放在通用 key
      if (chinese.isEmpty) {
        chinese = _safeString(content['content'] ?? content['text']);
      }
    } else if (content is String) {
      chinese = content;
    }

    return {'chinese': chinese, 'yi': yi, 'tibetan': tibetan};
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    final contentInfo = _parseContentFromValue(json['content']);

    final chineseText = contentInfo['chinese']!.isNotEmpty
        ? contentInfo['chinese']!
        : _safeString(json['chinese_text']);

    final yiText = contentInfo['yi']!.isNotEmpty
        ? contentInfo['yi']!
        : _safeString(json['yi_text']);

    final tibetanText = contentInfo['tibetan']!.isNotEmpty
        ? contentInfo['tibetan']!
        : _safeString(json['tibetan_text']);

    return Story(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(_safeString(json['id'])) ?? 0,
      title: _safeString(json['title']),
      titleBo: _safeString(json['title_bo']),
      titleIi: _safeString(json['title_ii']),
      ethnic: _safeString(json['ethnic']),
      ethnicBo: _safeString(json['ethnicBo']),
      ethnicIi: _safeString(json['ethnicIi']),
      intro: _safeString(json['intro']),
      introBo: _safeString(json['intro_bo']),
      introIi: _safeString(json['intro_ii']),
      chineseText: chineseText.isNotEmpty ? chineseText : '',
      yiText: yiText,
      tibetanText: tibetanText,
      coverImage: _safeString(json['cover_image']).isNotEmpty
          ? _safeString(json['cover_image'])
          : null,
    );
  }

  factory Story.fromListJson(Map<String, dynamic> json) {
    final merged = Map<String, dynamic>.from(json);
    merged['intro'] = merged['intro'] ?? merged['summary'] ?? '';
    return Story.fromJson(merged);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_bo': titleBo,
      'title_ii': titleIi,
      'ethnic': ethnic,
      'ethnicbo': ethnicBo,
      'ethnicii': ethnicIi,
      'intro': intro,
      'intro_bo': introBo,
      'intro_ii': introIi,
      'chinese_text': chineseText,
      'yi_text': yiText,
      'tibetan_text': tibetanText,
      'cover_image': coverImage,
    };
  }

  String getContentByLanguage(String lang) {
    switch (lang) {
      case 'ii':
        return yiText;
      case 'bo':
        return tibetanText;
      default:
        return chineseText;
    }
  }

  String getContentText() => chineseText;

  @override
  String toString() {
    return 'Story{id: $id, title: $title, ethnic: $ethnic}';
  }
}
