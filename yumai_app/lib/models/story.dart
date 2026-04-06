class Story {
  final int id;
  final String title;
  final String ethnic;
  final String intro;
  final String chineseText;
  final String yiText;
  final String tibetanText;
  final String? coverImage;

  Story({
    required this.id,
    required this.title,
    required this.ethnic,
    required this.intro,
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
      ethnic: _safeString(json['ethnic']),
      intro: _safeString(json['intro']),
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
      'ethnic': ethnic,
      'intro': intro,
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
